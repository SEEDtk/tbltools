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

=head1 All Features for a Genome

    svc_all_features.pl [ options ] type

For each incoming genome, extract all the features, or optionally all the features of a specified type.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The single positional parameter is a feature type. If specified, only features of the specified type will
be returned. Otherwise, all features will be returned.

The returned feature IDs will be appended to the end of the input records. Since a genome will contain multiple
features, a single input record will result in many output records.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('type');
my ($type) = @ARGV;
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Get the features for each genome.
    my $resultsH = $helper->all_features([map { $_->[0] } @batch], $type);
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
