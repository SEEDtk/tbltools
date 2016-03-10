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
use ClusterPairs;

=head1 Form Clusters From ID Pairs

    svc_cluster_pairs.pl [ options ] 

Read in a list of object ID pairs (connections) and form the transitive closure (clusters) of the connections.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input file is tab-delimited, and each line contains two object IDs. Any two object IDs on the same line are
considered to be in the same cluster. The output will list all the objects in a cluster on a single tab-delimited line.
Each line will consist of a count of the number of elements followed by the elements themselves.


=over 4

=item col1

The index (1-based) of the column containing the second object ID. A value of C<0> indicates the last column. The default
is C<1>.

=item col2

The index (1-based) of the column containing the second object ID. A value of C<0> indicates the last column. The default
is C<2>. If this value is the same as the C<col1> value, there will be no output.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ['col1|c=i', 'index of column containing first ID', { default => 1 }], 
        ['col2|d=i', 'index of column containing second ID', { default => 2 }],
        { input => 'file', nodb => 1 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Get the column IDs.
my ($col1, $col2) = ($opt->col1, $opt->col2);
# Create the clustering object.
my $clusterObj = ClusterPairs->new();
# Loop through it.
while (! eof $ih) {
    # Get the object IDs.
    my ($obj1, $obj2) = ServicesUtils::get_cols($ih, $col1, $col2);
    # Cluster them.
    $clusterObj->add_pair($obj1, $obj2);
}
# Now loop through the clusters, writing them out.
my $clusterList = $clusterObj->clusters();
for my $in (@$clusterList) {
    my $clusterL = $clusterObj->cluster($in);
    print join("\t", $clusterObj->cluster_len($in), @$clusterL) . "\n";
}
