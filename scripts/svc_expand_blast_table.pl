#!/usr/bin/env perl
#
#copyright (c) 2003-2006 University of Chicago and Fellowship
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
use Data::Dumper;

=head1 Expand a blast output into a more readable table
    svc_expand_blast_table [options] < blast output

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input is a tab-delimited file in standard blast -m8 format. 
=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
         ["priv|p", "assignment privilege level", { default => 0 }],
         ["verbose|v", "return descriptions instead of IDs"]);

# Open the input file.
my $ih = ServicesUtils::ih($opt);


 
while (defined($_ = <$ih>))
{
        chop;
        my ($id1,$id2,$iden,undef,undef,undef,$b1,$e1,$b2,$e2,$psc) = split(/\t/,$_);
        my $resultsH = $helper->function_of([$id1], $opt->priv, $opt->verbose);
        my $func = $resultsH->{$id1};
        print join("\t",($id1,$id2,$psc,$iden,$b1,$e1,$b2,$e2,$func)),"\n";
}

