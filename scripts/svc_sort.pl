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
=head1 Sort rows in a table

Takes a table as input and writes a sorted version.  Sorting is
based on specified columns, which are allowed to contain
numeric values, fid ids, and locations.

    svc_sort -c 1,fid -c 2 < input > sorted.file

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> and
L<ScriptUtils/ih_options> plus the following.

-c ColSpec  Examples:  -c 1             Sort on column 1 (first column) assuming numeric values
                       -c 1,fid         Sort on column 1, assuming feature ids

                       -c 2,n -c 3,fid  Sort on column 2 (numeric) and column 3 (fids)

-u (keep only unique lines)

=cut

use strict;
use warnings;
use Data::Dumper;
use Shrub;
use ScriptUtils;
use ScriptThing;
use SeedUtils;

# Get the command-line parameters.
my $opt =
  ScriptUtils::Opts( '',
                     Shrub::script_options(), ScriptUtils::ih_options(),
                     ['columns|c=s@', 'columns to sort on', { required => 1 }],
                     ['reverse|r', 'reverse order', {}],
                     ['unique|u', 'keep unique', {}]
    );

my $unique = $opt->unique;
my $ih = ScriptUtils::IH( $opt->input );
my $x = $opt->columns;
my @columns = map { ($_ =~ /^(\d+)(,(\S+){0,1})?$/) ? [$1,$3] : () } @$x;
my $reverse = $opt->reverse;
my @file   = map { chomp; [split(/\t/,$_)] } <$ih>;
my @sorted = sort { &compare($a,$b,\@columns) } @file;
if ($reverse) { @sorted = reverse @sorted }

my $last = '';
foreach $_ (@sorted)
{
    $_ = join("\t",@$_) . "\n";
    if ((! $unique) || ($last ne $_))
    {
        print $_;
        $last = $_;
    }
}

sub compare {
    my($a,$b,$specs) = @_;

    my $val = 0;
    my $i = 0;
    while ((! $val) && ($i < @$specs))
    {
        my ($col,$type) = @{$specs->[$i]};
        if (! $type)             { $type = '' }
        if ($type eq "n")        { $val =  $a->[$col-1] <=> $b->[$col-1] }
        elsif ($type eq "fid")   { $val =  &SeedUtils::by_fig_id($a->[$col-1],$b->[$col-1]) }
        else                     { $val =  $a->[$col-1] cmp $b->[$col-1] }
        $i++;
    }
    return $val;
}
