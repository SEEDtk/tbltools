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

=head1 Display Genome Statistics

    svc_genome_statistics.pl [ options ] field1 field2 ...

Retrieve basic data about genomes.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are the names of the fields to be retrieved. These may be one or more of the
following.

=over 4

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

The input file is tab-delimited. The output fields will be appended to the end of each input row.
Rows with invalid genome IDs will be removed from the output.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('field1 field2 ...');
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->genome_statistics([map { $_->[0] } @batch], @ARGV);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Append the input value's results;
        my $results = $resultsH->{$value};
        if ($results) {
            # Output this result with the original row.
            print join("\t", @$row, @$results), "\n";
        }
    }
}
