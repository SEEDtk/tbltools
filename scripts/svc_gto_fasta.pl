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
use Contigs;

=head1 Produce a FASTA File for a GTO

    svc_gto_fasta.pl [ options ] 

This script takes as input a L<GenomeTypeObject> in JSON format and outputs a FASTA file for its contigs. Note
that the GTO B<must> be a SEED-format GTO. Many other scripts are flexible and allow kBase-format GTOs as well;
however, the DNA sequences are not in the kBase-format GTOs, so that is pointless here.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options. The additional command-line
options are

=over 4

=item lenFilter

Minimum length for a contig to be output. This is used to reduce the contig count so the job is more likely
to fit into RAST.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', 
        ['lenFilter|l=i', 'minimum acceptable length for an output contig', { default => 0 }], 
        { nodb => 1, input => 'file' });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read in the GTO.
my $gto = GenomeTypeObject->create_from_file($ih);
# Get the genome ID.
my $genome = $gto->{genome_id};
# Get the  minimum length.
my $minLen = $opt->lenfilter;
# Extract the contigs.
my $contigO = Contigs->new($gto, genomeID => $genome);
# Write them in FASTA format.
my @tuples = $contigO->tuples;
for my $tuple (@tuples) {
    my ($id, $comment, $seq) = @$tuple;
    if (length($seq) >= $minLen) {
        print ">$id $comment\n$seq\n";
    }
}
