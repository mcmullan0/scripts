#!/usr/bin/perl
use strict;
use warnings;

# run samtools depth on a list of files provided by the user and output to a table
# source samtools-0.1.19
# Enter -l <file> contianing a list of files to run
# Enter -q <bsub que> 
# Enter -p if you want to print the command line to check the run

use Getopt::Std;
my %opts;
getopts('l:q:p', \%opts);

unless ($opts{l})
{
  print "\nrun samtools depth on a list of files provided by the user and output to a table\n\nsource samtools-0.1.19";
  print "\n\nEnter -l <file> contianing a list of files to run\nEnter -q <bsub que>\nEnter -p if you want to print the command line to check the run\n\n";
  exit;
}
unless (open (INFILE, $opts{l}))
{
  print "\n\nCannot open infile\nClosing script\n$!\n";
  exit;
}

foreach my $line (<INFILE>)
{
    print "bsub -q $opts{q} \"samtools depth $opts{l} | awk \'{sum+=$3; sumsq+=$3*$3} END { print \"$line Average = \",sum/NR; print \"$line Stdev = \",sqrt(sumsq/NR - (sum/NR)**2)}\'";
}