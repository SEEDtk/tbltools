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

=head1 Create a GenomeTypeObject

    svc_gto.pl [ options ] genomeID

This script outputs a L<GenomeTypeObject> in JSON format for a specified genome.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

There is no input file. The single positional parameter is a genome ID. The output is a JSON-form
L<GenomeTypeObject> for the identified genome.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('genomeID');
# Get the genome ID.
my ($genomeID) = @ARGV;
if (! $genomeID) {
    die 'A genome ID is required.';
} else {
    my $gto = $helper->gto_of($genomeID);
    if (! $gto) {
        die "Genome $genomeID not found.";
    } else {
        $gto->destroy_to_file(\*STDOUT);
    }
}