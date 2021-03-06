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

=head1 Filter Prokaryotic Genomes

This is used to filter a column of genome ids or a column
of feature IDs, keeping only those for prokaryotic genomes.

Thus,

    svc_all_genomes | svc_is_prokaryotic

would give you just the prokaryotic genomes.

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> (database connection) and
L<ScriptUtils/ih_options> (standard input) plus the following.

=over 4

=item invert

Keep only non-prokaryotic genomes/features.  That is, this reverses the
retention condition.

=back

=cut


# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',["invert|v","invert retention condition"]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
my $v = $opt->invert;
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $csH = $helper->is_prokaryotic($v,[map { $_->[0] } @batch]);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Check for a result.
        my $result = $csH->{$value};
        if ($result) {
            # We have one, so output this result with the original row.
            print join("\t", @$row), "\n";
        }
    }
}
