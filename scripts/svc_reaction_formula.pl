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

=head1 Output Reaction Formulas

    svc_reaction_formula.pl [ options ]

This script takes reaction IDs as input and outputs chemical formulas for those reactions.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output fields will be appended to the end of each input row.
Rows with invalid reaction IDs will be removed from the output.

The command-line options include the following.

=over 4

=item names

If specified, the compound names will be displayed instead of their chemical formulae.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', ['names|v', 'display compound names']);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->reaction_formula([map { $_->[0] } @batch], $opt->names);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Get input value's result.
        my $result = $resultsH->{$value};
        if ($result) {
            # Output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}