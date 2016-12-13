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

=head1 Filter Genomes by Domain

This is used to filter a column of genome ids or a column
of feature IDs, keeping only those in a given domain.

Thus,

    svc_all_genomes | svc_is_domain -B

would give you just the Bacterial genomes.

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> (database connection) and
L<ScriptUtils/ih_options> (standard input) plus the following. Note that the options specifying the
domain are mutually exclusive-- you can only specify one.

=over 4

=item invert

Keep only genomes/features not in the specified domain.  That is, this reverses the
retention condition.

=item eukaryota

Keep eukaryotic genomes.

=item bacteria

Keep bacterial genomes.

=item archaea

Keep archaeal genomes.

=item virus

Keep viral genomes.

=back

=cut


# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',["invert|v","invert retention condition"],
        ["domain", "hidden", { one_of => [
            ["eukaryota|E", "keep eukaryotic genomes"],
            ["bacteria|B", "keep bacterial genomes"],
            ["archaea|A", "keep archael genomes"],
            ["virus|V", "keep viral genomes"]
            ]}]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
my $v = $opt->invert;
my $dom = ucfirst $opt->domain;
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $csH = $helper->is_domain($v,$dom, [map { $_->[0] } @batch]);
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
