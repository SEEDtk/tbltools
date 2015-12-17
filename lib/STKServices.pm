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
    my ($class, $opt) = @_;
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
    # Connect to the database.
    my $shrub = Shrub->new_for_script($opt);
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

    my $genomeList = $helper->all_genomes();

Return the ID and name of every genome in the database.

=over 4

=item RETURN

Returns a reference to a list of 2-tuples, each 2-tuple consisting of (0) a genome name and (1) a genome ID.
All of the genomes in the database are returned.

=back

=cut

sub all_genomes {
    my ($self) = @_;
    my $shrub = $self->{shrub};
    my @genomes = $shrub->GetAll('Genome', '', [], 'name id');
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

    my $featureHash = $helper->features_of(\@roleIDs, $priv);

Return a hash mapping each incoming role ID to a list of its feature IDs.

=over 4

=item roleIDs

A reference to a list of IDs for the roles to be processed.

=item priv

The privilege level for the relevant assignments.

=item RETURN

Returns a reference to a hash mapping each incoming role ID to a list reference containing all the features with that
role.

=back

=cut

sub role_to_features {
    my ($self, $roleIDs, $priv) = @_;
    my $shrub = $self->{shrub};
    my %retVal;
    for my $rid (@$roleIDs) {
        # Get the IDs of the desired features.
        my @fids = $shrub->GetFlat('Role2Function Function2Feature',
                'Role2Function(from-link) = ? AND Function2Feature(security) = ?', [$rid, $priv], 'Function2Feature(to-link)');
        # Store the returned features with the role ID.
        $retVal{$rid} = \@fids;
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

Return the descriptions corresponding to a set of role IDsn

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
                'Role(id) Role(description)');
        for my $tuple (@tuples) {
            $retVal{$tuple->[0]} = $tuple->[1];
        }
        # Move to the next chunk.
        $start = $end + 1;
    }
    return \%retVal;
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
        @{$retVal{$id}} = map { [$_->[0], FormatRole($_->[1], $_->[2], $_->[3])] }
                    $shrub->GetAll('Subsystem2Role Role', 'Subsystem2Role(from-link) = ? ORDER BY Subsystem2Role(ordinal)', [$id],
                        'Role(id) Role(ec-number) Role(tc-number) Role(description)');

    }
    return \%retVal;
}

=head3 FormatRole

    my $roleText = Shrub::FormatRole($ecNum, $tcNum, $description)'

Format the text of a role given its EC, TC, and description information.

=over 4

=item ecNum

EC number of the role, or an empty string if there is no EC number.

=item tcNum

TC number of the role, or an empty string if there is no TC number.

=item description

Descriptive text of the role.

=item RETURN

Returns the full display text of the role.

=back

=cut

sub FormatRole {
    return ($_[2] . ($_[0] ? " (EC $_[0])" : '') . ($_[1] ? " (TC $_[1])" : ''));
}

1;
