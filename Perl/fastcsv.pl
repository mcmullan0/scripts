#!/usr/bin/perl
use strict;
use warnings;

# Transpose fasta sequences into columns for analysis in stats programs

use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('i:', \%opts);

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
    print "\nTranspose fasta sequences into columns for analysis in stats programs";
    print "\nRemove carriag returns from within the sequence";
    print "\n\nEnter -i filename.fas\n\n";
    exit;
}

my @column = ();
foreach my $line (<INFILE>)
{
    if ($line =~ m/^>/)
    {
        chomp $line;
        push (@column, $line);
    }
    else
    {
        my @sequence = split (//,$line);
        push (@column, @sequence);
    }
}
foreach my $column (@column)
{
    print "$column,\n";
}
print "\n";