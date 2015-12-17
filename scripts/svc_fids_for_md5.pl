########################################################################
use strict;

use Getopt::Long;
use ScriptThing;
use STKServices;
use ServicesUtils;

#
# This is a SAS Component
#


=head1 svc_fids_for_md5

Given a set of md5 protein IDs, compute the FIG IDs of features that produce each
protein. This script takes as input a table containing md5 protein IDs and 
adds a column containing the associated FIG feature IDs.

------
Example:

    svc_fids_for_md5 < md5_file > md5_file_with_fids

------

=back

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing md5 protein IDs is not the last.

=back

=head2 Output Format

The standard output is a tab-delimited file. It consists of the input
file with an extra column added (the ID of a feature that produces the
specified protein).  Note that this implies that there will
often be multiple output lines for a single input line.

=cut

use SeedUtils;
use Getopt::Long;
use ScriptThing;

my $usage = "usage: svc_fids_for_md5 [-c column]";

my $column;
my($helper,$opt) = &ServicesUtils::get_options('');
my $ih = ServicesUtils::ih($opt);

while (my @batch = ServicesUtils::get_batch($ih, $opt))
{
    my $md5H = $helper->fids_for_md5([map { $_->[0] } @batch]);
    for my $couplet (@batch) {
        # Get the input value and input row.
        my ($value,$row) = @$couplet;
        # Check for a result.
        my $result = $md5H->{$value};
        if (@$result > 0) {
            foreach my $tuple (@$result)
	    {
		my($md5,$fid) = @$tuple;
		print join("\t", @$row, $fid), "\n";
	    }
	}
    }
}

