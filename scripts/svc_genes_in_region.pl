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
use GenomeTypeObject;
use GenesInRegion;

=head1 Genes in a Region

    svc_genes_in_region.pl [ options ] contig start end

This method displays the features found in a particular region on a contig. For each feature, we
display the feature ID, the endpoints, the direction and length, and the assigned function. The
goal is to give a picture of what is in the region.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The positional parameters are the contig ID and the start and end points of the region.

=over 4

=item gto

If specified, the name of a file containing a L<GenomeTypeObject> in JSON format. This object will
be used as the source genome.

=item missing

If specified, the name of a file output by L<svc_missing_roles.pl> containing proposed missing roles.
Any roles that overlap the specified region will be displayed as virtual pegs.

=item priv

The privilege level for functional assignments. The default is C<0>.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('contig start end',
        ['missing=s', 'if specified, a file of missing roles'],
        ['gto=s', 'if specified, a file containing a JSON genome-typed-object'],
        ['priv=i', 'privilege level for functional assignments', { default => 0 }],
        { input => 'none' });
# Get the contig range.
my ($contig, $start, $end) = @ARGV;
if (! $contig) {
    die "A contig ID is required.";
} elsif (! $start || $start !~ /^\d+$/) {
    die "Invalid or missing start location.";
} elsif (! $end || $end !~ /^\d+$/) {
    die "Invalid or missing end location.";
}
# Create the processing object.
my $gir = GenesInRegion->new($helper, $contig, $start, $end, $opt->priv);
# Are we reading from a genome-typed-object?
my $gto;
if ($opt->gto) {
    # Yes. Get the GTO from the file.
    $gto = GenomeTypeObject->create_from_file($opt->gto);
}
# Compute the genes in the region.
my $gList = $gir->Process(missing => $opt->missing, priv => $opt->priv, gto => $gto);
# Loop through the genes found, writing them out.
for my $gene (@$gList) {
    my ($fid, $loc, $funcID, $funcName) = @$gene;
    print join("\t", $fid, $loc->Left, $loc->Right, $loc->Dir, $loc->Length, $funcID, $funcName) . "\n";
}