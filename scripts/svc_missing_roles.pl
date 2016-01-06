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
use File::Copy::Recursive;
use SeedUtils;
use KmerDb;
use FileHandle;
use BlastInterface;

=head1 Missing-Role Analysis

    svc_missing_roles.pl [ options ] kmerdb workDir

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

The single positional parameter is the name of a KMER database for the candidate close genomes. The
database should be protein kmers and should have been created by L<svc_kmerdb.pl>.

The command-line options are as follows.

=over 4

=item annotations

Name of a JSON-format L<GenomeTypeObject> file containing the annotations. If omitted, the annotation are presumed
to be in the input file.

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

User name for calls to RAST (if needed).

=item password

Password for calls to RAST (if needed).

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
        { input => 'file' });
# Get the kmer database.
my ($kmerFile) = @ARGV;
if (! $kmerFile) {
    die "No KMER database specified.";
} elsif (! -s $kmerFile) {
    die "Kmer file $kmerFile not found or empty.";
}
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# Read the incoming genome.
my $genomeJson = SeedUtils::read_encoded_object($ih);
close $ih;
# We'll use this for output handles.
my $oh;
# Get the genome ID and name.
my $genomeID = ServicesUtils::json_field($genomeJson, 'id');
my $name = ServicesUtils::json_field($genomeJson, 'name');
# Correct the genome ID if this is a contigs object.
$genomeID =~ s/\.contigs$//;
# Compute the working directory.
my $workDir = $opt->workdir;
if (! $workDir) {
    $workDir = "$genomeID.files";
}
if (! -d $workDir) {
    File::Copy::Recursive::pathmk($workDir) || die "Could not create $workDir: $!";
}
# Open the log file.
my $logh;
if ($opt->warn) {
    $logh = \*STDERR;
} else {
    $logh = FileHandle->new(">$workDir/status.log") || die "Could not open log file: $!";
    $logh->autoflush();
}
print $logh "Incoming genome is $genomeID: $name.\n";
# Create a FASTA file from the contigs.
my $contigList = ServicesUtils::contig_tuples($genomeJson);
my $fastaFile = CreateContigFasta($contigList, $genomeID, $workDir);
# Get the feature list from the incoming genome.
my $featureList = ServicesUtils::json_field($genomeJson, 'features', optional => 1);
if (! $featureList) {
    if ($opt->annotations) {
        # Here we have annotations in a separate object.
        print $logh "Reading annotations from " . $opt->annotations . "\n";
        my $annotationJson = SeedUtils::read_encoded_object($opt->annotations);
        $featureList = ServicesUtils::json_field($annotationJson, 'features');
    } else {
        # Here we need to use RAST.
        $featureList = FeaturesFromRast($contigList, $genomeID, $name, $opt->geneticcode, $opt->domain,
                $opt->user, $opt->password);
    }
}
my $roleH = LoadRoles($featureList);
print $logh  scalar(keys %$roleH) . " roles found in $genomeID.\n";
# Spool the roles found.
my $gRoleFile = "$workDir/genome.roles.tbl";
open($oh, ">$gRoleFile") || die "Could not open $gRoleFile: $!";
for my $role (sort keys %$roleH) {
    print $oh join("\t", $role, $roleH->{$role}) . "\n";
}
close $oh; undef $oh;
# The next step is to get the close genomes. Read the kmer database.
print $logh  "Reading kmer database from $kmerFile.\n";
my $kmerdb = KmerDb->new(json => $kmerFile);
# Loop through the contigs, counting hits.
my %counts;
for my $contig (@$contigList) {
    my $contigID = $contig->[0];
    my $sequence = $contig->[2];
    print $logh  "Processing contig $contigID.\n";
    $kmerdb->count_hits($sequence, \%counts, $opt->geneticcode);
}
# Get the best genomes.
my ($deleted, $kept) = (0, 0);
for my $closeG (keys %counts) {
    if ($counts{$closeG} >= $opt->minhits) {
        $kept++;
    } else {
        delete $counts{$closeG};
        $deleted++;
    }
}
print $logh  "$kept close genomes found, $deleted genomes discarded.\n";
my @sorted = sort { $counts{$b} <=> $counts{$a} } keys %counts;
$deleted = 0;
while ($kept > $opt->keep) {
    my $deleteG = pop @sorted;
    $deleted++;
    $kept--;
    delete $counts{$deleteG};
}
print $logh  "$kept close genomes in final list.\n";
my $closeFile = "$workDir/close.tbl";
open($oh, ">$closeFile") || die "Could not open $closeFile: $!";
for my $sortedG (@sorted) {
    print $oh join("\t", $sortedG, $counts{$sortedG}, $kmerdb->name($sortedG)) . "\n";
}
close $oh; undef $oh;
print $logh  "Close genomes written to $closeFile.\n";
# Release the memory for the kmer database.
undef $kmerdb;
# This hash will contain the roles found in the close genomes but not in the new genome.
my %roleCounts;
# Get the roles in the close genomes.
my $genomeRolesH = $helper->roles_in_genomes(\@sorted, 0, 'ssOnly');
# Filter out the ones already in the new genome.
for my $closeG (@sorted) {
    print $logh  "Processing roles in $closeG.\n";
    # Get the close genome's roles.
    my $rolesL = $genomeRolesH->{$closeG};
    for my $role (@$rolesL) {
        if (! $roleH->{$role}) {
            $roleCounts{$role}++;
        }
    }
}
# Get the role descriptions.
my $roleNamesH = $helper->role_to_desc([keys %roleCounts]);
# Spool the roles to the work directory.
my $roleFile = "$workDir/missing.roles.tbl";
print $logh  "Writing roles to $roleFile.\n";
open($oh, ">$roleFile") || die "Could not open $roleFile: $!";
my @sortedRoles = sort { $roleCounts{$b} <=> $roleCounts{$a} } keys %roleCounts;
for my $role (@sortedRoles) {
    print $oh join("\t", $role, $roleCounts{$role}, $roleNamesH->{$role}) . "\n";
}
close $oh; undef $oh;
# Now we need to get the features for these roles and blast them.
print $logh  "Retrieving features from close genomes.\n";
my $triples = GetRoleFeatureTuples(\@sortedRoles, \@sorted);
# Run the BLAST.
print $logh  "Performing BLAST.\n";
my $matches = RunBlast($triples, $fastaFile, $opt->maxe, $opt->minlen);
my $blastFile = "$workDir/blast.tbl";
# Now we process the matches. We spool them to an intermediate file at the same time
# we write them to the output.
print $logh  "Spooling BLAST output to $blastFile.\n";
open($oh, ">$blastFile") || die "Could not open $blastFile: $!";
for my $match (@$matches) {
    # Spool to the blast file.
    print $oh join("\t", @$match) . "\n";
    # Get the output fields.
    my $role = $match->qdef;
    my $desc = $roleNamesH->{$role};
    my $count = $roleCounts{$role};
    my $score = $match->scr;
    my $pct = $match->pct;
    my $loc = $match->sid . "_" . $match->s1 . $match->dir . $match->n_mat;
    print join("\t", $role, $desc, $count, $score, $pct, $loc) . "\n";
}
close $oh; undef $oh;
print $logh  "All done.\n";


