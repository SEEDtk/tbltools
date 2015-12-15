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
use FIG_Config;
use Shrub;
use ScriptUtils;
use Data::Dumper;

=head1 Prototype SEEDtk Pipeline Script

    Proto [ options ] parm1 parm2 ...

This is a prototype template for a database script.

=head2 Parameters

## describe positional parameters

The command-line options are those found in L<Shrub/script_options> (database connection) and
L<ScriptUtils/ih_options> (standard input) plus the following.

=over 4

=item col

The column from the standard input from which the query sequence feature IDs is to be taken. The default is the last
column.

## more command-line options

=back

=cut

# Get the command-line parameters.
my $opt = ScriptUtils::Opts('parm1 parm2 ...', Shrub::script_options(),
        ScriptUtils::ih_options(),
        ['col|c=i', 'if specified, index (1-based) of input column containing feature IDs'],
        ## more command-line options
        );
# Connect to the database.
my $shrub = Shrub->new_for_script($opt);
# Open the input file.
my $ih = ScriptUtils::IH($opt->input);
# Extract the input column. Each input row will be converted into a 2-tuple
# containing [$inputCol, \@wholeRow).
my @couplets = ScriptUtils::get_couplets($ih, $opt->col);
# Loop through the couplets.
for my $couplet (@couplets) {
    my ($inputCol, $row) = @$couplet;
    my @output; ##TODO compute output
    # If we have a result, write it out.
    if (@output) {
        print join("\t", @$row, @output) . "\n";
    }
}
