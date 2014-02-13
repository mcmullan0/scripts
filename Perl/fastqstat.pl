#!/usr/bin/perl -w
use strict;
use warnings;

# Return the total number of reads and bases and the average (StDev)
# length of reads and the estimated coverage, if genome size is provided.

use Getopt::Std;
{
    my %opts;
    # accept input file -i (argument)
    # accept genome size -g (argument)
    getopts('i:g:', \%opts);
    if ($opts{i})
    {
        unless (open(INFILE, $opts{i}))
        {
            print "\n\nCannot open infile\nClosing script\n$!\n";
            exit;
        }
        print "$opts{i}";
    }
    else
    {
        print "\nEnter -i filename\n\n";
    }
    if ($opts{g})
    {
        print "\nGenome = $opts{g}\n"
    }
}
my $nread = 0;          # Could use wc -l but I have to read each line anyway..
my $nbase = 0;
my $counter = 0;
# Read each line and record information every 4th line
foreach my $line (<INFILE>)
{
    $counter = $counter + 1;
    my $remain = $counter % 4;
    if ($remain == 0)
    {
        $nread = $nread + 1;
        $nbase = $nbase + length($line);
        
    }
}