=head2 Internal Subroutines

=head3 RunBlast

    my $matches = RunBlast($triples, $fastaFile, $maxe, $minlen);

Run BLAST against the feature triples to find hits in the new genome's
contigs.

=over 4

=item triples

Reference to a list of FASTA triples for the features from the close genomes.

=item fastaFile

Name of the FASTA file for the new genome's contigs.

=item maxe

Maximum permissible E-value.

=item minlen

Minimum percentage of the query length that must match (e.g. C<50> would require a match for half the
length).

=item RETURN

Returns a reference to a list of L<Hsp> objects for the matches found.

=back

=cut

sub RunBlast {
    # Get the parameters.
    my ($triples, $fastaFile, $maxe, $minlen) = @_;
    # Declare the return variable.
    my @retVal;
    # Get the matches.
    my $matches = BlastInterface::blast($triples, $fastaFile, 'tblastn',
            { outForm => 'hsp', maxE => $maxe });
    # Filter by length.
    my ($rejected, $kept) = (0, 0);
    for my $match (@$matches) {
        my $minForMatch = $match->qlen * $minlen / 100;
        if ($match->n_id >= $minForMatch) {
            push @retVal, $match;
            $kept++;
        } else {
            $rejected++;
        }
    }
    print $logh  "$rejected matches rejected by length check; $kept kept.\n";
    # Return the result.
    return \@retVal;
}


=head3 GetRoleFeatureTuples

    my $triples = GetRoleFeatureTuples(\@roles, \@genomes);

Compute the FASTA triples for the features in the close genomes belonging
to the specified roles. The comment field is the role ID. The sequence
will be the feature's protein translation.

