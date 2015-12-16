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

=head1 Get the Functions of Features

    svc_function_of.pl [ options ]

Compute the functional roles of one or more features.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input is a tab-delimited file. The functional role computed is added to the end of each row.
If an incoming feature ID is invalid it will not appear in the output.

=over 4

=item priv

The privilege level of the assignment. The default is C<0>. This option has no meaning outside of SEEDtk.

=item verbose

If specified, the text of the functional role will be returned instead of the function ID.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ["priv|p", "assignment privilege level", { default => 0 }],
        ["verbose|v", "return descriptions instead of IDs"]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->function_of([map { $_->[0] } @batch], $opt->priv, $opt->verbose);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Get through the input value's results;
        my $result = $resultsH->{$value};
        if ($result) {
            # Output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}
