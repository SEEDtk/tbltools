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
=head1 Get roles of a subsystem

Given a table with role name, add a new column
containing subsystems

=head2 Parameters

The command-line options are those found in L<Shrub/script_options> and
L<ScriptUtils/ih_options> plus the following.

-c N  The column containing feature

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
                        ['limit|l=i', 'limit output pegs in a row', {}],
                        ['col|c=i', 'rowid column', { }],
    );
my $ih = ScriptUtils::IH( $opt->input );
my $shrub = Shrub->new_for_script($opt);
my $column = $opt->col;
my $limit = $opt->limit;

while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    foreach my $tuple (@tuples) {
        my ($role, $line) = @$tuple;
        my $filter = 'Role(description) = ?';
        my @normal = Shrub::Roles::Parse($role);
        my $r = $normal[0];
        my @parms = ($r);
        my $data = [$shrub->GetFlat('Role Role2Function Function2Feature Feature', $filter, \@parms, 'Feature(id)')];
        my @result = @$data[0..($limit-1)];
        print $line,"\t",join(",",@result),"\n";
    }
}

