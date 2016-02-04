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

    svc_compare_regions.pl [ options ] pin genome1 genome2 ...

Display a side-by-side comparison of the functions in multiple regions.

The first region will be taken from the standard input and should be the output from L<svc_genes_in_region.pl>.
The pin parameter should be a feature or function ID that identifies a particular input line. A section from each
of the other genomes of roughly the same length will be found that contains the pinned function and as many of the
other input functions as possible, For best results, the pinned function should be roughly in the middle of the
first region. Once all the regions are identified, the functions in each will be displayed, aligned by the pinned
role. If the pinned role cannot be found, the corresponding column of the output will be blank. At the current
time, for each region, there will be three columns displayed: the feature ID, the function ID or description, and
the strand.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are the pinned function / feature ID and one or more genome IDs. The additional genome
IDs are displayed in comparison to the region in the standard input.

The input file is read as a whole and there is no meaningful correspondence between input and output rows.

=over 4

=item priv

Privilege level for functional assignments. The default is C<0>.

=item gFile

If specified, the list of genomes will be taken from the first column of the specified tab-delimited file
in addition to the command line.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('pin genome1 genome2 ...',
        ['priv=i', 'privilege level for functional assignments', { default => 0 }],
        ['gFile=s', 'name of a file containing genome IDs in the first column'],
        {input => 'file', batchSize => 0});
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the parameters.
my ($pin, @genomes) = @ARGV;
if (! $pin) {
    die "You must specify a pinned function or feature.";
}
if ($opt->gfile) {
    my $moreGenomes = ServicesUtils::get_column($opt->gfile, 1);
    push @genomes, @$moreGenomes;
}
# Read in the region data. We need to know the location spanned by the region, the list of [ID, func, dir]
# triples, and the index of the pinned feature.
my ($start0, $end0);
my @region0;
my ($pinIdx0, $pinFunc);
while (! eof $ih) {
    # Get the feature ID, location, and function ID.
    my ($fid, $start, $end, $dir, $funcID) = ServicesUtils::get_cols($ih, 1, 2, 3, 4, 6);
    # Merge in the location.
    $start0 //= $start;
    $end0 = $end;
    # Save the display tuple for this feature.
    push @region0, [$fid, $funcID, $dir];
    # Check for the pin. Note we only save the first match.
    if (($fid eq $pin || $funcID eq $pin) && ! defined $pinIdx0) {
        $pinIdx0 = $#region0;
        $pinFunc = $funcID;
    }
}
# Check for errors.
if (! defined $pinIdx0) {
    die "Pinned feature not found in input.";
}
# Compute the region length.
my $regionLen = $end0 - $start0;
# Get a list of the function IDs in the region.
my %funcs = map { $_->[1] => 1 } @region0;
my $funcList = [grep { $_ } keys %funcs];
# Now we loop through the genomes. Each genome's region will be added to these lists. The offset tells us
# how much to add to the index in each region in order to get the pinned roles to line up.
my @regions = (\@region0);
my @pinIdxes = ($pinIdx0);
my @offsets = (0);
my $maxOffset = 0;
for my $genome (@genomes) {
    # Ask for this genome's region.
    my ($similarRegion, $pinFid) = $helper->find_similar_region($genome, $regionLen, $pinFunc, $funcList, $opt->priv);
    if (! $similarRegion) {
        # No region found, push a blank.
        push @regions, [];
        push @pinIdxes, $pinIdx0;
        push @offsets, 0;
    } else {
        # Get the genes in the similar region.
        my $regionFeats = $helper->genes_in_region($similarRegion, $opt->priv);
        my @region = map { [$_->[0], $_->[2], $_->[1]->Dir] } @$regionFeats;
        my $pinIdx = 0;
        while ($region[$pinIdx][0] ne $pinFid) { $pinIdx++ }
        push @regions, \@region;
        push @pinIdxes, $pinIdx;
        my $offset = $pinIdx - $pinIdx0;
        push @offsets, $offset;
        if ($offset > $maxOffset) { $maxOffset = $offset }
    }
}
# Now start the output.
my $found = 1;
for (my $i = -$maxOffset; $found; $i++) {
    # This will hold the output columns.
    my @line;
    # This will count the number of nonempty columns. We stop when it is 0.
    $found = 0;
    for (my $col = 0; $col < @regions; $col++) {
        my $realI = $i + $offsets[$col];
        my $region = $regions[$col];
        if ($realI >= 0 && $realI < @$region) {
            my $tuple = $region->[$realI];
            push @line, @$tuple;
            $found++;
        } else {
            push @line, '', '', '';
        }
    }
    # Print the line.
    print join("\t", @line) . "\n";
}
