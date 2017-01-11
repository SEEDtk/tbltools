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

=head1 Common Services Function

    svc_cat.pl [ options ] file1 file2 ... fileN

Concatenate sequential files. This script works like C<cat> but fixes missing EOL characters on the
last line.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options. Standard input should not
be specified.

The positional parameters are the names of the files to concatenate.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('file1 file2 ... fileN',
        { input => 'none', nodb => 1 });
# Get the names of the files.
my @files = @ARGV;
# Prime the main loop.
my $done = 0;
my ($ih, $line);
# Loop through the input.
while (! $done) {
    if (defined $ih) {
        $line = <$ih>;
        # Check for end-of-file.
        if (! defined $line) {
            # Yes. Request the next file.
            undef $ih;
        } else {
            # We have a line. Print it.
            $line =~ s/[\r\n]+$//;
            print "$line\n";
        }
    } elsif (! scalar(@files)) {
        # No more files. We are done.
        $done = 1;
    } else {
        # Get the next file.
        my $file = shift @files;
        open($ih, '<', $file) || die "Could not open $file: $!";
    }
}