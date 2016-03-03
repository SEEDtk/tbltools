#!/usr/bin/env perl
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


use strict;
use warnings;
use ServicesUtils;
use KmerDb;

=head1 Count Kmer Hits in a Set of Source Sequences

    svc_kmer_hits.pl [ options ] kmerdb

Count the kmer hits in the incoming source sequences.  Each source group is associated with a source ID and
name. For each source ID, the kmer groups with the most hits will be returned.

We talk of incoming sequences being organized into I<sources> and the kmer database identifying I<groups>.
In most cases both the sources and groups are genomes. In this case, the output groups represent the closest
genomes to each of the source genomes. The rather uncomfortable general terminology is to allow the possibility
of counting kmers for other things, such as protein families and metagenomic bins.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options. The input column specifies the
sequences to be analyzed.

The positional parameter is the file name for the kmer database generated by L<svc_kmer_db.pl>.

The input file is tab-delimited. The output file is tab-delimited, but does not correspond to the input file
in the normal way. Each line contains five fields: (0) a source ID, (1) the corresponding source name, (2) the
number of kmer hits against the source by a particular group, (3) the group ID, and (4) the group name.

=over 4

=item id

The index (1-based) of the column containing source IDs. Each sequence is associated with a source, and the script
computes kmer hits for each source separately. This parameter is required.

=item name

The index (1-based) of the column containing source names. The default is the source ID column.

=item keep

The maximum number of groups to output for each source. Only the highest-scoring groups are output. The
default is to output them all.

=item minHits

The minimum number of kmer hits by a group for it to be considered significant. Groups with fewer hits are not
output. The default is C<400>.

=item geneticCode

The genetic code to use for translating source sequences. If this parameter is specified, the source sequences
are assumed to be DNA and the kmers are assumed to be proteins. If this parameter is NOT specified, it is presumed
the source and group sequences are of the same type.

=item prot

This parameter is a shorthand for C<--geneticCode=11>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('kmerdb',
        ['id|i=i', 'index (1-based) of the column containing group IDs', { required => 1 }],
        ['name|n=i', 'index (1-based) of the column containing group names'],
        ['keep|N=i', 'maximum number of groups to keep per source'],
        ['minHits|m=i', 'minimum number of hits to indicate a relevant group', { default => 400 }],
        ['geneticCode|g=i', 'genetic code for translating DNA source sequences'],
        ['prot|p', 'if specified, source sequences are bacterial DNA sequences'],
        { nodb => 1 }
        );
# Handle the genetic code specification.
my $genetic_code = $opt->geneticcode;
if ($opt->prot) {
    if (! $genetic_code) {
        $genetic_code = 11;
    } elsif ($genetic_code ne 11) {
        die "Genetic code specification incompatible with 'prot' option-- use one or the other.";
    }
}
# Get the data column indices.
my $seqCol = $opt->col;
my $idCol = $opt->id;
my $nameCol = $opt->name;
if (! defined $nameCol) {
    $nameCol = $idCol;
}
# Get the minimum hits and the keep count.
my $minHits = $opt->minhits;
my $keep = $opt->keep;
# Get the name of the kmer database.
my ($kmerFile) = @ARGV;
if (! $kmerFile) {
    die "You must specify a kmer database.";
} elsif (! -s $kmerFile) {
    die "Invalid kmer file name $kmerFile.";
}
# Read in the kmer database.
my $kmerdb = KmerDb->new(json => $kmerFile);
# The counts will be kept in here. The hash is keyed by source ID, and for each source ID there is a
# sub-hash keyed by group ID.
my %counts;
# This hash tracks the name of each source.
my %sources;
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (! eof $ih) {
    # Get the data columns from the current line.
    my ($seq, $id, $name) = ServicesUtils::get_cols($ih, $seqCol, $idCol, $nameCol);
    # Insure this source is in the hashes.
    if (! $sources{$id}) {
        $sources{$id} = $name;
        $counts{$id} = {};
    }
    # Count the hits in the sequence.
    $kmerdb->count_hits($seq, $counts{$id}, $genetic_code);
}
# All the sequences have been processed. Process the output, one source at a time.
for my $source (sort keys %sources) {
    # Get the counts for this source.
    my $countH = $counts{$source};
    # Eliminate the low hit counts.
    my @relevant = grep { $countH->{$_} >= $minHits } keys %$countH;
    # Sort the counts.
    my @groups = sort { $countH->{$b} <=> $countH->{$a} } @relevant;
    # If we are keeping only the best, truncate the list.
    if ($keep) {
        splice @groups, $keep;
    }
    # Now write the results.
    for my $group (@groups) {
        print join("\t", $source, $sources{$source}, $countH->{$group}, $group, $kmerdb->name($group)) . "\n";
    }
}
