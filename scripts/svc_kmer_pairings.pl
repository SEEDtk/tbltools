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
use KmerDb;

=head1 Find Groups Sharing Kmers

    svc_kmer_pairings.pl [ options ]

Examine a kmer database and output the groups that have kmers in common. For any groups A and B that
have common kmers, the application will output the two group IDs and the number of common kmers.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is a json-format kmer database, such as is produced by L<svc_kmer_db.pl>. The output
file is tab-delimited with three columns, as described above.

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('', { input => 'file', nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read in the kmer database.
my $kmerdb = KmerDb->new(json => $ih);
# We will track our group pairs in here.
my %pairs;
# Get the kmer list.
my $kmerList = $kmerdb->kmer_list();
# Loop through it.
for my $kmer (@$kmerList) {
    # Get the groups.
    my $groups = $kmerdb->groups_of($kmer);
    # Count them.
    for my $groupA (@$groups) {
        for my $groupB (@$groups) {
            # To insure we get each pair once, only keep a pair if A is lexically lower than B.
            if ($groupA lt $groupB) {
                $pairs{"$groupA\t$groupB"}++;
            }
        }
    }
}
# Output the pairs.
for my $pair (sort keys %pairs) {
    print "$pair\t$pairs{$pair}\n";
}
