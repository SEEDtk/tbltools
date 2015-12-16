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

=head1 svr_is_CS is used to filter out non-coreSEED genomes or features

This is used to filter a column of genome ids or a column
of feature IDs, keeping only those for CoreSEED genomes.

Thus,

    all_genomes.sh | scr_is_CS

would give you just the coreSEED genomes.

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> (database connection) and
L<ScriptUtils/ih_options> (standard input) plus the following.

=over 4

=item col

The column from the standard input from which the query sequence feature IDs is to be taken. The default is the last
column.

=item batch

Number of records to process in each batch. The default is C<1000>. A value of C<0> will process the entire input
stream as a single chunk. Smaller batches reduce performance but increase the possibility of parallelism in pipelines.

=back

=cut

# Get the command-line parameters.
my $opt = ScriptUtils::Opts('', Shrub::script_options(),
        ScriptUtils::ih_options(),
        ['col|c=i',   'if specified, index (1-based) of input column containing feature IDs'],
        ['batch|b=i', 'number of records to process at a time (0 for all)', { default => 1000 }]
        );
# Connect to the database.
my $shrub = Shrub->new_for_script($opt);
my $cs_genomesH = $shrub->all_genomes("core");
# Open the input file.
my $ih = ScriptUtils::IH($opt->input);
# Extract the input column. Each input row will be converted into a 2-tuple
# containing [$inputCol, \@wholeRow). We will get the input in batches. An
# empty batch means end-of-file.
while (my @couplets = ScriptUtils::get_couplets($ih, $opt->col, $opt->batch)) {
    # Loop through the couplets in each batch.
    for my $couplet (@couplets) {
        my ($inputCol, $row) = @$couplet;
        if ($inputCol =~ /^(\d+\.\d+)$/ || $inputCol =~ /^fig\|(\d+\.\d+)/) {
            if ($cs_genomesH->{$1}) {
                print join("\t",@$row),"\n";
            }
        }
    }
}
