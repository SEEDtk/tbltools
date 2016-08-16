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

=head1 Get All Instances of an Entity

    all_entities.pl [ options ] entityName

Return a table containing all instances of a particular entity, optionally filtered by
one or more parameters.

=head2 Parameters

The command-line options include all those in L<Shrub/script_options> plus the following.

=over 4

=item fields

A comma-delimited list of field names specifying the list of fields to be included in the
output. The default value is the list of default fields for the entity.

=item all

Include all of the entity's fields.

=item show-fields

Output a list of the entity's fields rather than data from the database.

=item is (multiple)

A field name followed by a comma and a value (C<--is=>I<fieldName>C<,>I<value>). Only entity
instances with the specified value in the named field will be included in the output.

=item like (multiple)

A field name followed by an SQL match pattern (C<--like=>I<fieldName>C<,>I<value>). Only entity
instances with a matching value in the named field will be included in the output. Unlike the
other operators, C<--like> does case-insensitive matching.

=item op (multiple)

A field name followed by an operator and a value, all comma-separated (C<--op=>I<fieldName>C<,>I<op>C<,>I<value>).
Only entity instances for which the value in the named field stands in the proper relationship to
the supplied value will be included in the output. The operator can be C<lt>, C<le>, C<gt>, C<ge>, C<eq>,
or C<ne>.

=back

=cut

# Get the command-line parameters.
my $opt = ScriptUtils::Opts('entityName', Shrub::script_options(),
        ['fields|f=s', 'list of fields to include in output'],
        ['all|a', 'include all fields in output'],
        ['is=s@', 'filter by exact match'],
        ['like=s@', 'filter by pattern match'],
        ['op=s@', 'filter by relational operator'],
        ['show-fields|s', 'display the fields of the entity', { shortcircuit => 1 }] );
# Connect to the database.
my $shrub = Shrub->new_for_script($opt);
# Get the entity name.
my ($entityName) = @ARGV;
# Look for the entity's descriptor.
my $entityData = $shrub->FindEntity($entityName);
if (! $entityData) {
    die "Invalid entity name $entityName.";
}
# Get the field list.
my @allFields = ERDBtk::Helpers::Scripts::field_list($entityName, $entityData);
# Check for a field list request.
if ($opt->show_fields) {
    print map { join("\t", @$_) . "\n" } @allFields;
} else {
    # Compute the output field list.
    my @fieldList = ERDBtk::Helpers::Scripts::compute_field_list($opt->all, $opt->fields, $entityData, \@allFields);
    # Compute the filtering.
    my ($filter, $parms) = ERDBtk::Helpers::Scripts::compute_filtering($opt->is, $opt->like, $opt->op,
            $entityName, $entityData);
    # Execute the query.
    my @results = $shrub->GetAll($entityName, $filter, $parms, \@fieldList);
    # Remove duplicates.
    my $results = ERDBtk::Helpers::Scripts::clean_results(\@results);
    # Output the results.
    print map { join("\t", @$_) . "\n" } @$results;
}

