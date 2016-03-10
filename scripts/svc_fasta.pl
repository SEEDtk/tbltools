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

=head1 Generate Feature FASTA File

    svc_fasta.pl [ options ] col1 col2 ...

Generate a FASTA file from incoming feature IDs. Normally, the sequence data is read from the database, but
the C<seq> option can be used to specify reading the sequence from the input.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are 1-based column numbers indicating the input columns to be used for the comment
field in the output FASTA. These columns will be strung together with tabs.

The additional command-line options are as follows.

=over 4

=item dna

Generate a DNA FASTA file. This option is mutually exclusive with C<prot>.

=item prot

Generate a protein FASTA file. This option is mutually exclusive with C<dna> and is the default.

=item seq

If specified, the sequence is taken from a column of the input rather than being looked up from the database.
The specified column index is 1-based. If this parameter is specified, the mode parameters (C<dna> and C<prot>)
are ignored.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('col1 col2 ...',
        ['mode' => hidden => { one_of => [ ['dna|n' => 'create DNA FASTA'], ['prot|p' => 'create protein FASTA'] ] }],
        ['seq|s=i', 'column containing the sequence to use'],
        );
# Compute the mode.
my $mode = $opt->mode // 'prot';
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    my $resultsH;
    my $batch = [map { $_->[0] } @batch];
    if ($opt->seq) {
        $resultsH = { map { $_->[0] => $_->[1][$opt->seq - 1] } @batch };
    } elsif ($mode eq 'dna') {
        $resultsH = $helper->dna_fasta($batch);
    } else {
        $resultsH = $helper->translation($batch);
    }
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Get the input value's sequence.
        my $sequence = $resultsH->{$value};
        if ($sequence) {
            # Create the comment.
            my @comment;
            for my $col (@ARGV) {
                push @comment, $row->[$col - 1];
            }
            # Write it out in FASTA format.
            my $comment = join("\t", @comment);
            print ">$value $comment\n$sequence\n";
        }
    }
}
