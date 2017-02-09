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

=head1 Extract Assignments from JSON Object

    svc_gto_to_features.pl [ options ]

Extract features and their functions from a JSON kBase object. In general, the JSON string will be a
genome type object (L<GenomeTypeObject>) or a workspace object containing a genome. We will look
for a member called C<features> either in the object itself or the object's C<data> member. Inside
this member we expect the feature ID in a member named C<id> and the feature's function in a member
named C<function>. This is consistent with the both current definitions of a genome-type object.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is a json string. The output file will be tab-delimited with two columns-- (0) feature ID
and (1) function of the feature.

=over 4

=item label

If specified, a label that will be added as the first column of every line.

=item type

If specified, must be a feature type. Only features of that type will be output. A value of C<peg> will get type <CDS> or type
C<peg>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ["label|l=s", "label to add in the first column"],
        ["type|t=s", "feature type to which output should be restricted"],
        { nodb => 1, input => 'file' });
# Get the label.
my @row;
if ($opt->label) {
    push @row, $opt->label;
}
# Get the feature type.
my $type = $opt->type;
my %types;
if ($type) {
    $types{$type} = 1;
    if ($type eq 'peg') {
        $types{CDS} = 1;
    }
}
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read in the json object.
my $object = SeedUtils::read_encoded_object($ih);
# Is this a workspace object? if so, get down to the real data.
if (ref $object->{data} eq 'HASH') {
    $object = $object->{data};
}
# Get the features.
my $fidList = $object->{features};
for my $fid (@$fidList) {
    # Get the ID and function.
    my $id = $fid->{id};
    my $function = $fid->{function};
    # Check the type.
    if (! $type || $types{$fid->{type}}) {
        # Print the feature.
        print join("\t", @row, $id, $function) . "\n";
    }
}
