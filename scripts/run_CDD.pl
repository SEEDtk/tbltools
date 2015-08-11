use strict;
use Data::Dumper;
use Proc::ParallelLoop;
my $data_dir = "/homes/disz/CDD_Data/";


my @lines = <>;

pareach(\@lines, \&process_lines, {Max_Workers => 10});

sub process_lines {
    my $ss = shift;
    chomp $ss;
    my $dir = $data_dir.$ss;
    if (-d $dir) {return;}
    mkdir $dir unless -d $dir;
    my $cmd = "echo $ss | perl ss2roles.pl | perl filter_roles -c2 | perl peg_of.pl  | perl trans_of.pl | perl domain_of.pl -s | cut -f 1,2,3,4,6 > $dir/cdd";
    #print("$cmd, \n");
    system($cmd);
}
