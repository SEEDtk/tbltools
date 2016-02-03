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
use SeedUtils;
use MissingRoles;

=head1 Missing-Role Analysis

    svc_missing_roles.pl [ options ] kmerdb genomeID name

This script computes the roles missing from a proposed genome based on close genomes in the Shrub.
The basic strategy is as follows:

=over 4

=item 1

Find the close genomes using kmer hits.

=item 2

Get all the roles in subsystems from the close genomes.

=item 3

Subtract from that set all the roles in subsystems from the proposed genomes.

=item 4

Blast the pegs for those roles from the close genomes against the contigs of the proposed genome.

=back

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The standard input should be a JSON file containing a L<GenomeTypeObject>. We will look for contig
sequences and feature assignments from this object.

The single required positional parameter is the name of a KMER database for the candidate close genomes. The
database should be protein kmers and should have been created by L<svc_kmerdb.pl>.

Optionally, you can include a genome ID and name as the second and third positional parameters. If not
provided, they will be inferred from the input.

The command-line options are as follows.

=over 4

=item annotations

Name of a JSON-format L<GenomeTypeObject> file containing the annotations. If omitted, the annotation are presumed
to be in the input file. If they are not, the contigs are called using RAST.

=item minHits

The minimum number of hits from the kmer database for a genome to be considered close. The default is
C<400>.

=item keep

The number of close genomes to keep. The default is C<10>.

=item maxE

The maximum permissible E-value from a BLAST hit. The default is C<1e-20>.

=item minLen

The minimum permissible percent length for a BLAST hit. The default is C<50>.

=item geneticCode

The genetic code to use for protein translations. The default is C<11>.

=item warn

If specified, log messages will be written to STDERR instead of the log file.

=item domain

Domain code for the organism-- C<B>, C<E>, or C<A>. The default is C<B>.

=item workDir

Working directory for intermediate files. The default is constructed from the genome ID under the
current directory, and will be created if it does not exist.

=item user

User name for calls to RAST (if needed). If no user name is specified, the environment variable C<RASTUSER>
will be interrogated.

=item password

Password for calls to RAST (if needed). If no password is specified, the environment variable C<RASTPASS>
will be interrogated.

=item fasta

If specified, then the input is assumed to be in FASTA format.

=back

=head2 Output

The standard output will be a tab-delimited file, each line representing a BLAST hit, with the following columns.

=over 4

=item 1

ID of a missing role.

=item 2

Description of the role

=item 3

Number of close genomes containing the role.

=item 4

BLAST score of the hit.

=item 5

Percent identity of the hit.

=item 6

Location string for the hit location in the proposed genome.

=item 7

Protein sequence from the BLAST hit.

=back

The following intermediate files are created.

=over 4

=item contigs.fasta

A FASTA file of the contigs from the incoming genome.

=item close.tbl

A tab-delimited file of the close genomes found. Contains the hit count, ID, and name of each close genome.

=item missing.roles.tbl

A tab-delimited file of the roles missing in the new genome. Contains the ID, hit count, and description of
each role.

=item genome.roles.tbl

A tab-delimited file of the roles in the new genome. Contains the ID and description.

=item blast.tbl

A tab-delimtied file containing the hsp-format output from the BLAST.

=item status.log

The progress log file.

=item genome.json

A JSON file containing a L<GenomeTypeObject> for the incoming genome. This is only produced if RAST is used
to call the features.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('kmerdb genomeID name',
        ["annotations|a=s", "name of the annotations GTO file (if annotations are separate)"],
        ["keep|N=i",        "number of close genomes to keep", {default => 10 }],
        ["minHits|m=i",     "minimum number of kmer hits for a close genome to be considered relevant", { default => 400 }],
        ["maxE|e=f",        "maximum permissible E-value for a BLAST hit", { default => 1e-20 }],
        ["minLen|l=i",      "minimum percent length for a BLAST hit", { default => 50 }],
        ["geneticCode=i",   "genetic code for protein translation", { default => 11 }],
        ["warn",            "if specified, log messages will be written to STDERR"],
        ["domain=s",        "domain of the incoming organism"],
        ["workDir|D=s",     "name of the working directory for intermediate files"],
        ["user|u=s",        "RAST user name (if needed for annotation"],
        ["password|p=s",    "RAST password (if needed for annotation)"],
        ["fasta",           "if specified, the standard input is assumed to be a FASTA file"],
        { input => 'file' });
# Get the kmer database and the other parameters.
my ($kmerFile, $genomeID, $genomeName) = @ARGV;
if (! $kmerFile) {
    die "No KMER database specified.";
} elsif (! -s $kmerFile) {
    die "Kmer file $kmerFile not found or empty.";
}
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read the incoming genome.
my $genomeJson;
if ($opt->fasta) {
    my $contigTriples = gjoseqlib::read_fasta($ih);
    $genomeJson = { contigs => [ map { {id => $_->[0], dna => $_->[2]} } @$contigTriples ],
        id => ($genomeID // '6666666.66'), scientific_name => ($genomeName // 'Unknown sp.') };
} else {
    $genomeJson = SeedUtils::read_encoded_object($ih);
    if ($genomeID) {
        $genomeJson->{id} = $genomeID;
    }
    if ($genomeName) {
        $genomeJson->{scientific_name} = $genomeName;
    }
}
my $annotationJson;
if ($opt->annotations) {
    # Here we have annotations in a separate object.
    $annotationJson = SeedUtils::read_encoded_object($opt->annotations);
}
# Create the missing-roles object.
my $mr = MissingRoles->new($genomeJson, $annotationJson, $helper, $opt->workdir, minHits => $opt->minhits,
        keep => $opt->keep, maxE => $opt->maxe, minLen => $opt->minlen, geneticCode => $opt->geneticcode,
        'warn' => $opt->warn, domain => $opt->domain, user => $opt->user, password => $opt->password);
# Process the contigs against the kmers.
my $roles = $mr->Process($kmerFile);
for my $role (@$roles) {
    print join("\t", @$role) . "\n";
}
