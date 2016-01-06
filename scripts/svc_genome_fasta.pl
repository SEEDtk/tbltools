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

=head1 Create Genome Fasta File

    svc_genome_fasta.pl [ options ] col1 col2 ...

Generate a FASTA file from incoming

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are 1-based column numbers indicating the input columns to be used for the comment
field in the output FASTA. These columns will be strung together with tabs.

The additional command-line options are as follows.

=over 4

=item dna

Generate a DNA FASTA file. This option is mutually exclusive with C<prot> and is the default.

=item prot

Generate a protein FASTA file. This option is mutually exclusive with C<dna>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('col1 col2 ...',
        ['mode' => hidden => { one_of => [ ['dna|n' => 'create DNA FASTA'], ['prot|p' => 'create protein FASTA'] ] }]
        );
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Compute the mode.
my $mode = $opt->mode // 'dna';
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Compute the FASTA triples for each genome ID.
    my $triplesH = $helper->genome_fasta([map { $_->[0] } @batch], $mode);
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value's triples.
        my ($value, $row) = @$couplet;
        my $triples = $triplesH->{$value};
        if ($triples) {
            # Create the comment.
            my $comment = '';
            for my $col (@ARGV) {
                $comment .= "\t" . $row->[$col - 1];
            }
            # Loop through the triples, producing FASTA output.
            for my $triple (@$triples) {
                print ">$triple->[0] $comment\n$triple->[2]\n";
            }
        }
    }
}
