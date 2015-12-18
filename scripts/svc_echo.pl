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

=head1 Echo Strings to Output

    svc_echo.pl [ options ] parm1 parm2 ...

This is a simple script that writes each positional parameter to the output as a single line. It is mostly
used for testing, and mostly in Windows.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are strings that are written to the output one per line.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('parm1 parm2 ...', { nodb => 1, input => 'none' });
# Loop through the parameters.
for my $arg (@ARGV) {
    print "$arg\n";
}