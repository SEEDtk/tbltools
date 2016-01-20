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

=head3 role_to_reactions

    my $reactionHash = $helper->role_to_features(\@roleIDs);

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
        my @tuples = $shrub->GetAll('Role', $filter, \@slice,
                'Role(id) Role(description) Role(ec-number) Role(tc-number)');
        for my $tuple (@tuples) {
            $retVal{$tuple->[0]} = Shrub::FormatRole($tuple->[2], $tuple->[3], $tuple->[1]);
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
        @{$retVal{$id}} = map { [$_->[0], Shrub::FormatRole($_->[1], $_->[2], $_->[3])] }
                    $shrub->GetAll('Subsystem2Role Role', 'Subsystem2Role(from-link) = ? ORDER BY Subsystem2Role(ordinal)', [$id],
                        'Role(id) Role(ec-number) Role(tc-number) Role(description)');

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
        my ($roleText) = Shrub::Roles::Parse($desc);
        my $normalized = Shrub::Roles::Normalize($roleText);
        my $checksum = Shrub::Checksum($normalized);
        # Compute the ID for this checksum.
        my ($id) = $shrub->GetFlat('Role', 'Role(checksum) = ?', [$checksum], 'id');
        if ($id) {
            $retVal{$desc} = $id;
        }
    }
    return \%retVal;
}

=head3 roles_in_genome

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

    my @tuples = $self->GetAll('Complex2Role','',[],'Complex2Role(from-link) Complex2Role(to-link)');
    foreach my $tuple (@tuples)
    {
        my($complex,$role) = @$tuple;
        $complex2Role_all{$complex}->{$role} = 1;
    }
    foreach my $role (@$roles)
    {
        @tuples = $self->GetAll('Role2Complex','Role2Complex(from-link) = ?',[$role],
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
            @tuples = $self->GetAll('Complex2Reaction',
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


1;