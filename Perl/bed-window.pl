#!/usr/bin/perl
use strict;
use warnings;

# as input
# file containing a column of numbers no visible formatting juse a number on each line

use Getopt::Std;
my %opts;
getopts('i:w:s:n:f:', \%opts);

unless ($opts{i})
{
    print "\n######################################## bed-window ########################################";
    print "\nProduces a file containing two columns which are the start and end posiitions of a window";
    print "\nA precurser bed file where you want to sample within each window (e.g. GCContentByInterval)\n";
    print "\n-i Provide input file, a column of numbers representing the length of each scaffold";
    print "\n-w Window size (default = 100000)";
    print "\n-s Slide width (default = 100000 = jumping window)";
    print "\nName each scaffold and increment? (not required)\n  -n scaffold-name\n  -f first scaffold number (default = 1)";
    print "\n   e.g. print an first column scaffold1... scaffold2... where -n scaffold -f 1";
    print "\n\nYou can pipe in an infile try something like:";
    print "\nfor i in {1..<lastline>}; do sed -n <print_even> fasta | wc; done | sed -n 2~2p | awk <print_col3> | bed-window.pl -i -";
    print "\n############################################################################################\n\n";
    exit;
}

######################################## Set vairables ########################################
unless ($opts{w})
{
    $opts{w}=100000;
}
unless ($opts{s})
{
    $opts{s}=100000;
}
unless ($opts{f})
{
    $opts{f} = 1;
}
print "# infile = $opts{i}; window = $opts{w}; slide = $opts{s}\n";

###################################### Print start end position for window of each scaff#######
open(INFILE, "<$opts{i}") or die "cannot open < $opts{i}: $!";
foreach my $line (<INFILE>)
{
    my $start = 0;
    my $end = $start + ($opts{w}-1);
    my $endscaff = 0;
    chomp($line);
    $endscaff = $line;
    while ($endscaff >= $end)
    {
        if ($opts{n})
        {
            print "$opts{n}$opts{f}\t$start\t$end\n";
            $start = $start+$opts{s};
            $end = $end+$opts{s};
        }
        else
        {
            print "$start\t$end\n";
            $start = $start+$opts{s};
            $end = $end+$opts{s};
        }
    }
    if ($opts{n})
    {
        print "$opts{n}$opts{f}\t$start\t$endscaff\n";
        $opts{f}++;
    }
    else
    {
        print "$start\t$endscaff\n"; 
    }
}
