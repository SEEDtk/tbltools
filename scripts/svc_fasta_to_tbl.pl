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
use gjoseqlib;

=head1 Convert FASTA to Tab-Delimited File

    svc_fasta_to_tbl.pl [ options ] 

This script converts a FASTA file to a tab-delimited file of three columns-- id, comment, and sequence.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input is a FASTA file. The output file is tab-delimited, and is simply a reformatting of the input.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', { input => 'file', nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read the FASTA into memory.
my $triples = gjoseqlib::read_fasta($ih);
# Loop through them.
for my $triple (@$triples) {
    my ($id, $comment, $seq) = @$triple;
    print "$id\t$comment\t$seq\n";
}
