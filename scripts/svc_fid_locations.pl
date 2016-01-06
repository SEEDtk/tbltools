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

=head1 Common Services Function

    svc_fid_locations.pl [ options ]

Return the location strings for the incoming features.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output fields will be appended to the end of each input row.
Unless C<justBoundaries> is specified, there may be more than one location for each feature, in which
case there may be more output lines than input lines. Rows with invalid feature IDs will be removed from the output.

The following additional command-line options are supported.

=over 4

=item justBoundaries

Only return a single all-encompassing location for each feature. This parameter is mutually exclusive with
C<compressed>

=item compressed

Return multiple locations as a single comma-delimited string. This parameter is mutually exclusive with
<justBoundaries>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ["justBoundaries|j", "return a single location for each feature"],
        ["compressed|z", "return multiple locations as a single comma-delimited string"]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the options.
my $justBoundaries = $opt->justboundaries;
my $compressed = $opt->compressed;
if ($justBoundaries && $compressed) {
    warn "-justBoundaries and -compressed are mutually exclusive.";
}
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->fid_locations([map { $_->[0] } @batch], $justBoundaries);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Loop through the input value's results;
        my $results = $resultsH->{$value};
        # Check for compressed output.
        if ($compressed) {
            $results = [join(",", @$results)];
        }
        for my $result (@$results) {
            # Output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}