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
use SeedUtils;

=head1 Find All Reactions for a Role

    svc_role_to_reactions.pl [ options ]

Locate all of the reactions connected to each role.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input must be tab-delimited and contain role IDs in one column. The ID and name of each
triggered raction will be added to the end of each input row. Since each role can trigger many reactions,
there will be many more output lines than input lines.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('');
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->role_to_reactions([map { $_->[0] } @batch]);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Loop through the input value's results;
        my $results = $resultsH->{$value};
        for my $result (@$results) {
            # Output this result with the original row.
            print join("\t", @$row, @$result), "\n";
        }
    }
}
