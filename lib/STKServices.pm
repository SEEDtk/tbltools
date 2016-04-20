#
# Copyright (c) 2003-2015 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#


package STKServices;

    use strict;
    use warnings;
    use Shrub;
    use Data::Dumper;
    use SeedUtils qw(); # suppress imports to prevent warnings

=head1 SEEDtk Services Helper

This is the helper object for implementing common services in SEEDtk. It contains a constructor that
connects to the L<Shrub> database and methods to perform the basic script functions. All helper objects
must have the same interface.

The fields in this object are as follows.

=over 4

=item shrub

The L<Shrub> database object used to access the data.

=back

=cut

=head2 Special Methods

=head3 new

    my $helper = STKServices->new();

Construct a new SEEDtk services helper.

=cut

sub new {
    my ($class) = @_;
    my $retVal = {
    };
    bless $retVal, $class;
    return $retVal;
}

=head3 connect_db

    $helper->connect_db($opt);

Connect this object to the Shrub database.

=over 4

=item opt

L<Getopt::Long::Descriptive::Opt> object containing options from L<Shrub/script_options> for connecting to
the correct database.

=back

=cut

sub connect_db {
    my ($self, $opt) = @_;
    # Connect to the database. Note that if no options are specified we do a default connection.
    my $shrub;
    if ($opt) {
        $shrub = Shrub->new_for_script($opt);
    } else {
        $shrub = Shrub->new();
    }
    # Store it in this object.
    $self->{shrub} = $shrub;
}

=head3 script_options

    my @options = $helper->script_options();

Return a list of the command-line option specifiers for this object. These options are only used if we need
to connect to the database. They should be in the format expected by L<Getopt::Long::Descriptive::describe_options>.

=cut

sub script_options {
    return Shrub::script_options();
}

=head2 Service Methods

=head3 all_genomes

    my $genomeList = $helper->all_genomes($prok, $complete);

Return the ID and name of every genome in the database.

=over 4

=item prok

If TRUE, only prokaryotic genomes are included. The default is FALSE.

=item complete

If TRUE, only complete genomes are include. The default is FALSE.

=item RETURN

Returns a reference to a list of 2-tuples, each 2-tuple consisting of (0) a genome name and (1) a genome ID.
All of the genomes in the database are returned.

=back

=cut

sub all_genomes {
    my ($self, $prok, $complete) = @_;
    my $shrub = $self->{shrub};
    # All genomes in the Shrub are complete, so we only need to worry about filtering on proks.
    my $filter = '';
    my @parms;
    if ($prok) {
        $filter = 'Genome(prokaryotic) = ?';
        push @parms, 1;
    }
    my @genomes = $shrub->GetAll('Genome', $filter, \@parms, 'name id');
    return \@genomes;
}

=head3 all_features

    my $featureHash = $helper->features_of(\@genomeIDs, $type);

Return a hash mapping each incoming genome ID to a list of its feature IDs.

=over 4

=item genomeIDs

A reference to a list of IDs for the genomes to be processed.

=item type (optional)

If specified, the type of feature ID desired. Only feature IDs with matching types will be returned.

=item RETURN

Returns a reference to a hash mapping each incoming genome ID to a list reference containing all the features in the
genome.

=back

=cut

sub all_features {
    my ($self, $genomeIDs, $type) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # This string is added to the end of the parameter used in filtering the features. If a type is specified,
    # it filters on feature type as well as genome ID.
    my $parmSuffix = ($type ? "$type.%" : "%");
    for my $gid (@$genomeIDs) {
        # Get the IDs of the desired features. Note the feature ID contains both the genome ID and the feature
        # type. This is not the cleanest way to filter the query, just the fastest.
        my @fids = $shrub->GetFlat('Feature', 'Feature(id) LIKE ?', ["fig|$gid.$parmSuffix"], 'id');
        print Dumper @fids; die;
        # Store the returned features with the genome ID.
        $retVal{$gid} = \@fids;
    }
    return \%retVal;
}

=head3 role_to_features

    my $featureHash = $helper->role_to_features(\@roleIDs, $priv, $genomesL);

Return a hash mapping each incoming role ID to a list of its feature IDs.

=over 4

=item roleIDs

A reference to a list of IDs for the roles to be processed.

=item priv

The privilege level for the relevant assignments.

=item genomesL (optional)

If specified, a list of genomes. Only features from the specified genomes will be returned.

=item RETURN

Returns a reference to a hash mapping each incoming role ID to a list reference containing all the features with that
role.

=back

=cut

sub role_to_features {
    my ($self, $roleIDs, $priv, $genomesL) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Build the query.
    my @parms;
    my $path = 'Role2Function Function2Feature';
    my $filter = 'Role2Function(from-link) = ? AND Function2Feature(security) = ?';
    if ($genomesL) {
        $path .= ' Feature2Genome';
        $filter .= ' AND Feature2Genome(to-link) IN (' . join(', ', map { '?' } @$genomesL) . ')';
        push @parms, @$genomesL;
    }
    for my $rid (@$roleIDs) {
        # Get the IDs of the desired features.
        my @fids = $shrub->GetFlat($path, $filter, [$rid, $priv, @parms], 'Function2Feature(to-link)');
        # Store the returned features with the role ID.
        $retVal{$rid} = \@fids;
    }
    return \%retVal;
}


=head3 function_to_features

    my $featureHash = $helper->function_to_features(\@functionIDs, $priv);

Return a hash mapping each incoming function ID to a list of its feature IDs.

=over 4

=item roleIDs

A reference to a list of IDs for the functions to be processed.

