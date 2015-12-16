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

=head1 Translate Feature IDs to Protein Sequences

    svc_translation.pl [ options ]

Compute the protein translation of a feature. Features that do not have proteins will be removed from the input.
For protein-encoding features, the protein translation will be added.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

There are no positional parameters.

The input should be a tab-delimited file containing feature IDs in the specified column. The appropriate protein
translation will be appended to each input record in producing the output. Records containing the IDs of features
without protein translations will be removed.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('');
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->translation([map { $_->[0] } @batch]);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Check for a result.
        my $result = $resultsH->{$value};
        if ($result) {
            # We have one, so output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}
