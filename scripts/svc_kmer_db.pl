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

=head1 Create a Kmer Database

    svc_kmer_db.pl [ options ]

Create a kmer database from input sequences.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The sequences to be scanned for kmers are taken from the input column.

The input file is tab-delimited. The output is a json kmer database, not a standard tab-delimited output file.

The additional command-line options are as follows

=over 4

=item id

The index (1-based) of the column containing group IDs. Each kmer is associated with a group, and the L<scr_kmer_hits.pl>
script will record hits by group ID. This parameter is required.

=item name

The index (1-based) of the column containing group names. The default is the group ID column.

=item kmer

The size of each kmer. The default is C<10>.

=item maxFound

The number of kmer occurrences required for a kmer to be considered common. Common kmers are removed from the
database. The default is C<10>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ['id|i=i', 'index (1-based) of the column containing group IDs', { required => 1 }],
        ['name|n=i', 'index (1-based) of the column containing group names'],
        ['kmer|k=i', 'size of a kmer', { default => 10 }],
        ['maxFound|m=i', 'number of kmer occurrences requried for a kmer to be considered common', { default => 10 }],
        { nodb => 1 });
# Create the kmer database object.
my $kmerdb = KmerDb->new(kmerSize => $opt->kmer, maxFound => $opt->maxFound);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the group ID and name columns.
my $idCol = $opt->id;
my $nameCol = $opt->name // $idCol;
# Get the sequence column.
my $seqCol = $opt->col;
# Loop through it, processing sequences.
while (! eof $ih) {
    my ($sequence, $groupID, $groupName) = ServicesUtils::get_cols($ih, $seqCol, $idCol, $nameCol);
    $kmerdb->AddSequence($groupID, $sequence, $groupName);
}
# Save the computed database.
$kmerdb->Save(\*STDOUT);
