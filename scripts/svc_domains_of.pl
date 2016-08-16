use strict;
use Shrub;
use ScriptUtils;
use Data::Dumper;
use Carp;
use Getopt::Long;
use LWP::UserAgent;
use Digest::MD5;
use ConservedDomainSearch;
use ScriptThing;
use FIG;

use gjoseqlib;


=head1 Search CDD Data

    svc_domains_of [options] < fids > domains added to lines

Use the ConservedDomainSearch.pm api to search for domains. The input is a list of fids

=head2 Parameters

See L<ServicesUtils> for more information about common command-line options.

=cut

my $usage = <<"End_of_Usage";

usage: domain_of [options] < fids > domains.table

       -h   print this help screen

End_of_Usage


# Get the command-line parameters.
my $opt =
  ScriptUtils::Opts( '',
                     Shrub::script_options(), ScriptUtils::ih_options(),
                        ['col|c=i', 'rowid column', { }],
                        ['specific|s', 'specific hits', { }]
    );
my $ih = ScriptUtils::IH( $opt->input );
my $shrub = Shrub->new_for_script($opt);
my $column = $opt->col;
my $specific = $opt->specific;
my $md5;
my %options =  (data_mode => 'rep');
my $fig = FIG->new_for_script($opt);
my $CDD = ConservedDomainSearch->new($fig);
my @ids;
my %lineH;


while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    foreach my $tuple (@tuples) {
        my ($id, $line) = @$tuple;
        my $d = $CDD->domains_of([$id]);
        print $line, "\t",join(",", @{$d->{$id}}), "\n";
    }
}
