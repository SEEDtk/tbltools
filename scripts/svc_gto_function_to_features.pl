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

=head1 Extract Features from JSON Object by Function

    svc_gto_function_to_features.pl [ options ] function

Extract features from a JSON kBase object. In general, the JSON string will be a
genome type object (L<GenomeTypeObject>) or a workspace object containing a genome. We will look
for a member called C<features> either in the object itself or the object's C<data> member. Inside
this member we expect the feature ID in a member named C<id> and the feature's function in a member
named C<function>. This is consistent with the both current definitions of a genome-type object.

This script returns a two-column tab-delimited file of the features possessing the input function or
functions. The first column is the feature ID and the second is the function ID.

=head2 Parameters

The positional parameter is a function string, which must match exactly. (This is not a big problem if
the GTO comes from RAST.) More than one function can be specified using the C<funFile> command-line option.

See L<ServicesUtils> for more information about common command-line options.

The input file is a json string. The output file will be tab-delimited with two columns, the function and
the feature ID.

=over 4

=item funFile

If specified, the name of a tab-delimited file containing function strings in the last column. The
feature IDs will be added as the last column.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('function',
        ["funFile|f=s", "file containing function strings"],
        { nodb => 1, input => 'file' });
# Check for a function file.
my %functions;
my $funFileFound;
if ($opt->funfile) {
    open(my $ih, '<', $opt->funfile) || die "Could not open function file: $!";
    $funFileFound = 1;
    while (! eof $ih) {
        my @row = ServicesUtils::get_cols($ih, 'all');
        my $function = pop @row;
        $functions{$function} = [@row, $function];
    }
}
# Check for a positional-parme function.
my ($function) = @ARGV;
if (! $function) {
    die "No function or funFile specified." if ! $funFileFound;
} else {
    die "Command-line parameter invalid when funFile specified." if $funFileFound;
    $functions{$function} = [$function];
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
    # Is this a function we want?
    my $row = $functions{$function};
    if ($row) {
        # Yes. Print it.
        print join("\t", @$row, $id) . "\n";
    }
}
