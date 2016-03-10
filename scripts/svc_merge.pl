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

=head1 Add Data from a KeyFile to the Input File

    svc_merge.pl [ options ] keyfile

In this script, the key file is read into memory, and then for each record in the input file whose input column
value matches a key value in the key file, the key file's record (less the key column) is appended to the input 
line. So, for example, if the key file contained IDs and sequences and the input file contained IDs, the output
would be IDs and the matching sequences.

This is slightly different than what L<svc_matching.pl> does, since the output file contains data from both
input files.  

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameter is the name of the key file.

In addition to the common command-line options, the following are supported.

=over 4

=item key

Index (1-based) of the column in the key file containing the ID. The default is C<1>. This parameter does
not support the use of C<0> to indicate the last column.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('keyfile',
        ["key|k=i", 'index (1-based) of key column in key file', { default => 1 }],
        { nodb => 1 });
# This will contain the key file data.
my %keyData;
# Read the key file.
my ($keyFile) = @ARGV;
if (! $keyFile) {
    die "No key file specified."
} elsif (! -f $keyFile) {
    die "Key file $keyFile not found."
} else {
    my $keyCol = $opt->key - 1;
    open(my $kh, "<$keyFile") || die "Could not open key file: $!";
    while (! eof $kh) {
        my @cols = ServicesUtils::get_cols($kh, 'all');
        my (@data, $id);
        for (my $i = 0; $i < @cols; $i++) {
            if ($i == $keyCol) {
                $id = $cols[$i];
            } else {
                push @data, $cols[$i];
            }
        }
        $keyData{$id} = \@data;
    }
}
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Try to match the input value.
        my $data = $keyData{$value};
        if ($data) {
            # We found it. Output the line.
            print join("\t", @$row, @$data) . "\n";
        }
    }
}