=item priv

The privilege level for the relevant assignments.

=item RETURN

Returns a reference to a hash mapping each incoming role ID to a list reference containing all the features with that
role.

=back

=cut

sub function_to_features {
    my ($self, $functionIDs, $priv) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $funcid (@$functionIDs) {
        # Get the IDs of the desired features.
        my @funcids = $shrub->GetFlat('Function2Feature',
                'Function2Feature(from-link) = ? AND Function2Feature(security) = ?', [$funcid, $priv], 'Function2Feature(to-link)');
        # Store the returned features with the function ID.
        $retVal{$funcid} = \@funcids;
    }
    return \%retVal;
}


=head3 function_to_roles

    my $featureHash = $helper->function_to_roles(\@functionIDs, $priv);

Return a hash mapping each incoming function ID to a list of its associated role IDs.

=over 4

=item funcIDs

A reference to a list of IDs for the functions to be processed.

=item priv

The privilege level for the relevant assignments.

=item RETURN

Returns a reference to a hash mapping each incoming function ID to a list reference containing all the roles associated with that function.

=back

=cut

sub function_to_roles {
    my ($self, $functionIDs, $priv) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $funcid (@$functionIDs) {
        # Get the IDs of the desired features.
        my @funcids = $shrub->GetFlat('Function2Role',
                'Function2Role(from-link) = ? ', [$funcid], 'Function2Role(to-link)');
        # Store the returned features with the function ID.
        $retVal{$funcid} = \@funcids;
    }
    return \%retVal;
}


=head3 role_to_reactions

    my $reactionHash = $helper->role_to_reactions(\@roleIDs);

Return a hash mapping each incoming role ID to a list of its triggered reactions.

=over 4

=item roleIDs

A reference to a list of IDs for the roles to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming role ID to a list reference containing a 2-tuple for each
triggered reaction, each 2-tuple itself consisting of (0) the reaction ID and (1) the reaction name.

=back

=cut

sub role_to_reactions {
    my ($self, $roleIDs) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Build the query.
    my @parms;
    my $path = 'Role2Complex Complex2Reaction Reaction';
    my $filter = 'Role2Complex(from-link) = ? AND Role2Complex(triggering) = ?';
    for my $rid (@$roleIDs) {
        # Get the IDs of the desired reactions.
        my %rmap = map { $_->[0] => $_->[1] } $shrub->GetAll($path, $filter, [$rid, 1], 'Reaction(id) Reaction(name)');
        # Store the returned features with the role ID.
        $retVal{$rid} = [ map { [$_, $rmap{$_}] } sort keys %rmap ];
    }
    return \%retVal;
}


=head3 role_to_ss

    my $ssHash = $helper->role_to_ss(\@roles, $idForm);

Return a hash mapping each incoming role description to a list of subsystems

=over 4

=item roleIDs

A reference to a list of role descriptions to be processed.

=item idForm (optional)

If TRUE, then the incoming roles will be presumed to be IDs instead of descriptions. This option
only has meaning in the SEEDtk environment.

=item RETURN

Returns a reference to a hash mapping each incoming role description to a list reference containing
all the subsystems with that role. Roles that do not occur in a subsystem will not appear in the hash.

=back

=cut

sub role_to_ss {
    my ($self, $roles, $idForm) = @_;
    my $shrub = $self->{shrub};
    # Compute the filter.
    my $filterField = 'description';
    if ($idForm) {
        $filterField = 'id';
    }
    my %retVal;
    for my $role (@$roles) {
        # Get the IDs of the desired features.
        my $r;
        if ($idForm) {
            $r = $role;
        } else {
            ($r) = Shrub::Roles::Parse($role);
        }
        my @ss_s = $shrub->GetFlat('Role Role2Subsystem ',
                "Role($filterField) = ?", [$r], 'Role2Subsystem(to-link)');
        # Store the returned subsystems. with the role ID.
        if (@ss_s) {
            $retVal{$role} = \@ss_s;
        }
    }
    return \%retVal;
}


=head3 translation

    my $protHash = $helper->translation(\@fids);

Return the protein translation for each incoming feature.

=over 4

=item fids

A reference to a list of IDs for the features to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming feature ID to its protein translation. A feature without
a protein translation will not appear in the hash.

=back

=cut

