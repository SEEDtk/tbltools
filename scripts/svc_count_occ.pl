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

=head1 Count Occurrences

    svc_count_occ.pl [ options ]

This script counts the number of a times a particular value occurs in a column.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The value counted is taken from the input column. The typical output
will be a two-column table with the value followed by the count; however, the C<verbose> option can be
used to keep other columns from the input; in that case, the first line for a particular value will be output
with the count appended.

=over 4

=item verbose

If specified, then an entire input line will be output followed by the count; otherwise, only the
value counted will be output.

=item frequencySort

If specified, the output will be sorted from most frequent value to least frequent; otherwise, it will
be sorted by value.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ["verbose|v", "output entire input line for value's first row"],
        ["frequencySort|f", "sort by frequency"],
        { nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the options.
my $verbose = $opt->verbose;
# This hash tracks the counts.
my %counts;
# This hash tracks the output lines.
my %lines;
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Process the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Have we seen this value before?
        if (! $lines{$value}) {
            # No. Compute its output line.
            if ($verbose) {
                $lines{$value} = $row;
            } else {
                $lines{$value} = [$value];
            }
            # Count it. We've found 1.
            $counts{$value} = 1;
        } else {
            # Yes we have seen it before. Increment its count.
            $counts{$value}++;
        }
    }
}
# Output the results.
my @sorted;
if ($opt->frequencysort) {
    @sorted = sort { $counts{$b} <=> $counts{$a} } keys %counts;
} else {
    @sorted = sort keys %counts;
}
for my $value (@sorted) {
    print join("\t", @{$lines{$value}}, $counts{$value}) . "\n";
}
