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

=head1 Find Active Reactions Base on Roles Present

    svc_roles_to_implied_reactions.pl [-f Frac] [ options ] < Roles > Reactions

Compute the set of potentially active Reactions from the set of detected Roles.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output Reactions are those for which
an active Complex appears to exist.  An active Complex will be presumed, if FracNeed
of the Roles relating to the Complex have been identified.

=over

=item -m FracNeeded

This specifies the minimum fraction of the Roles that connect to a Complex
that must be present for the Complex to be considered active.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', ['minF|m=f','minimum fraction of roles needed to be an active complex',{ default => 0.5} ], {});

# Open the input file.
my $ih = ServicesUtils::ih($opt);
my $frac = $opt->minf;
my $roles = ServicesUtils::get_column($ih, $opt->col);
my @reactions = $helper->roles_to_implied_reactions($roles,$frac);
foreach $_ (@reactions)
{
    print $_,"\n";
}

