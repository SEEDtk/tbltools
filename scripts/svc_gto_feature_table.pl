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
use GenomeTypeObject;
use BasicLocation;

=head1 Generate Feature Table for GTO

    svc_gto_feature_table.pl [ options ] 

This script outputs a tab-delimited feature table from a JSON-format L<GenomeTypeObject>. Each row of the
output file will contain (0) a feature ID, (1) the feature type, (2) the ID of the contig containing the feature, 
(3) the leftmost location of the feature on the contig, (4) the feature's location string, (5) the feature's functional 
assignment, and (6) the feature's protein sequence (if any).

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', { input => 'file', nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read in the GTO.
my $gto = GenomeTypeObject->create_from_file($ih);
# Get the list of features.
my $features = $gto->features;
# Loop through the features, producing the output.
for my $feature (@$features) {
    # Get the basic fields.
    my $fid = $feature->{id};
    my $type = $feature->{type};
    my $function = $feature->{function};
    my $translation = $feature->{protein_translation} // '';
    # Get the location information.
    my @locs = map { BasicLocation->new($_) } @{$feature->{location}};
    my $leftMost = $locs[0];
    for (my $i = 1; $i < @locs; $i++) {
        if ($locs[$i]->Left < $leftMost->Left) {
            $leftMost = $locs[$i];
        }
    }
    # Extract the contig and left offset for the leftmost location.
    my $contig = $leftMost->Contig;
    my $left = $leftMost->Left;
    # Compute the location string.
    my $loc = join(",", map { $_->String } @locs);
    # Write the feature.
    print join("\t", $fid, $type, $contig, $left, $loc, $function, $translation) . "\n";
}
