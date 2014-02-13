#!/usr/bin/perl
use strict;
use warnings;

# Returns a line of a file
# sed -n '52p' ana_c1.fas
# the 52nd line of ana.c1.fas

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:l:', \%opts);
unless ($opts{i})
{
    print "\nReturns a line (-l) of a file";
    print "\nEnter -i input file\n\n";
    exit;
}
unless ($opts{l})
{
    print "\nEnter -l line number to return a line\n\n";
    exit;
}


# Open file
unless (open(IN, $opts{i}))
{
    print "\nI Can't open file\nClosing script\n";
    exit;
}
my $counter = 0;
foreach my $line (<IN>)
{
    $counter = $counter + 1;
    if ($counter == $opts{l})
    {
        chomp $line;
        print "$line";
    }
}
if ($counter < $opts{l})
{
    print "There are fewer than $opts{l} lines in this file\nFile = $counter lines\n";
}
print "\n";
close (IN);
