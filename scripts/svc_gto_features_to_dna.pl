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
use GenomeTypeObject;

=head1 Extract DNA for Specific Features from JSON Object

    svc_gto_features_to_dna.pl [ options ] gtoFile

Extract DNA for features from a JSON kBase object. The JSON string must be a SEED-type L<GenomeTypeObject>,
since kBase GTOs do not contain DNA sequences.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited, with the feature ID in a specified column, defaulting to the last. The DNA
sequence will be added at the end. If the C<fasta> parameter is specified, the output will be in FASTA format,
with the feature ID as the sequence ID and the other columns as the comment.

The GTO file name must be specified as the positional parameter.

The other command-line options are as follows.

=over 4

=item fasta

If specified, the output will be in FASTA format.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('gtoFile',
        ["fasta", "produce output in FASTA format"],
        { nodb => 1 });
# Check for FASTA format.
my $fastaForm = $opt->fasta;
# Get the input column index.
my $col = $opt->col;
# Get the GTO.
my $gto;
my ($gtoFile) = @ARGV;
if (! $gtoFile) {
    die "No GTO file name specified.";
} elsif (! -f $gtoFile) {
    die "GTO file not found.";
} else {
    $gto = GenomeTypeObject->create_from_file($gtoFile);
}
# Loop through the input, retrieving the DNA.
my $ih = ServicesUtils::ih($opt);
while (! eof $ih) {
    my @tuples = ServicesUtils::get_batch($ih, $opt);
    for my $tuple (@tuples) {
        my ($fid, $row) = @$tuple;
        my $dna = $gto->get_feature_dna($fid);
        if ($dna) {
            # We found the feature's DNA. Write it out.
            if (! $fastaForm) {
                # Normal format.
                print join("\t", @$row, $dna) . "\n";
            } else {
                # FASTA form. We need to remove the ID column from the row to form the comment.
                if (! $col) {
                    pop @$row;
                } else {
                    splice @$row, ($col - 1), 1;
                }
                print ">$fid " . join("\t", @$row) . "\n$dna\n";
            }
        }
    }
}
