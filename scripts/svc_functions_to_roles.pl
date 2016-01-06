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

=head1 Convert Functions to Roles

    svc_functions_to_roles.pl [ options ]

Parse the roles out from functional assignments. In a SEEDtk environment, this will extract role IDs
from function IDs and role descriptions from function descriptions. Use L<svc_desc_to_role.pl> to
convert role descriptions to IDs.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited. The output fields will be appended to the end of each input row.
Since a functional assignment can have multiple roles, the output file could contain more lines than
the input file.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', { nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Process the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Separate the roles from the function.
        my @results = SeedUtils::roles_of_function($value);
        # Loop through the input value's results;
        for my $result (@results) {
            # Output this result with the original row.
            print join("\t", @$row, $result), "\n";
        }
    }
}