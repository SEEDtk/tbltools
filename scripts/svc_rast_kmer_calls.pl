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
use gjoseqlib;
use Data::Dumper;
use LWP::UserAgent;
use JSON::XS;
use ServicesUtils;



=head1 Count Kmer Hits in a Set of Source Sequences

    svc_rast_kmer_calls.pl [ options ] < fasta file 

Make RAST Kmer calls.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options. The input column specifies the
sequences to be analyzed.

There are no parameters.

The input file is a fasta file. 

=head3 Output

The output of this command is a tab separated table. For each fasta entry, a line is written containing the FIGid, the function, #kmer hits and  the weighted hit count
=cut

my $service_url = 'http://tutorial.theseed.org/services/genome_annotation';
my $ua = LWP::UserAgent->new;


# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options();
#
# Construct minimal genome object.
#
my $flist = [];
my $genome_in = { features => $flist };

while (my($id, $def, $seq) = read_next_fasta_seq())
{
    push(@$flist, { id => $id, protein_translation => $seq, type => 'peg' });
}

#
# Perform JSONRPC call to the service.
#

my $req = {
    jsonrpc => '2.0',
    method => 'GenomeAnnotation.annotate_proteins_kmer_v2',
    params => [$genome_in, {}],
};

my $hres = $ua->post($service_url, Content => encode_json($req));

if (!$hres->is_success )
{
    die "Call failed: " . $hres->status_line . " " . $hres->content;
}

#
# Decode return
#
my $res = decode_json($hres->content);
my $genome_out = $res->{result}->[0];

#
# Process called features
#

for my $f (@{$genome_out->{features}})
{
    my $q = $f->{quality};
    print join("\t", $f->{id}, $f->{function}, $q->{hit_count}, $q->{weighted_hit_count}), "\n";
}
