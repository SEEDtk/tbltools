#!/usr/bin/perl -w
#
## Copyright (c) 2003-2015 University of Chicago and Fellowship
## for Interpretations of Genomes. All Rights Reserved.
##
## This file is part of the SEED Toolkit.
##
## The SEED Toolkit is free software. You can redistribute
## it and/or modify it under the terms of the SEED Toolkit
## Public License.
##
## You should have received a copy of the SEED Toolkit Public License
## along with this program; if not write to the University of Chicago
## at info@ci.uchicago.edu or the Fellowship for Interpretation of
## Genomes at veronika@thefig.info or download a copy from
## http://www.theseed.org/LICENSE.TXT.
##
#
#
#
#	This is a SAS Component.
#

=head1 Write translations to a table, or write a fasta file

    tbl_fasta <gene_ids.tbl >sequences.tbl

Produce DNA or protein strings for genes.

This script takes as input a tab-delimited file with gene IDs at the end of
each line. For each gene ID, the gene's DNA or protein sequence is written to
the output file. If the C<--fasta> option is specified, the sequence is written
in FASTA format.

This is a pipe command: the input is taken from the standard input and the
output to the standard output. The columns of data preceding the first will be
supplied as comments to each FASTA string. In addition, if the incoming ID is
not a FIG ID, the output gene's FIG ID will be prefixed to the comment.

Note that because some gene IDs correspond to multiple genes, there may be
more output items than input lines.

=head2 Parameters
The command-line options are those found in L<Shrub/script_options> and
L<ScriptUtils/ih_options> plus the following.

-c N  The column containing feature


=over 4

=item source

Database source of the IDs specified-- C<SEED> for FIG IDs, C<GENE> for standard
gene identifiers, or C<LocusTag> for locus tags. In addition, you may specify
C<RefSeq>, C<CMR>, C<NCBI>, C<Trembl>, or C<UniProt> for IDs from those databases.
Use C<mixed> to allow mixed ID types (though this may cause problems when the same
ID has different meanings in different databases). Use C<prefixed> to allow IDs with
prefixing indicating the ID type (e.g. C<uni|P00934> for a UniProt ID, C<gi|135813> for
an NCBI identifier, and so forth). The default is C<SEED>.

=item protein

If specified, the output FASTA sequences will be protein sequences; otherwise,
they will be DNA sequences. The default is FALSE.

=item fasta

If specified, the output sequences will be FASTA format, otherwise just simple character strings.
The default is FALSE. In this case the output file will look the same as the
input file but with DNA/protein sequences tacked onto the end of each line.

=item c

Column index. If specified, indicates that the input IDs should be taken from the
indicated column instead of the last column. The first column is column 1.

=back

=cut

use strict;
use warnings;
use Data::Dumper;
use Shrub;
use ScriptUtils;
use ScriptThing;
use SeedUtils;

# Get the command-line parameters.
my $opt =
  ScriptUtils::Opts( '',
                       Shrub::script_options(), ScriptUtils::ih_options(),
                           ['col|c=i', 'rowid column', { }],
                           ['protein|p', 'Protein', {}],
                           ['fasta|f', "FASTA", {},],
                           ['source|s=s', "Source of the given id's", {default => 'SEED'}]
                        );

  my $ih = ScriptUtils::IH( $opt->input );
  my $shrub = Shrub->new_for_script($opt);
  my $column = $opt->col;

my $genomeH = $shrub->all_genomes();
my $protein = $opt->protein;
my $fasta = $opt->fasta;
my $source = $opt->source;
    # The main loop processes chunks of input, 1000 lines at a time for proteins, 10 at
    # a time for DNA. (This is to prevent timeouts, because DNA requires more work.)
    my $batchSize = ($protein ? 1000 : 10);
    while (my @tuples = ScriptThing::GetBatch(\*STDIN, $batchSize, $column)) {
        # If we're in normal FASTA mode, we need to create a comment hash.
        my %comments;
        if ($fasta) {
            %comments = ScriptThing::CommentHash(\@tuples, $column);
        }
        # Ask the server for results.

	my @fids  = map { $_->[0] } @tuples;
	my($genH,$funcH);
        $funcH = $shrub->Feature2Function(2,\@fids);
	my $seqH = $shrub->Feature2Trans(\@fids );

        # Loop through the IDs, producing output.
        for my $tuple (@tuples) {
            # Get the ID and the line.
            my ($id, $line) = @$tuple;
            # Get this feature's sequence.
            my $seq = $seqH->{$id};
            # Did we get something?
            if (! $seq) {
                # No. Write an error notification.
                print STDERR "Not found: $id\n";
            } elsif (! $fasta) {
                # Yes, and it's stripped. Write it at the end of the input line.
                print "$line\t$seq\n";
            } else {
                # Yes, and it's normal FASTA. Write it unaltered.
		#my $g = $genH->{$id}  ? $genH->{$id} : 'unknown';
		my $data = $funcH->{$id} ? $funcH->{$id} : 'hypothetical protein';
                my $f = ($data ? $data->[1]: "");
		$seq =~ s/(.{1,60})/$1\n/g;
                my $g = genome_of($id);
                #print ">$id $f [$g]\n$seq";
                print ">$id [$genomeH->{$g}] $f\n$seq";
            }
        }
    }
