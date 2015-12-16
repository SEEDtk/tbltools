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

=head1 Describe Script Here

    svc_all_genomes.pl [ options ]

Return all the genomes for the database.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

There are no special options or parameters.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', { input => 'none' });
# Get the genome list.
my $genomeList = $helper->all_genomes();
# Write it out.
for my $genomeData (@$genomeList) {
    print join("\t", @$genomeData), "\n";
}
