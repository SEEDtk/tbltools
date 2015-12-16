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
        # Compute the translatins for this chunk.o
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

    my $fastaHash = $helper->dna_fasta(\@fids, $mode);

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


1;
