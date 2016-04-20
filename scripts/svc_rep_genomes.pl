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

    svc_rep_genomes.pl [ options ] 

This script finds representative genomes that are spread out in the taxonomy tree. The input file
contains a list of scientific names followed by counts. The number of genomes specified will be
more-or-less randomly selected from underneath the taxonomy node with the specified name. The name
can be a taxonomy ID or an actual primary scientific name. At this time, aliases are not supported.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The additional command-line options are as follows.

=over 4

=item skip

The ID of a taxonomic group that should be skipped. Multiple values can be specified.

=back

The input file is tab-delimited. The first column should contain a taxonomy ID or name, the second column
should contain a number of genomes desired. The output file will contain genome names followed by genome IDs.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ['skip=s@', 'taxonomic grouping to skip'], { input => 'file' });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# We will put the requests in here.
my @requests;
# Loop through it.
while (! eof $ih) {
    # Get the taxonomy specification from the next input record.
    my ($taxon, $count) = ServicesUtils::get_cols($ih, 1, 2);
    push @requests, [$taxon, $count];
}
# Compute the blacklist.
my $blackList = $opt->skip // [];
# Get the genomes requested.
my $genomes = $helper->rep_genomes(\@requests, $blackList);
# Output the genomes.
for my $genome (@$genomes) {
    print join("\t", @$genome) . "\n";
}

