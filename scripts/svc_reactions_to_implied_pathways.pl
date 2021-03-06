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

=head1 Find Active Pathways Base on Reactions Present

    svc_reactions_to_implied_pathways.pl [-f Frac] [ options ] < Reactions > Pathways

Compute the set of potentially active Pathways from the set of detected Reactions.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output Pathways are those for which
an active Complex appears to exist.  An active Complex will be presumed, if FracNeed
of the Reactions relating to the Complex have been identified.

=over 4

=item minF

This specifies the minimum fraction of the Reactions that connect to a Complex
that must be present for the Complex to be considered active.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', ['minF|m=f','minimum fraction of reactions needed to be an active complex',{ default => 0.5} ], {});

# Open the input file.
my $ih = ServicesUtils::ih($opt);
my $frac = $opt->minf;
my $reactions = ServicesUtils::get_column($ih, $opt->col);
my @pathways = $helper->reactions_to_implied_pathways($reactions,$frac);
foreach $_ (@pathways)
{
    print $_,"\n";
}

