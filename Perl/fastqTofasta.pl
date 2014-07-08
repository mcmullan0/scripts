#!/usr/bin/perl
use strict;
use warnings;

# Converts fastq to fasta
# Assumes no line breaks in sequence lines

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:', \%opts);
if ($opts{i})
{
    
}
else
{
    print "\nEnter -i input fastq file\n\n";
    exit;
}



# Open file
unless (open(IN, $opts{i}))
{
    print "\nI Can't open fastq file\nClosing script\n";
    exit;
}

# IF, lines 1 and 2 print, 3 and 4 dispose
my $counter = 0;
my $arrow = '>';
foreach my $line (<IN>)
{
    $counter = $counter + 1;
    if ($counter == 1)
    {
        $line =~ s/.//;
        print "$arrow$line";
    }
    if ($counter == 2)
    {
        print "$line";
    }
    if ($counter == 4)
    {
        $counter = 0;
    }
}