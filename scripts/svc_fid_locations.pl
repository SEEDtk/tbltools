########################################################################
use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_fid_locations < FIDs > with.locs

Clusters from protein-encoding genes

------

Example:

    svr_all_features 3702.1 peg | svr_fid_locations
    svr_all_features 3702.1 peg | svr_fid_locations -b

would produce a 3-column table.  The first column would contain
FID IDs and the second the FID locations. 
The file would be sorted on the locations.
The second version would collapse multi-region locations into
just the boundaries.
------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the FID for which clusters are being requested.
If some other column contains the FIDs, use

    -c N

where N is the column (from 1) that contains the FID in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing FIDs is not the last.

=item -b [return just boundaries]

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the locations of fids)

=cut

use ServicesUtils;

my $usage = "usage: fid_locations [-c column] [-b]\n";

my($opt,$helper) = &ServicesUtils::get_options('',["boundaries|b","Just boundaries"]);
my $ih = ServicesUtils::ih($opt);
my $boundaries = $opt->boundaries;

while (my @batch = ServicesUtils::get_batch($ih, $opt))
{
    my @fids = map { $_->[0] } @batch;
    my $locH = $helper->fid_locations([\@fids,$boundaries);
    foreach my $couplet (@batch)
    {
        my ($fid,$row) = @$couplet;
	my $loc = $locH->{$fid};
	print join("\t", @$row, $loc), "\n";
    }
}

