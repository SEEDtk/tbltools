#!/usr/bin/env perl
##
## Copyright (c) 2003-2015 University of Chicago and Fellowship
## for Interpretations of Genomes. All Rights Reserved.
##
## This file is part of the SEED Toolkit.
##
## The SEED Toolkit is free software. You can redistribute
## it and/or modify it under the terms of the SEED Toolkit
## Public License.
##
## You should have received a copy of the SEED Toolkit Public License
## along with this program; if not write to the University of Chicago
## at info@ci.uchicago.edu or the Fellowship for Interpretation of
## Genomes at veronika@thefig.info or download a copy from
## http://www.theseed.org/LICENSE.TXT.
##


use strict;
use warnings;
use ServicesUtils;
use SeedUtils;
use Data::Dumper;
use Carp;

=head1 Return or remove Hypothetical features/roles

    svc_is_hypo [-c N] [-v]

Keep or remove just hypotheticals


Versions of this command once took a stream of feature IDs (PEGs) as input. 
This version takes values of functions and lets through those
that are hypothetical.  Use the -v parameter if you wish only
the functions that are not hypothetical.

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG .  If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -v [keep only non-hypotheticals]

=back

=head2 Output Format

This is a filter producing a subset of the input lines.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', 
    ["keep|v", "keep only non-hypotheticals"],
    { nodb => 1 });

# Get the v option
my $v = $opt->keep;
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Loop through it.
while (my @batch = ServicesUtils::get_batch($ih, $opt)) {
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value, $row) = @$couplet;
        # Check for a result.
        my $is_hypo = &SeedUtils::hypo($value);

        if ($v && !$is_hypo) {
            # We have non-hypo  and want non-hypo, so output this result with the original row.
            print join("\t", @$row), "\n";
        } elsif(!$v && $is_hypo) {
        #We have hypo and want hypo's 
            print join("\t", @$row), "\n";
        }

    }
}
