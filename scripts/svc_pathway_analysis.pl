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

=head1 Common Services Function

    svc_pathway_analysis.pl [ options ] genomeID

This script takes role IDs as input and computes the pathways implied by the roles. It then relates
these pathways to the reactions and ultimately the features of a single genome.

=head2 Output

The output file is created from whole cloth, and will consist of the following fields.

=over 4

=item 1

A pathway ID.

=item 2

A reaction ID

=item 3

The reaction name

=item 4

A feature ID

=item 5

The role associated with the reaction belonging to the feature.

=back

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

The single positional parameter is the input genome ID.

The input file is tab-delimited.

=over 4

=item minF

This specifies the minimum fraction of the Reactions connecting to a Complex
that must be present for the Complex to be considered active.

=item genomeRoles

If specified, then the standard input will not be read. Instead, the roles will be computed from the
genome.

=item addRoles

If specified, the the roles in the standard input are presumed to be in addition to the roles already
in the genome.

=item priv

Privilege level to use for role assignments. The default is C<0>.

=item json

If specified, the name of a file containing the genome as a L<GenomeTypeObject> in JSON format. This
file will be used instead of the genome specified as a parameter.

=back

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('genomeID',
        ['minF|m=f','minimum fraction of reactions needed to be an active complex',{ default => 0.5} ],
        ["priv|p", "functional role privilege level", { default => 0 }],
        ['genomeRoles', 'use roles currently in genome'],
        ['addRoles', 'add input roles to genome roles'],
        ['json=s', 'name of a file containing the genome as a JSON GenomeTypeObject'],
        { batchSize => 0 });
# Open the input file.
my $ih = ServicesUtils::ih($opt);
# This will map roles to features.
my $roleHash = {};
# Get the genome ID.
my ($genomeID) = @ARGV;
if ($opt->json) {
    # Here we are reading the genome from a json file.
    my $genomeJson = SeedUtils::read_encoded_object($opt->json);
    # Get a map of each role to its features in the genome.
    my $features = $genomeJson->{features};
    for my $feature (@$features) {
        my $function = $feature->{function};
        my $fid = $feature->{id};
        my @roles = SeedUtils::roles_of_function($function);
        my $rolesH = $helper->desc_to_role(\@roles);
        for my $roleID (values %$rolesH) {
            push @{$roleHash->{$roleID}}, $fid;
        }
    }
} elsif (! $genomeID) {
    die "A genome ID is required.";
} else {
    # Here we are getting genome data from the database.
    # Map each role to its features in the genome.
    $roleHash = $helper->genome_feature_roles($genomeID, $opt->priv);
}
# Get the list of roles.
my $roles = [];
if ($opt->genomeroles || $opt->addroles) {
    # Here we want the roles from the genome.
    $roles = [sort keys %$roleHash];
}
if ((! $opt->genomeroles) || $opt->addroles) {
    # Here we want the roles from the input.
    my $inRoles = ServicesUtils::get_column($ih, $opt->col);
    push @$roles, @$inRoles;
}
# Get the list of reactions.
my $reactionHash = $helper->role_to_reactions($roles);
my %reactionMap;
for my $role (keys %$reactionHash) {
    my $reactionList = $reactionHash->{$role};
    for my $reactionThing (@$reactionList) {
        my ($reaction) = @$reactionThing;
        push @{$reactionMap{$reaction}}, $role;
    }
}
# Get the list of pathways.
my @pathways = $helper->reactions_to_implied_pathways([keys %reactionMap], $opt->minf);
# Finally, get a list of the reactions for each pathway.
my $pathwayHash = $helper->pathways_to_reactions(\@pathways);
# Now we need to assemble all of this into our output. We start from the pathways.
for my $pathway (@pathways) {
    # Get the pathway's reactions.
    my $reactionList = $pathwayHash->{$pathway};
    # Loop through the reactions.
    for my $reactionThing (@$reactionList) {
        my ($reactionId, $reactionName) = @$reactionThing;
        # Get the reaction's roles.
        my $roleList = $reactionMap{$reactionId};
        for my $role (@$roleList) {
            # Loop through the role's features.
            my $fidList = $roleHash->{$role};
            for my $fid (@$fidList) {
                # Here we have an output line.
                print join("\t", $pathway, $reactionId, $reactionName, $fid, $role) . "\n";
            }
        }
    }
}
