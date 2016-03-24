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
use Spreadsheet::WriteExcel;

=head1 Convert Tab-Delimited File to Excel Spreadsheet 

Writes the contents of the tab separated file on STDIN to a spreadsheet

The output is an xls file

Example: svc_file_to_spreadsheet -f test.xls  < test.txt 

=head2 Command-Line Options

=over 4

=item file

The file name given to the output xls format spreadsheet.

=item fidlinks

If specified, the number (1-based) of a column containing feature IDs. The feature IDs will be converted to hyperlinks.
Unlike most scripts, you cannot specify C<0> for the last column.

=back

=head2 Output Format

The output is a file in xls format

=cut

# Get the command-line parameters.
my ($opt, $helper) = ServicesUtils::get_options('',
        ['file|f=s',    'output file name', { required => 1 }],
        ['fidlinks|u=i',  'convert feature IDs to links'],
        { input => 'file' }
);
# Create a new Excel workbook
my $workbook = Spreadsheet::WriteExcel->new($opt->file);
if (!$workbook) {
    die "Could not create workbook " . $opt->file;
}
# Add a worksheet
my $worksheet = $workbook->add_worksheet();
if (!$worksheet) {
    die "Could not create a worksheet in " . $opt->file;
}
# Check for the fidlinks feature.
my $fidlinks = $opt->fidlinks;
# This data structure is used by the link converter.
my %linkData;
# Loop through the file, creating the spreadsheet.
my $row = 0;
my $col = 0;
my @ctot;
my $ih = ServicesUtils::ih($opt);
while (! eof $ih) {
    my @line = ServicesUtils::get_cols($ih, 'all');

    $col = 0;
    foreach my $element (@line) {
        $ctot[$col] += length($element);
        # We put any hyperlink in here. If the subroutine decides not to link,
        # it will come back undefined.
        my $link;
        if ($fidlinks && $col+1 == $fidlinks) {
            $link = $helper->convert_to_link(fid => $element, \%linkData);
        }
        if ($link) {
            $worksheet->write_url($row, $col, $link, $element);
        } else {
            $worksheet->write($row, $col, $element);
        }
        $col++;
    }
    $row++;
}
# Fix up the column widths.
for my $col (0..$#ctot) {
    my $avg = int($ctot[$col] / $row);
    if ($avg > 5)
    {
        $worksheet->set_column($col, $col, $avg);
    }
}
