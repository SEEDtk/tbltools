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

=head1 Select Sequences from a FASTA File

    svc_pull_fasta_entries.pl [ options ] fastaFile

This script will accept as input a list of IDs and will output all the entries in a FASTA file that have those IDs.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameter is the name of the FASTA file from which sequences are to be extracted.

=over 4

=item reverse

If specified, the sequences NOT in the input will be output.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('fastaFile',
        ['reverse|invert|v', 'output sequences not in input'],
        { nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the options.
my $reverse = $opt->reverse;
# Read in the sequence IDs.
my %idList;
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    for my $tuple (@batch) {
        $idList{$tuple->[0]} = 1;
    }
}
close $ih;
# Now read through the FASTA file.
my ($fastaFile) = @ARGV;
open(my $fh, "<$fastaFile") || die "Could not open FASTA file: $!";
my $output;
while (! eof $fh) {
    my $line = <$fh>;
    if ($line =~ /^>(\S+)/) {
        my $id = $1;
        if ($reverse xor $idList{$id}) {
            $output = 1;
        } else {
            $output = 0;
        }
    }
    if ($output) {
        print $line;
    }
}
