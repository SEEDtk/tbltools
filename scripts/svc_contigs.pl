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

=head1 Get Contigs of Genomes

    svc_contigs.pl [ options ]

Get the contigs for a genome and optionally the contig sequences.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output fields will be appended to the end of each input row.
Rows with invalid genome IDs will be removed from the output. Because a genome can have many contigs,
there may be more output rows than input rows.

=over 4

=item sequences

If specified, the contig IDs and DNA sequences will be output. Otherwise, just the contig IDs will be output.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ['sequences|v', 'if specified, both contig IDs and sequences will be output']);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my @gids = map { $_->[0] } @batch;
    my %resultsH;
    # Are we looking for sequences?
    if ($opt->sequences) {
        # Yes. Use the genome fasta service.
        my $triplesH = $helper->genome_fasta(\@gids, 'dna');
        for my $genome (keys %$triplesH) {
            my $triples = $triplesH->{$genome};
            $resultsH{$genome} = [ map { [$_->[0], $_->[2]] } @$triples ];
        }
    } else {
        # No. Use the contigs service.
        my $contigsH = $helper->contigs_of(\@gids);
        for my $genome (keys %$contigsH) {
            my $contigs = $contigsH->{$genome};
            $resultsH{$genome} = [ map { [$_] } @$contigs ];
        }
    }
    # Now %resultsH maps each genome to a list of lists, either of the form [[c1], [c2], ...] or
    # [[c1,s1], [c2,s2] ...]. Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Loop through the input value's results;
        my $results = $resultsH{$value};
        if ($results) {
            for my $result (@$results) {
                # Output this result with the original row.
                print join("\t", @$row, @$result), "\n";
            }
        }
    }
}