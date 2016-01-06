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

=head1 Filter Out Roles Not in Subsystems

    svc_role_ss_filter.pl [ options ]

Remove from the input lines containing roles not in subsystems. Alternatively, the results can be inverted,
removing lines with roles that are in subsystems.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output file will contain a subset of the lines from the input file.
The input column should contain role IDs.

The following additional command-line options are supported.

=over 4

=item invert

Invert the output: that is, only output lines with roles not in subsystems.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('parms',
        ["invert|v", "output roles not in subsystems"]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the inversion flag.
my $v = $opt->invert;
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->role_to_ss([map { $_->[0] } @batch], 'idform');
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Do we keep this line?
        if ($resultsH->{$value} xor $v) {
            print join("\t", @$row), "\n";
        }
    }
}