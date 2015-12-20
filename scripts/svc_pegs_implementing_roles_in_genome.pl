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

=head1 Get the PEGs Implementing Specific Roles in a Given Genome

    svc_pegs_implementing_roles_in_genome.pl [ options ] -g Genome

This takes as input a table with a column composed of role IDs and 
a parameter designating a genome.  I new column is added for PEGs in the
genome that implement the roles.  Note that a single role ID may lead to
no lines being added (if the genome has no PEGs implementing the role) or
multiple output lines (if there are multiple PEGs that implement the role.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

=over 4

=item -g GenomeID

The resulting PEGs will all be from the specified genome

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',["genome|g=s","genome ID"]);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
my $g = $opt->genome;

# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->pegs_implementing_roles_in_genome($g,[map { $_->[0] } @batch]);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($role, $row) = @$couplet;
        my $pegH = $resultsH->{$role};
        for my $peg (sort { &SeedUtils::by_fig_id($a,$b)}  keys(%$pegH))
	{
	    my $function = $pegH->{$peg};
            print join("\t", @$row, $function,$peg), "\n";
        }
    }
}
