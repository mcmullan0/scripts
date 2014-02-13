#!/usr/bin/perl
use strict;
use warnings;

# Returns an expression from each line (if present will list or list a blank if missing)

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:x:', \%opts);
unless ($opts{i})
{
    print "\nReturns an expression from each line (if present will list or list a blank if missing)";
    print "\nEnter -i input fasta\nEnter -x regex to search for (in single quotes)\n\n";
    exit;
}

# Open file
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open the file\nClosing script\n";
    exit;
}

foreach my $line (<INFILE>)
{
    my $blankline = "\n";
    my $querie = "";
    if ($line =~ m/$opts{x}/is)
    {
        $querie = $1;
    }
    my $expression = "$querie$blankline";
    print "$expression";
}

# Notes
# (\d+)\s*_length will pull out the digit before _length