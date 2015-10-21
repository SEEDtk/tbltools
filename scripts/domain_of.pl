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

use gjoseqlib;

my $usage = <<"End_of_Usage";

usage: domain_of [options] < seq > cdd.table

       -h   print this help screen
       -s   only specific hits

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
my $CDD = ConservedDomainSearch->new();


while (my @tuples = ScriptThing::GetBatch($ih, undef, $column)) {
    foreach my $tuple (@tuples) {
        my ($seq, $line) = (@$tuple);
        my @domain;
        my $id = 1;
        my $d = $CDD->lookup_seq($id, $md5, $seq, \%options);
#        print Dumper($d); die;
        foreach my $hit (@{$d->{$id}->{"domain_hits"}}) {
            if (!$specific || ($hit->[0] eq "Specific")) {
                push (@domain, "$hit->[7]:$hit->[4]");
            }
       }
        print $line, "\t", join(", ", @domain), "\n";
    }
}
