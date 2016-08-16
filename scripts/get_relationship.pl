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
use ScriptUtils;
use Shrub;
use ERDBtk::Helpers::Scripts;

=head1 Cross a Relationship

    get_relationship.pl [ options ] relationshipName

Return a table containing instances of an entity on the far side of a relationship.

This method takes a tab-delimited file as input and produces tab-delimited output with new fields
added to the end of the input rows. Input rows with IDs not found in the from-link field of the
relationship will be removed from the output. The input file is either the standard input or is
taken from the command-line options in L<ScriptUtils/ih_options>.

Note that each relationship has two names-- one for each direction-- so this method can be used
to cross in both directions.

=head2 Parameters

The command-line options include all those in L<Shrub/script_options> plus the following.

=over 4

=item col

The (1-based) index of the ID column in the input. The default is the last column.

=item fields

A comma-delimited list of field names specifying the list of fields to be included in the
output. The default value is no fields.

=item all

Include all of the relationship's fields (excepting from-link and to-link).

=item show-fields

Output a list of the relationship's fields rather than data from the database.

=item to

A comma-delimited list of field names specifying the list of fields from the destination
entity to be included in the output. The default value is the list of default fields in
the entity.  A value of C<all> indicates all of the fields should be used.

=item filter (multiple)

A field name followed by a comma and a value (C<--filter=>I<fieldName>C<,>I<value>). Only relationship
instances with the specified value in the named field will be crossed to form the output.

=item is (multiple)

A field name followed by a comma and a value (C<--is=>I<fieldName>C<,>I<value>). Only target entity
instances with the specified value in the named field will be included in the output.

=item like (multiple)

A field name followed by an SQL match pattern (C<--like=>I<fieldName>C<,>I<value>). Only target entity
instances with a matching value in the named field will be included in the output. Unlike the
other operators, C<--like> does case-insensitive matching.

=item op (multiple)

A field name followed by an operator and a value, all comma-separated (C<--op=>I<fieldName>C<,>I<op>C<,>I<value>).
Only target entity instances for which the value in the named field stands in the proper relationship to
the supplied value will be included in the output.

=back

=cut

# Get the command-line parameters.
my $opt = ScriptUtils::Opts('relName', Shrub::script_options(), ScriptUtils::ih_options(),
        ['col|c=i', '(1-based) index of the input column', { default => 0 }],
        ['fields|f=s', 'list of fields to include in output'],
        ['to=s', 'list of target entity fields to include in output'],
        ['all|a', 'include all fields in output'],
        ['filter=s@', 'filter relationship by exact match'],
        ['is=s@', 'filter target by exact match'],
        ['like=s@', 'filter target by pattern match'],
        ['op=s@', 'filter target by relational operator'],
        ['show-fields|s', 'display the fields of the entity', { shortcircuit => 1 }] );
# Connect to the database.
my $shrub = Shrub->new_for_script($opt);
# Get the entity name.
my ($relName) = @ARGV;
# Look for the entity's descriptor.
my $relData = $shrub->FindRelationship($relName);
if (! $relData) {
    die "Invalid relationship name $relName.";
}
# Get the target entity.
my $entityName = $shrub->ComputeTargetEntity($relName);
my $entityData = $shrub->FindEntity($entityName);
# Get the target entity field list.
my @allFields = ERDBtk::Helpers::Scripts::field_list($entityName, $entityData);
# Get the relationship field list.
my @relFields = ERDBtk::Helpers::Scripts::field_list($relName, $relData);
# Check for a field list request.
if ($opt->show_fields) {
    print map { join("\t", @$_) . "\n" } @relFields;
    print map { "$entityName($_->[0])\t$_->[1]\n" } @allFields;
} else {
    # Compute the output field list from the relationship.
    my @fieldList = ERDBtk::Helpers::Scripts::compute_field_list($opt->all, $opt->fields, $relData, \@relFields);
    # Compute the output field list from the target entity.
    my $fields = $opt->to;
    my $all;
    if ($fields && $fields eq 'all') {
        $fields = undef;
        $all = 1;
    }
    push @fieldList, map { "$entityName($_)" }
            ERDBtk::Helpers::Scripts::compute_field_list($all, $fields, $entityData, \@allFields);
    # Compute the input column index.
    my $col = $opt->col - 1;
    # Compute the filtering.
    my ($filter, $parms) = ERDBtk::Helpers::Scripts::compute_filtering($opt->is, $opt->like, $opt->op,
            $entityName, $entityData);
    if ($filter) {
        $filter = "($filter) AND $relName(from-link) = ?";
    } else {
        $filter = "$relName(from-link) = ?";
    }
    # Get the relationship filters.
    my $relFilters = $opt->filter // [];
    my @relFilterThings = map { [ split /,/, $_, 2 ] } @$relFilters;
    # Insure the field names are valid.
    ERDBtk::Helpers::Scripts::validate_fields([ map { $_->[0] } @relFilterThings ], $relData);
    # Process the filters.
    $filter = join(' AND ', (map { "$relName($_->[0]) = ?" } @relFilterThings), $filter);
    $parms = [(map { $_->[1] } @relFilterThings), @$parms];
    # Open the input file.
    my $ih = ScriptUtils::IH($opt->input);
    # Loop through the input, extracting IDs.
    my $column = $opt->col - 1;
    while (! eof $ih) {
        my $line = <$ih>;
        $line =~ s/[\r\n]+$//;
        # Get the ID column.
        my @fields = split /\t/, $line;
        my $id = $fields[$column];
        # Execute the query.
        my @results = $shrub->GetAll("$relName $entityName", $filter, [@$parms, $id], \@fieldList);
        # Remove duplicates.
        my $results = ERDBtk::Helpers::Scripts::clean_results(\@results);
        # Append the results to the input row.
        print map { join("\t", @fields, @$_) . "\n" } @$results;
    }
}

