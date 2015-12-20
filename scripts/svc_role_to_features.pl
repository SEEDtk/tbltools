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

=head1 Find All Features for a Role

    svc_role_to_features.pl [ options ]

Locate all of the features possessing a specific role.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input must be tab-delimited and contain role IDs in one column. The IDs of the features will
be added to the end of each input row. Since each role is associated with many features, there will be many
more output lines than input lines.

=over 4

=item priv

The privilege level of the assignment. The default is C<0>. This option has no meaning outside of SEEDtk.

=item genomes

If specified, a comma-delimited list of genome IDs or the name of a file containing genome IDs in the
first column. Only roles in the specified genomes will be returned.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('parm1 parm2 ...',
        ["priv|p", "assignment privilege level", { default => 0 }],
        ["genomes|g=s", "list of genomes to restrict results"]
);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Check for genomes.
my $genomesList;
my $genomesParm = $opt->genomes;
if ($genomesParm) {
    # Do we have a comma-delimited list or a file name?
    if (-f $genomesParm) {
        # Here we have a file name.
        $genomesList = [ SeedUtils::read_ids($genomesParm) ];
    } else {
        # Not a file name, so treat it as a comma-delimited list.
        $genomesList = [split /\s*,\s*/, $genomesParm];
    }
}
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH = $helper->role_to_features([map { $_->[0] } @batch], $opt->priv, $genomesList);
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
