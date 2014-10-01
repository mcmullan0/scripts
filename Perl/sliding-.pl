#!/usr/bin/perl
use strict;
use warnings;


# Run after fast2column.pl so that you can iterate through rows of base 1, 2, 3, etc.
# This script contains a usful tally counter (hash) you might want to use again in the future

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:', \%opts);

if ($opts{i})
{
    if (open(INFILE, $opts{i}))
    {
        foreach my $line (<INFILE>)
        {
            my %polyM= ();              # Open a hash table for polymorphisms
            chomp $line;
            if ($line =~ m/^>/)
            {
                print "Population level polyM data for:\n$line\n";
            }
            else
            {
                my @columns = split(/,/, $line);
                foreach (@columns)
                {
                    $polyM{$_}++;
                }
                my $printline = "";
                foreach (reverse sort {$polyM{$a} <=> $polyM{$b}} keys %polyM)
                {
                    $printline = "$printline$_,$polyM{$_},";
                }
                print "$printline\n";
            }
        }
    }
    else
    {
        print "\nI Can't open file\nClosing script\n\n";
        exit;
    }
}
else
{
    print "\nThe Second sliding window script designed to print a hash table per row of data";
    print "\nRun after fast2column.pl so that you can iterate through rows of base 1, 2, 3, etc.";
    print "\nConsider running fastchar.pl to remove character data from the fasta?";
    print "\nEnter infile -i (produces at tempMM files)\nEnter outfile (prefix) -o\n\n";
    exit;
}

# Headers for next stage
my $headers = "MSNP,MSNPNo,mSNP,mSNPNo,Hetz,hNo,Total";    #Major SNP, Major SNP number,minor SNP,minor SNP number,Hetz SNP, Hetz SNP number, total