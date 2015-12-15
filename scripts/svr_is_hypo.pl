use strict;
use Data::Dumper;
use Carp;

#
# This is a SAS Component
#


=head1 svr_is_hypo [-c N] [-v]

Keep just hypotheticals

------

Example:

    svr_all_features 3702.1 peg | function_of | svr_is_hypo

would produce a 2-column table containing the [peg,function] for
hypotheticals in genome 3702.1

Versions of this command once took a stream of feature IDs (PEGs) as input. 
This version takes values of functions and lets through those
that are hypothetical.  Use the -v parameter if you wish only
the functions that are not hypothetical.

------

The standard input should be a tab-separated table (i.e., each line 
is a tab-separated set of fields).  Normally, the last field in each
line would contain the PEG .  If some other column contains the PEGs, use

    -c N

where N is the column (from 1) that contains the PEG in each case.

This is a pipe command. The input is taken from the standard input, and the
output is to the standard output.

=head2 Command-Line Options

=over 4

=item -c Column

This is used only if the column containing PEGs is not the last.

=item -v [keep only non-hypotheticals]

=back

=head2 Output Format

This is a filter producing a subset of the input lines.

=cut

use SeedUtils;
use SAPserver;
my $sapObject = SAPserver->new();
use Getopt::Long;

my $usage = "usage: svr_is_hypo [-c column] [-v]";

my $column;
my $v;
my $rc  = GetOptions('c=i' => \$column,
		     'v'   => \$v);
if (! $rc) { print STDERR $usage; exit }

my @lines = map { chomp; [split(/\t/,$_)] } <STDIN>;
(@lines > 0) || exit;
foreach $_ (@lines)
{
    my $thing = $_->[$column-1];
    my $func;
    $func = $thing;
    my $hypo = &SeedUtils::hypo($func);
    if (((! $v) && $hypo) || ($v && (! $hypo)))
    {
	print join("\t",@$_),"\n";
    }
}
