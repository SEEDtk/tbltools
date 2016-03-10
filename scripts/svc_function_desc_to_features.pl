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

=head1 Find All Features for a function description

    svc_function_desc_to_features.pl [ options ]

Locate all of the features possessing a specific function.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input must be tab-delimited and contain Function descriptions in one column. The IDs of the features will
be added to the end of each input row. Since each function is associated with many features, there will be many
more output lines than input lines.

=over 4

=item priv

The privilege level of the assignment. The default is C<0>. This option has no meaning outside of SEEDtk.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('parm1 parm2 ...',
        ["priv|p", "assignment privilege level", { default => 0 }],
);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->function_desc_to_features([map { $_->[0] } @batch], $opt->priv);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Loop through the input value's results;
        my $results = $resultsH->{$value};
        for my $result (@$results) {
            # Output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}