=over 4

=item roles

Reference to a list of the roles whose features are desired.

=item genomes

Reference to a list of the close genomes from which the features should be taken.

=item RETURN

Returns a reference to a list of FASTA triples for the desired features.

=back

=cut

sub GetRoleFeatureTuples {
    # Get the parameters.
    my ($roles, $genomes) = @_;
    # Declare the return variable.
    my @retVal;
    # Get the features for the roles.
    my $roleH = $helper->role_to_features($roles, 0, $genomes);
    # Get the translations.
    for my $role (keys %$roleH) {
        my $fids = $roleH->{$role};
        my $fidHash = $helper->translation($fids);
        for my $fid (keys %$fidHash) {
            push @retVal, [$fid, $role, $fidHash->{$fid}];
        }
    }
    # Return the result.
    return \@retVal;
}



=head3 LoadRoles

    my $roleH = LoadRoles($featureList);

Get the list of roles from the specified list of feature descriptors.

=over 4

=item featureList

Reference to a list of feature descriptors. Each is a hash reference, and the
functional assignment must be in the C<function> member.

=item RETURN

Returns a reference to a hash keyed by role ID for all the roles in the feature list.

=back

=cut

sub LoadRoles {
    # Get the parameters.
    my ($featureList) = @_;
    # Create a role hash.
    my %rolesH;
    for my $feature (@$featureList) {
        my $function = $feature->{function};
        my @roles = SeedUtils::roles_of_function($function);
        for my $role (@roles) {
            $rolesH{$role} = 1;
        }
    }
    # Now we have all the roles. Compute the descriptions.
    my $descH = $helper->desc_to_role([keys %rolesH]);
    # Reverse the hash to get the role IDs.
    my %retVal = map { $descH->{$_} => $_ } keys %$descH;
    # Return the result.
    return \%retVal;
}


=head3 FeaturesFromRast

    my $featureList = FeaturesFromRast($contigs, $genomeID, $name, $geneticcode, $domain, $user, $pass);

Use RAST to compute the features in the new genome.

=over 4

=item contigs

Reference to a list of contig triples, each consisting of (0) a contig ID, (1) a comment, and (2) the
contig DNA sequence.

=item genomeID

ID of the new genome.

=item name

Name of the new genome.

=item geneticcode

Genetic code for the new genome.

=item domain

Domain code for the new genome (e.g. C<B> for bacteria, C<A> for archaea).

=item user

RAST user name.

=item pass

RAST password.

=item RETURN

Returns a reference to a list of feature descriptors.

=back

=cut

sub FeaturesFromRast {
    # Get the parameters.
    my ($contigs, $genomeID, $name, $geneticcode, $domain, $user, $pass) = @_;
    # Load the RAST library.
    require RASTlib;
    # Annotate the contigs.
    print $logh "Annotating contigs using RAST.\n";
    my $gto = RASTlib::Annotate($contigs, $genomeID, $name, user => $user, password => $pass,
            domain => $domain, geneticCode => $geneticcode);
    # Spool the GTO to disk.
    print $logh "Spooling RAST annotations.\n";
    open(my $oh, ">$workDir/genome.json") || die "Could not open GTO output file: $!";
    SeedUtils::write_encoded_object($gto, $oh);
    # Extract the features.
    my $retVal = $gto->{features};
    # Return the result.
    return $retVal;
}


=head3 CreateContigFasta

    my $fastaFile = CreateContigFasta($contigList, $genomeID, $workDir);

Create a contig FASTA file. The file will be created in the specified working
directory and the file name will be returned. The specified genome ID will be
used as the comment string for each contig.

=over 4

=item contigList

Reference to a list of contig triples [id, comment, sequence].

=item genomeID

Genome ID of the incoming genome.

=item workDir

Working directory to contain the FASTA file.

=item RETURN

Returns the name of the file created.

=back

=cut

sub CreateContigFasta {
    # Get the parameters.
    my ($contigList, $genomeID, $workDir) = @_;
    # Declare the return variable.
    my $retVal = "$workDir/contigs.fasta";
    # Open the output file.
    open(my $oh, ">$retVal") || die "Could not open $retVal: $!";
    # Loop through the contigs, writing the FASTA.
    my $count = 0;
    for my $contig (@$contigList) {
        print $oh ">$contig->[0] $genomeID\n$contig->[2]\n";
        $count++;
    }
    print $logh  "$count contigs written to $retVal.\n";
    # Return the result.
    return $retVal;
}


