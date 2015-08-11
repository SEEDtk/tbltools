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
=head1 Add Pegs to Table

Given a table with feature function ids as a column, remove unwanted ones. 

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> and
L<ScriptUtils/ih_options> plus the following.

-c N  The column containing feature

-p N  The privilege level for accessing the function

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
                        ['col|c=i', 'rowid column', { }],
                        ['privilegel|p=i', 'privilege level', { default => 2 }]
    );
my $ih = ScriptUtils::IH( $opt->input );
my $shrub = Shrub->new_for_script($opt);
my $column = $opt->col;

my %core = map { chomp; $_ => 1 } `all_genomes id -c "core=true"`;

while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    my @funcs = map { $_->[0] } @tuples;
    foreach my $tuple (@tuples) {
        my ($func, $line) = @$tuple;
        if (ok_role($func)) {
            print $line, "\n";
        }
    }
}

sub ok_role {
    my ($role) = shift;
    if ($role =~ /dehydrogenase|transport|regulat/i) {
        return(0);
    }
    return(1);
}