sub translation {
    my ($self, $fids) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Break the input list into batches and retrieve a batch at a time.
    my $start = 0;
    while ($start < @$fids) {
        # Get this chunk.
        my $end = $start + 10;
        if ($end >= @$fids) {
            $end = @$fids - 1;
        }
        my @slice = @{$fids}[$start .. $end];
        # Compute the translatins for this chunk.o
        my $filter = 'Feature2Protein(from-link) IN (' . join(', ', map { '?' } @slice) . ')';
        my @tuples = $shrub->GetAll('Feature2Protein Protein', $filter, \@slice,
                'Feature2Protein(from-link) Protein(sequence)');
        for my $tuple (@tuples) {
            $retVal{$tuple->[0]} = $tuple->[1];
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%retVal;
}

=head3 function_of

    my $funcHash = $helper->function_of(\@fids, $priv, $verbose);

Return the functional assignment for each incoming feature.

=over 4

=item fids

A reference to a list of IDs for the features to be processed.

=item priv

Privilege level of the desired assignments.

=item verbose (optional)

If TRUE, then function descriptions will be returned instead of function IDs. (On most systems these are the same.)

=item RETURN

Returns a reference to a hash mapping each incoming feature ID to its functional assignment. An invalid feature ID
will not appear in the hash.

=back

=cut

sub function_of {
    my ($self, $fids, $priv, $verbose) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Compute the output field and path from the verbose option.
    my ($path, $fields);
    if ($verbose) {
        $path = 'Feature2Function Function';
        $fields = 'Feature2Function(from-link) Function(description) Feature2Function(comment)';
    } else {
        $path = 'Feature2Function';
        $fields = 'Feature2Function(from-link) Feature2Function(to-link)';
    }
    # Break the input list into batches and retrieve a batch at a time.
    my $start = 0;
    while ($start < @$fids) {
        # Get this chunk.
        my $end = $start + 10;
        if ($end >= @$fids) {
            $end = @$fids - 1;
        }
        my @slice = @{$fids}[$start .. $end];
        # Compute the functions for this chunk.o
        my $filter = 'Feature2Function(from-link) IN (' . join(', ', map { '?' } @slice) .
            ') AND Feature2Function(security) = ?';
        my @tuples = $shrub->GetAll($path, $filter, [@slice, $priv], $fields);
        for my $tuple (@tuples) {
            my ($fid, $function, $comment) = @$tuple;
            if ($comment) {
                $function .= " # $comment";
            }
            $retVal{$fid} = $function;
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%retVal;
}

=head3 role_to_desc

    my $roleIdHash = $helper->role_to_desc(\@role_ids);

Return the descriptions corresponding to a set of role IDs

=over 4

=item role_ids

A reference to a list of IDs for the roles to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming role ID to its full description.
An invalid role ID will not produce a map entry;

=back

=cut

sub role_to_desc {
    my ($self, $role_ids) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Break the input list into batches and retrieve a batch at a time.
    my $start = 0;
    while ($start < @$role_ids) {
        # Get this chunk.
        my $end = $start + 10;
        if ($end >= @$role_ids) {
            $end = @$role_ids - 1;
        }
        my @slice = @{$role_ids}[$start .. $end];
        # Compute the translatins for this chunk.o
        my $filter = 'Role(id) IN (' . join(', ', map { '?' } @slice) . ')';
        my @tuples = $shrub->GetAll('Role', $filter, \@slice, 'Role(id) Role(description)');
        for my $tuple (@tuples) {
            $retVal{$tuple->[0]} = $tuple->[1];
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%retVal;
}

=head3 fids_for_md5

    my $md5H = $helper->fids_for_mdr(\@md5s);

Returns a reference to a hash table mapping md5s to lists
of fids.  Thus, $md5H->{$md5} will be undefined or a reference to a
list of fids.


=over 4

=item md5s

A reference to a list of md5 values to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming md5 to a list of fids

=back

=cut

sub fids_for_md5 {
    my($self,$md5s) = @_;

    my $shrub = $self->{shrub};
    my %md5H;

    my $start = 0;
    while ($start < @$md5s) {
        # Get this chunk.
        my $end = $start + 100;
        if ($end >= @$md5s) {
            $end = @$md5s - 1;
        }
        my @slice = @{$md5s}[$start .. $end];
        my $filter = 'Protein2Feature(to-link) IN (' . join(', ', map { '?' } @slice) . ')';
        my @tuples = $shrub->GetAll('Protein2Feature', $filter, \@slice,
                                    'Protein2Feature(from-link) Protein2Feature(to-link)');
        for my $tuple (@tuples) {
            push(@{$md5H{$tuple->[0]}},$tuple->[1]);
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%md5H;
}

=head3 dna_fasta

    my $fastaHash = $helper->dna_fasta(\@fids);

Return the DNA sequence translation for each incoming feature.

=over 4

=item fids

A reference to a list of IDs for the features to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming feature ID to its DNA sequence. A nonexistent
feature will not appear in the hash.

=back

=cut

sub dna_fasta {
    my ($self, $fids) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Partition the input list by genome ID.
    my %genomes;
    for my $fid (@$fids) {
        if ($fid =~ /^fig\|(\d+\.\d+)/) {
            push @{$genomes{$1}}, $fid;
        }
    }
    # Process each genome separately.
    require Shrub::Contigs;
    for my $genome (keys %genomes) {
        # Get the contig object for this genome.
        my $contigs = Shrub::Contigs->new($shrub, $genome);
        # Loop through the features, getting the sequences.
        for my $fid (@{$genomes{$genome}}) {
            my $sequence = $contigs->fdna($fid);
            if ($fid) {
                $retVal{$fid} = $sequence;
            }
        }
    }
    return \%retVal;
}

=head3 genome_fasta

    my $triplesHash = $helper->genome_fasta(\@genomes, $mode);

Produce FASTA data containing sequences for one or more genomes. The FASTA data is in the form of
3-tuples (id, comment, sequence) with the comment field blank.

=over 4

=item genomes

Reference to a list of genome IDs.

=item mode

The type of sequences desired: C<dna> for DNA sequences of the contigs, C<prot> for protein sequences
of the protein-encoding genes.

=item RETURN

Returns a reference to a hash mapping each incoming genome ID to a list of 3-tuples for the sequences,
each 3-tuple consisting of (0) a contig or feature ID, (1) an empty string, and (2) the sequence itself.

=back

=cut

sub genome_fasta {
    my ($self, $genomes, $mode) = @_;
    my %retVal;
    # Get the shrub database.
    my $shrub = $self->{shrub};
    # Loop through the genome IDs.
    for my $genome (@$genomes) {
        my @tuples;
        if ($mode eq 'dna') {
            # Here we need contigs.
            require Shrub::Contigs;
            my $contigs = Shrub::Contigs->new($shrub, $genome);
            @tuples = $contigs->tuples;
        } else {
            # Here we need protein sequences.
            $shrub->write_prot_fasta($genome, \@tuples);
        }
        $retVal{$genome} = \@tuples;
    }
    # Return the FASTA triples hash.
    return \%retVal;
}


=head3 genome_statistics

    my $genomeHash = $helper->genome_statistics(\@genomeIDs, @fields);

Return a hash mapping each incoming genome ID to a list of field values.

=over 4

=item genomeIDs

A reference to a list of IDs for the genomes to be processed.

=item fields

A list of field names, consisting of one or more of the following.

=over 8

=item contigs

The number of contigs in the genome.

=item dna-size

The number of base pairs in the genome.

=item domain

The domain of the genome (Eukaryota, Bacteria, Archaea).

=item gc-content

The percent GC content of the genome.

=item name

The name of the genome.

=item genetic-code

The DNA translation code for the genome.

=back

=item RETURN

Returns a reference to a hash mapping each incoming genome ID to a list reference containing all the field values,
in order.

=back

=cut

sub genome_statistics {
    my ($self, $genomeIDs, @fields) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Break the input list into batches and retrieve a batch at a time.
    my $start = 0;
    while ($start < @$genomeIDs) {
        # Get this chunk.
        my $end = $start + 10;
        if ($end >= @$genomeIDs) {
            $end = @$genomeIDs - 1;
        }
        my @slice = @{$genomeIDs}[$start .. $end];
        # Compute the functions for this chunk.o
        my $filter = 'Genome(id) IN (' . join(', ', map { '?' } @slice) . ')';
        my @tuples = $shrub->GetAll('Genome', $filter, [@slice], ['id', @fields]);
        for my $tuple (@tuples) {
            my ($gid, @data) = @$tuple;
            $retVal{$gid} = \@data;
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%retVal;
}


=head3 ss_to_roles

    my $ssHash = $helper->ss_to_roles(\@ssIds);

Return a hash mapping each incoming subsystem ID to a list of roles

=over 4

=item genomeIDs

A reference to a list of IDs for the subsystems to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming subsystem ID to a list reference containing all the roles

=back

=cut

sub ss_to_roles {
    my ($self, $ssIDs) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    foreach my $id (@$ssIDs) {
        @{$retVal{$id}} =
                    $shrub->GetAll('Subsystem2Role Role', 'Subsystem2Role(from-link) = ? ORDER BY Subsystem2Role(ordinal)', [$id],
                        'Role(id) Role(description)');

    }
    return \%retVal;
}

=head3 genome_of

    my $fidHash = $helper->genome_of(\@fids);

Return a hash mapping each incoming feature ID to the ID of its owning genome.

=over 4

=item fids

Reference to a list of feature IDs.

=item RETURN

Returns a reference to a hash mapping each feature ID to the ID of the genome in which it is contained.
A feature ID with an invalid format will not appear in the hash.

=back

=cut

sub genome_of {
    my ($self, $fids) = @_;
    my %retVal;
    for my $fid (@$fids) {
        if ($fid =~ /^fig\|(\d+\.\d+)/) {
            $retVal{$fid} = $1;
        }
    }
    return \%retVal;
}

=head3 contigs_of

    my $genomeHash = $helper->contigs_of(\@genomeIDs);

Return a hash mapping each incoming genome ID to a list of its contig IDs.

=over 4

=item genomeIDs

A reference to a list of IDs for the genomes to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming genome ID to a list reference containing all the contigs for
that genome.

=back

=cut

sub contigs_of {
    my ($self, $genomeIDs) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $gid (@$genomeIDs) {
        # Get the IDs of the desired contigs.
        my @contigIDs = $shrub->GetFlat('Genome2Contig',
                'Genome2Contig(from-link) = ?', [$gid], 'to-link');
        # Store the returned contig IDs with the genome ID.
        $retVal{$gid} = \@contigIDs;
    }
    return \%retVal;
}

=head3 is_CS

    my $csHash = $helper->is_CS($v,\@genome_or_peg_ids);

Keep only rows with coreSEED genome or peg IDs (or the reverse)

=over 4

=item v

If $v keep lines that do not contain coreSEED ids

=item genome_or_peg_ids

A reference to a list of IDs to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming id to be kept to 1

=back

=cut

sub is_CS {
    my ($self, $v,$genome_or_peg_ids) = @_;
    my %retVal;
    my $shrub = $self->{shrub};
    my $core = $shrub->all_genomes('core');
    foreach my $id (@$genome_or_peg_ids)
    {
        if ((($id =~ /^(\d+\.\d+)$/) || ($id =~ /^fig\|(\d+\.\d+)/)) && $core->{$1})
        {
            $retVal{$id} = $v ? 0 : 1;
        }
        else
        {
            $retVal{$id} = $v ? 1 : 0;
        }
    }
    return \%retVal;
}

=head3 desc_to_role

    my $roleMapHash = $helper->desc_to_role(\@role_descs);

Return the role IDs corresponding to a set of descriptions.

=over 4

=item role_descs

A reference to a list of descriptions for the roles to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming role description to a role ID.
An invalid role description will not produce a map entry;

=back

=cut

sub desc_to_role {
    my ($self, $role_descs) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Get access to the role normalizer.
    require Shrub::Roles;
    # Loop through the role descriptions.
    for my $desc (@$role_descs) {
        # Compute the role's checksum.
        my $checksum = Shrub::Roles::Checksum($desc);
        # Compute the ID for this checksum.
        my ($id) = $shrub->GetFlat('Role', 'Role(checksum) = ?', [$checksum], 'id');
        if ($id) {
            $retVal{$desc} = $id;
        }
    }
    return \%retVal;
}

=head3 desc_to_function

    my $funcMapHash = $helper->desc_to_function(\@func_descs);

Return the function IDs corresponding to a set of descriptions.

=over 4

=item func_descs

A reference to a list of descriptions for the functions to be processed.

=item RETURN

Returns a reference to a hash mapping each incoming function description to a function ID.
An invalid function description will not produce a map entry;

=back

=cut

sub desc_to_function {
    my ($self, $function_descs) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    # Get access to the function parser.
    require Shrub::Functions;
    # Loop through the function descriptions.
    for my $desc (@$function_descs) {
        # Split the function into roles.
        my (undef, $sep, $roles) = Shrub::Functions::Parse($desc);
        # Convert the roles to IDs.
        my $roleMap = $self->desc_to_role($roles);
        # Assemble the role IDs into a function ID.
        $retVal{$desc} = join($sep, map { $roleMap->{$_} } @$roles);
    }
    return \%retVal;
}

=head3 genes_in_region

    my $geneList = $helper->genes_in_region($targetLoc, $priv);

Return a list of all the features that overlap the specified region.

=over 4

=item targetLoc

A L<BasicLocation> for the region whose features are desired.

=item priv

Privilege level for functional assignments.

=item RETURN

Returns a reference to a list of 4-tuples, one for each feature that overlaps the region. Each
4-tuple contains (0) the feature ID, (1) a L<BasicLocation> describing the full extent of its
segments on the target contig, (2) the ID of its assigned function, and (3) the description of its
assigned function.

=back

=cut

sub genes_in_region {
    my ($self, $targetLoc, $priv) = @_;
    my $shrub = $self->{shrub};
    # Our results go in here.
    my @retVal;
    # Get the target contig.
    my $contig = $targetLoc->Contig;
    # Get the length of the longest feature for the genome that owns this contig.
    my ($limit) = $shrub->GetFlat('Contig2Genome Genome', 'Contig2Genome(from-link) = ?', [$contig],
            'Genome(longest-feature)');
    # Every feature that overlaps MUST start to the left of this point.
    my $leftLimit = $targetLoc->Left - $limit;
    # Form a query to get all the overlapping segments. We get a segment if it starts to the left of
    # the end point and it starts to the right of the limit point.
    my $filter = 'Contig2Feature(from-link) = ? AND Contig2Feature(begin) <= ? AND (Contig2Feature(begin) >= ? AND Feature2Function(security) = ?)';
    my $parms = [$contig, $targetLoc->Right, $leftLimit, $priv];
    my @feats = $shrub->GetAll('Contig2Feature Feature Feature2Function Function', $filter, $parms,
        'Contig2Feature(to-link) Contig2Feature(begin) Contig2Feature(dir) Contig2Feature(len) Feature(sequence-length) Function(id) Function(description) Feature2Function(comment)');
    # Now loop through the features, keeping the ones that truly overlap the region. If a feature's
    # total length does not match the segment length, we get the rest of its segments. We use a hash to
    # skip over features we've already processed.
    my %feats;
    for my $feat (@feats) {
        my ($fid, $begin, $dir, $len, $totLen, $funcID, $funcName, $comment) = @$feat;
        # Only proceed if this feature is new.
        if (! $feats{$fid}) {
            # Get the feature's location.
            my $loc = BasicLocation->new([$contig, $begin, $dir, $len]);
            if ($targetLoc->Overlap($loc)) {
                # Check for multiple segments.
                if ($len < $totLen) {
                    my @locs = map { BasicLocation->new($_) } $shrub->GetAll('Feature2Contig',
                            'Feature2Contig(from-link) = ? AND Feature2Contig(to-link) = ?',
                            [$fid, $contig], 'contig begin dir len');
                    for my $loc2 (@locs) {
                        $loc->Merge($loc2);
                    }
                }
            }
            # Add the comment (if any) to the function name.
            if ($comment) {
                $funcName .= " # $comment";
            }
            # Now $loc is the full location of the feature.
            push @retVal, [$fid, $loc, $funcID, $funcName];
            $feats{$fid} = 1;
        }
    }
    # Return the features fount.
    return \@retVal;
}

=head3 roles_in_genomes

    my $genomeHash = $helper->roles_in_genome(\@genomeIDs, $priv, $ssOnly);

Return a hash mapping each incoming genome ID to a list of contained roles.

=over 4

=item genomeIDs

A reference to a list of IDs for the genomes to be processed.

=item priv

Privilege level for the functional assignments used.

=item ssOnly

If TRUE, then only roles in subsystems will be returned.

=item RETURN

Returns a reference to a hash mapping each incoming genome ID to a list reference containing all the roles for
that genome.

=back

=cut

sub roles_in_genomes {
    my ($self, $genomeIDs, $priv, $ssOnly) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $gid (@$genomeIDs) {
        # Get the IDs of the desired contigs.
        my @roleIDs = $shrub->GetFlat('Genome2Feature Feature2Function Function2Role',
                'Genome2Feature(from-link) = ? AND Feature2Function(security) = ?',
                [$gid, $priv], 'Function2Role(to-link)');
        # Store the returned role IDs for the genome ID.
        my %uniq = map { $_ => 1 } @roleIDs;
        # Do the subsystem filtering.
        if ($ssOnly) {
            for my $role (keys %uniq) {
                my ($ss) = $shrub->GetFlat('Role2Subsystem', 'Role2Subsystem(from-link) = ? LIMIT 1', [$role], 'to-link');
                if (! $ss) {
                    delete $uniq{$role};
                }
            }
        }
        $retVal{$gid} = [sort keys(%uniq)];
    }
    return \%retVal;
}

=head3 fid_locations

    my $fidHash = $helper->fid_locations(\@fids, $just_boundaries);

Return a hash mapping each incoming fid to a location on a contig.

=over 4

=item fids

A reference to a list of Feature ids

=item just_boundaries

If TRUE, a single location will be returned for each feature. Otherwise, a list of locations will be
returned.

=item RETURN

Returns a reference to a hash mapping each incoming fid to a list of location strings.

=back

=cut

sub fid_locations {
    my ($self, $fids, $just_boundaries) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $fid (@$fids) {
        my @locs;
        if ($just_boundaries) {
            @locs = ($shrub->loc_of($fid));
        } else {
            @locs = $shrub->fid_locs($fid);
        }
        $retVal{$fid} = [ map { $_->String } @locs ];
    }
    # This should build on fid_locs or loc-of, but I do not get it <<<<<<<
    return \%retVal;
}

=head3 roles_to_implied_reactions

    my @reactions = $shrub->roles_to_implied_reactions($roles,$frac);

Takes as input a set of roles, and a fraction ($frac).  Active complexes are
computed as those for which $frac of the connected roles are present in the
input Roles.  Then, the output list of reactions is formed as those conneting
to the active complexes.

=over

=item $roles

A pointer to a list of roles.  Normally these would be the list of roles that are present in
a new genome.

=item $frac (defaults to 0.5)

Complexes are considered "potentially active" if the fraction of connected
roles (from the input set) exceeds this value.  In some contexts, using a value
of 0.0001, which would make any complex connecting to at least one role active,
makes sense.

=item RETURN

Returns a list of potentionally active reactions.

=back

=cut

sub roles_to_implied_reactions {
    my ($self,$roles,$frac) = @_;

    my %complex2Role_all;
    my %complex2Role_in;
    my %complex2Reaction;
    my $shrub = $self->{shrub};
    my @tuples = $shrub->GetAll('Complex2Role','',[],'Complex2Role(from-link) Complex2Role(to-link)');
    foreach my $tuple (@tuples)
    {
        my($complex,$role) = @$tuple;
        $complex2Role_all{$complex}->{$role} = 1;
    }
    foreach my $role (@$roles)
    {
        @tuples = $shrub->GetAll('Role2Complex','Role2Complex(from-link) = ?',[$role],
                                'Role2Complex(to-link)');
        foreach my $tuple (@tuples)
        {
            my($complex) = @$tuple;
            $complex2Role_in{$complex}->{$role} = 1;
        }
    }

    my %reactions;
    foreach my $complex (keys(%complex2Role_in))
    {
        my $in_input = $complex2Role_in{$complex};
        my $in_all   = $complex2Role_all{$complex};
        if ((keys(%$in_all) * $frac) <= keys(%$in_input))
        {
            @tuples = $shrub->GetAll('Complex2Reaction',
                                    'Complex2Reaction(from-link) = ?', [$complex],
                                    'Complex2Reaction(to-link)');
            foreach my $tuple (@tuples)
            {
                my($reaction) = @$tuple;
                $reactions{$reaction} = 1;
            }
        }
    }
    return sort keys(%reactions);
}

=head3 reactions_to_implied_pathways

    my @pathways = $helper->reactions_to_implied_pathways($reactions, $frac);

Takes as input a set of reactions, and a fraction ($frac).  Active pathways are
computed as those for which $frac of the connected reactions are present in the
input Reactions.

=over

=item $reactions

A reference to a list of reaction IDs.  Normally these would be the list of reactions that are present in
a new genome.

=item $frac (defaults to 0.5)

Pathways are considered "potentially active" if the fraction of connected
reactions (from the input set) exceeds this value.  In some contexts, using a value
of 0.0001, which would make any pathway connecting to at least one reaction active,
makes sense.

=item RETURN

Returns a list of the IDs for the potentionally active pathways.

=back

=cut

sub reactions_to_implied_pathways {
    my ($self, $reactions, $frac) = @_;
    my $shrub = $self->{shrub};
    my %pathway2Reaction_in;
    foreach my $reaction (@$reactions)
    {
        my @paths = $shrub->GetFlat('Reaction2Pathway','Reaction2Pathway(from-link) = ?',[$reaction],
                                'Reaction2Pathway(to-link)');
        foreach my $pathway (@paths)
        {
            $pathway2Reaction_in{$pathway}->{$reaction} = 1;
        }
    }

    my %pathways;
    foreach my $pathway (keys(%pathway2Reaction_in))
    {
        my $in_input = $pathway2Reaction_in{$pathway};
        my %in_all = map { $_ => 1 } $shrub->GetFlat('Pathway2Reaction', 'Pathway2Reaction(from-link) = ?',
                [$pathway], 'Pathway2Reaction(to-link)');
        if ((keys(%in_all) * $frac) <= keys(%$in_input))
        {
            $pathways{$pathway} = 1;
        }
    }
    return sort keys(%pathways);
}

=head3 pathways_to_reactions

    my $pathwayHash = $helper->pathways_to_reactions(\@pathways);

Create a hash that maps each incoming pathway to a list of its reactions. Each reaction will be
represented by a 2-tuple consisting of reaction ID and name.

=over 4

=item pathways

Reference to a list of pathway IDs.

=item RETURN

Returns a reference to a hash mapping each incoming pathway ID to a list of 2-tuples, each 2-tuple
containing (0) a reaction ID and (1) a reaction name.

=back

=cut

sub pathways_to_reactions {
    my ($self, $pathways) = @_;
    my %retVal;
    my $shrub = $self->{shrub};
    for my $pathway (@$pathways) {
        my @reactionTuples = $shrub->GetAll('Pathway2Reaction Reaction', 'Pathway2Reaction(from-link) = ?',
                [$pathway], 'Reaction(id) Reaction(name)');
        if (@reactionTuples) {
            $retVal{$pathway} = \@reactionTuples;
        }
    }
    return \%retVal;
}


=head3 genome_feature_roles

    my $roleHash = $helper->genome_feature_roles($genomeID, $priv);

Create a hash mapping each role found in a genome to its features.

=over 4

=item genomeID

The ID of the target genome.

=item priv

Privilege level for the relevant functional assignments. The default is C<0>.

=item RETURN

Returns a hash mapping each role to a list of feature IDs from the genome.

=back

=cut

sub genome_feature_roles {
    my ($self, $genomeID, $priv) = @_;
    $priv //= 0;
    my $shrub = $self->{shrub};
    my %retVal;
    # Get the features and roles.
    my @fidTuples = $shrub->GetAll('Feature2Function Function2Role',
            'Feature2Function(from-link) LIKE ? AND Feature2Function(security) = ?',
            ["fig|$genomeID.%", $priv], 'Function2Role(to-link) Feature2Function(from-link)');
    # Map each role to a list of features.
    for my $fidTuple (@fidTuples) {
        my ($role, $fid) = @$fidTuple;
        push @{$retVal{$role}}, $fid;
    }
    # Return the result hash.
    return \%retVal;
}


=head3 reaction_formula

    my $rxnHash = $helper->reaction_formula(\@rxnIDs);

Return a hash mapping each incoming reaction ID to its chemical formula string.

=over 4

=item rxnIDs

A reference to a list of reaction ids

=item names

If TRUE, then compound names will be displayed instead of compound formulae.

=item RETURN

Returns a reference to a hash mapping each incoming reaction ID to a chemical formula string.

=back

=cut

use constant CONNECTORS => { '<' => '<=', '=' => '<=>', '>' => '=>' };

sub reaction_formula {
    my ($self, $rxnIDs, $names) = @_;
    my $shrub = $self->{shrub};
    my $cField = 'Compound(' . ($names ? 'label' : 'formula') . ')';
    my %retVal;
    for my $rxnID (@$rxnIDs) {
        # Get the reaction compounds and the information about each.
        my @formulaData = $shrub->GetAll('Reaction Reaction2Compound Compound', 'Reaction(id) = ?', [$rxnID],
                "Reaction(direction) Reaction2Compound(product) Reaction2Compound(stoichiometry) $cField");
        # Only proceed if we found the reaction.
        if (@formulaData) {
            # We accumulate the left and right sides separately.
            my @side = ([], []);
            my $dir;
            for my $formulaDatum (@formulaData) {
                my ($direction, $product, $stoich, $form) = @$formulaDatum;
                my $compound = ($stoich > 1 ? "$stoich*" : '') . $form;
                push @{$side[$product]}, $compound;
                $dir //= CONNECTORS->{$direction};
            }
            # Join it all together.
            my $string = join(" $dir ", map { join(" + ", @$_) } @side);
            # Store the formula in the return hash.
            $retVal{$rxnID} = $string;
        }
    }
    # Return the result hash.
    return \%retVal;
}

=head3 find_similar_region

    my ($similarRegion, $pinFid) = $helper->find_similar_region($genome, $regionLen, $pinFunc, $funcList, $priv);

Find a region of the specified length in the specified genome that
surrounds the specified function and contains as many of the specified
functions as possible. The idea is to find a region that is functionally
close to a region taken from another genome.

=over 4

=item genome

ID of the target genome.

=item regionLen

Length of the region to find.

=item pinFunc

The ID of the function of interest. A feature assigned to this function will be in the center of the
returned region.

=item funcList

Reference to a list of function IDs. If there is more than one possible target region, we will return
the one with the most functions from this list.

=item priv

Privilege level for functional assignments. The default is C<0>.

=item RETURN

Returns a two-element list consisting of (0) a L<BasicLocation> object for the desired region, and (1) the
ID of the feature in that region possessing the incoming pinned function.

=back

=cut

sub find_similar_region {
    # Get the parameters.
    my ($self, $genome, $regionLen, $pinFunc, $funcList, $priv) = @_;
    # Default the privilege.
    $priv //= 0;
    # Get the database.
    my $shrub = $self->{shrub};
    # Declare the return variables.
    my ($similarRegion, $pinFid);
    # Find all the occurrences of the specified function ID in the specified genome.
    my $filter = 'Function2Feature(from-link) = ? AND Function2Feature(security) = ? AND Function2Feature(to-link) LIKE ?';
    my @fids = $shrub->GetFlat('Function2Feature', $filter, [$pinFunc, $priv, "fig|$genome.%"], 'to-link');
    # This will hold our best region's function count.
    my $bestCount = 0;
    # Loop through the features found, testing each one.
    for my $fid (@fids) {
        # Get the feature's location, and widen it to the appropriate length by extending in both directions.
        my $fidLoc = $shrub->loc_of($fid);
        my $extent = ($regionLen - $fidLoc->Length) / 2;
        $fidLoc->Widen($extent);
        # Count the functions in the specified region.
        my $funCount = 0;
        my %func = map { $_ => 1 } @$funcList;
        my @fidsInRegion = map { $_->[0] } $shrub->FeaturesInRegion($fidLoc->Contig, $fidLoc->Left, $fidLoc->Right);
        my $fidToFunc = $shrub->Feature2Function($priv, \@fidsInRegion);
        for my $fidInRegion (@fidsInRegion) {
            my $funcID = $fidToFunc->{$fid}[0];
            if ($func{$funcID}) {
                $funCount++;
                $func{$funcID} = 0;
            }
        }
        # If this is the best region, keep it.
        if ($funCount > $bestCount) {
            $bestCount = $funCount;
            $similarRegion = $fidLoc;
            $pinFid = $fid;
        }
    }
    # Return the results.
    return ($similarRegion, $pinFid);
}

=head3 convert_to_link

    my $link = $helper->convert_to_link($type => $element, \%linkData);

Convert an ID of the specified type to a URL. If the ID cannot be
converted, an undefined value will be returned.

=over 4

=item type

Type of ID to convert. Currently, only feature (C<fid>) is supported.

=item element

Data element to be converted.

=item linkData

Reference to a hash that can be used to cache intermediate and reference data.

=item RETURN

Returns the URL of the specified ID, or C<undef> if there is none.

=back

=cut

sub convert_to_link {
    # Get the parameters.
    my ($self, $type, $element, $linkData) = @_;
    # Declare the return variable.
    my $retVal;
    # Get the database.
    my $shrub = $self->{shrub};
    # Attempt to convert the feature ID to a genome ID.
    if ($element =~ /^fig\|(\d+\.\d+)/) {
        my $genome = $1;
        # We succeeded. Check to see if the genome is a core genome.
        if (! defined $linkData->{$genome}) {
            # We haven't seen it before. Cache it's status in the hash.
            my ($core) = $shrub->GetFlat('Genome', 'Genome(id) = ?', [$genome], 'core');
            $linkData->{$genome} = ($core // 0);
        }
        if ($linkData->{$genome}) {
            # We have a core genome. Form the URL.
            $retVal = "http://core.theseed.org/FIG/seedviewer.cgi?page=Annotation;feature=$element";
        }
    }
    # Return the result.
    return $retVal;
}

=head3 gto_of

    my $gto = $helper->gto_of($genomeID);

Return a L<GenomeTypeObject> for the specified genome.

=over 4

=item genomeID

ID of the source genome.

=item RETURN

Returns a L<GenomeTypeObject> for the genome, or C<undef> if the genome was not found.

=back

=cut

sub gto_of {
    my ($self, $genomeID) = @_;
    require Shrub::GTO;
    my $shrub = $self->{shrub};
    my $retVal = Shrub::GTO->new($shrub, $genomeID);
    return $retVal;
}

=head3 rep_genomes

    my $genomeList = $helper->rep_genomes(\@requests, \@blacklist);

Return a list of representative genomes. These are selected from leaf nodes as far
apart as possible on the taxonomy tree inside specified subtrees. This is an expensive
algorithm, as it requires reading the entire genome table and traversing the taxonomy tree
twice.

=over 4

=item requests

Reference to a list of 2-tuples. Each 2-tuple consists of (0) a taxonomy ID or name
and (1) a number of requested genomes.

=item blacklist (optional)

Reference to a list of IDs for taxonomic groupings to avoid.

=item RETURN

Returns a reference to a list of 2-tuples, each consisting of (0) a genome name and (1) a genome ID.

=back

=cut

sub rep_genomes {
    my ($self, $requests, $blacklist) = @_;
    # Get the database.
    my $shrub = $self->{shrub};
    # Compute the blacklist hash.
    my %blackH;
    if ($blacklist) {
        %blackH = map { $_ => 1 } @$blacklist;
    }
    # First we create our in-memory taxonomy tree.
    require Shrub::Taxonomy;
    my $taxTree = Shrub::Taxonomy->new($shrub);
    # Now we have all the taxonomy information we need. Begin processing requests.
    my @retVal;
    my @requests = @$requests;
    while (@requests) {
        my $request = pop @requests;
        my ($taxon, $count) = @$request;
        # Get the specified taxon group.
        my $taxID = $taxTree->tax_id($taxon) // $taxon;
        # Determine how many genomes we can get from it.
        my $taxCount = $taxTree->count($taxID);
        if ($count > $taxCount) {
            $count = $taxCount;
        }
        # Is this a leaf?
        my $children = $taxTree->children($taxID);
        if (! @$children) {
            # Yes. Get some genomes.
            my $genomes = $taxTree->genomes($taxID);
            for (my $i = 0; $i < $count; $i++) {
                push @retVal, $genomes->[$i];
            }
        } else {
            # Not a leaf. Get the children and sort them by count. We eliminate blacklist items here.
            my @whiteChildren = grep { ! $blackH{$_} } @$children;
            my @childSpecs = sort { $a->[1] <=> $b->[1] } map { [$_, $taxTree->count($_)] } @whiteChildren;
            # Loop through the children, creating requests.
            my $residual = $count;
            while (@childSpecs) {
                my $requirement = int($residual / scalar(@childSpecs));
                my $childSpec = shift @childSpecs;
                my ($childID, $childCount) = @$childSpec;
                if ($requirement > $childCount) {
                    $requirement = $childCount;
                }
                if ($requirement) {
                    push @requests, [$childID, $requirement];
                    $residual -= $requirement;
                }
            }
        }
    }
    return \@retVal;
}


1;