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

=head1 Filter File

    svc_matching -f file-of-ids < streamtoFilter > matching
        keep selected lines

    svc_matching -v -f file-of-ids < streamtoFilter > non-matching


=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

=over 4

=item invert

invert the normal behaviour - keep lines that do not match

=item file

Name of the file containing the data to match

=item matchCol

Index of the column containing the data to match in the file specified by C<file>. The default is the last column.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',["file|f=s","file of match values", { required => 1 }],
                                                   ["invert|v","invert retention condition"],
                                                   ["matchCol|m=i", "column containing match values", { default => 0 }],
                                                   { nodb => 1 });
my $f = $opt->file;
my $v = $opt->invert;
my $m = $opt->matchcol;
my %to_match;
open(F,"<$f") || die "could not open $f";
while (defined(my $line = <F>))
{
    chomp $line;
    my @cols = split /\t/, $line;
    $to_match{$cols[$m-1]} = 1;
}
close(F);
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    # Output the batch.
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        if (((! $v) && $to_match{$value}) ||
            ($v && (! $to_match{$value})))
        {
            print join("\t", @$row), "\n";
        }
    }
}
