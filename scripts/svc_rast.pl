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
use RASTlib;
use SeedUtils;
use gjoseqlib;


=head1 Annotate a Genome Using RAST

    svc_rast.pl [ options ] genomeID name

This script invokes the RAST service over the web to annotate a genome. It will submit a FASTA
file to RAST, wait for the job to finish, and then format the results into a JSON-form L<GenomeTypeObject>.

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The input can be a contig-only GenomeTypeObject in JSON format or a contig FASTA file. The
two positional parameters are the genome ID and the genome name. The additional command-line
options are as follows.

=over 4

=item gto

If specified, then the input file is presumed to be a contig object or a workspace contig object
encoded in JSON format. The contigs must be in the form of a list attached to the C<contigs>
member or the C<contigs> member of the C<data> member (the latter indicating a workspace object).

=item domain

The domain of the new genome-- C<B> for bacteria, C<A> for archaea, and so forth. The default is
C<B>.

=item geneticCode

The genetic code of the new genome. The default is C<11>.

=item user

User name for RAST access.

=item password

Password for RAST access.

=item sleep

Sleep interval in seconds while waiting for the job to complete. The default is C<60>.

=back

=cut

# URL for RAST requests
use constant RAST_URL => 'http://redwood.mcs.anl.gov:5000/quick';

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('genomeID name',
        ["gto|j", "input file is in JSON format"],
        ["domain|d=s", "domain (A or B) of the new genome", { default => 'B' }],
        ["geneticCode=i", "genetic code for the new genome", { default => 11 }],
        ["user|u=s", "user name for RAST access"],
        ["password|p=s", "password for RAST access"],
        ["sleep=i", "sleep interval for status polling", { default => 60 }],
        { nodb => 1, input => 'file' });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Compute the login information.
my $user = $opt->user;
my $pass = $opt->password;
# We will put the genome information in here. If the input is a GTO, it can be overridden.
my $domain = $opt->domain;
my $geneticCode = $opt->geneticcode;
my ($genomeID, $name) = @ARGV;
# Get the contigs from the file. We form the contigs into a FASTA string.
my $contigs;
if (! $opt->gto) {
    # Here we have FASTA input.
    $contigs = gjoseqlib::read_fasta($ih);
} else {
    # Here we have JSON input.
    my $genomeJson = SeedUtils::read_encoded_object($ih);
    # Get as much other information as we can directly from the GTO.
    $name //= ServicesUtils::json_field($genomeJson, 'name');
    $geneticCode = ServicesUtils::json_field($genomeJson, 'genetic_code', optional => 1) // $geneticCode;
    $domain = ServicesUtils::json_field($genomeJson, 'domain', optional => 1) // $domain;
    $genomeID //= ServicesUtils::json_field($genomeJson, 'id');
    # Correct the genome ID if this is a contigs object.
    $genomeID =~ s/\.contigs$//;
    # Normalize the domain.
    $domain = uc substr($domain, 0, 1);
    # Create the contig string.
    $contigs = ServicesUtils::contig_tuples($genomeJson);
}
# Complain if we still do not have a name and ID.
if (! $genomeID || ! $name) {
    die "You must specify a genome ID and name somewhere.";
}
# Invoke the RAST service.
my $annotation = RASTlib::Annotate($contigs, $genomeID, $name, user => $user, password => $pass,
        domain => $domain, geneticCode => $geneticCode, sleep => $opt->sleep);
# Write the result.
$annotation->destroy_to_file(\*STDOUT);
