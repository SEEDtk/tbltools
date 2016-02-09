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
=head1 Extract and Reorder Columns in a Table

Takes a table as input and extracts designated columns (in specified order).
For example,

    svc_extract -f 3,1 < input > extracted.output

creates a 2-column table built from columns 3 and 1 in the input table.

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> and
L<ScriptUtils/ih_options> plus the following.

-f ListOfColumns to extract (i.e., '1,2,3' would extract the first 3 columns)

=cut

use strict;
use warnings;
use Data::Dumper;
use Shrub;
use ScriptUtils;
use ScriptThing;

# Get the command-line parameters.
my $opt =
  ScriptUtils::Opts( '',
                     Shrub::script_options(), ScriptUtils::ih_options(),
                     ['fields|f=s', 'columns to extract', { required => 1 }],
    );
my $ih = ScriptUtils::IH( $opt->input );
my $columns = $opt->fields;

my @flds = split(/,/,$columns);
my @bad  = grep { $_ !~ /^\d+$/ } @flds;
if (@bad > 0)
{
    die "$columns is not a valid comma-separated list of columns";
}

while (defined($_ = <$ih>))
{
    chomp;
    my @in_fields   = split(/\t/,$_);
    my @out_fields;
    foreach my $x (@flds)
    {
	my $y = $in_fields[$x-1];
	if (! $y) { $y = '' }
	push(@out_fields,$y);
    }
    print join("\t",@out_fields),"\n";
}
