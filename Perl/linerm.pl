#!/usr/bin/perl
use strict;
use warnings;

# Removes every other line.  Provide infile (-i) and outfile (-o)

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:o:k:', \%opts);
if ($opts{i})
{
    unless (open(INFILE, $opts{i}))
    {
        print "\n\nCannot open infile\nClosing script\n\n$!";
        exit;
    }
}
else
{
    print "\nRemoves every other line.  Provide infile (-i) and outfile (-o)";
    print "\nProvide -k 1 (keep 1, 3, 5...) -r 2 (keep 2, 4, 6...)\n\n";
    exit;
}

open (OUTFILE, ">$opts{o}");
print OUTFILE "";
close OUTFILE;
open (OUTFILE, ">>$opts{o}");

my $counter = 0;
foreach my $line (<INFILE>)
{
    $counter = $counter + 1;
    if ($counter % $opts{k} == 0)
    {
        print OUTFILE "$line";
    }
}