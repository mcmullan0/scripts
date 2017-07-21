#!/usr/bin/perl -w
use strict;
use warnings;

# strips all sequences shorter than -l from a fasta file

use Getopt::Std;
my %opts;
# accept input file -i (argument)
# what is the minimum length you want
getopts('i:l:p', \%opts);
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
    print "\nstrips all sequences shorter than -l from a fasta file";
    print "\nEnter -i filename\nState minimum length of sequence (includes last whtspc)\nOr -p instead of -l to print seq lengths\n\n";
    exit;
}
unless ($opts{l} || $opts{p})
{
    print "\nState minimum length of sequence\n\n";
    exit;
}
if ($opts{l})
{
    my $title = ();
    foreach my $line (<INFILE>)
    {
        if ($line =~ m/^>/)
        {
            $title = $line;
        }
        my $length = length($line);
        if ($length >= $opts{l})
        {
            print "$title$line";
        }
    }
}
else
{
    foreach my $line (<INFILE>)
    {
        if ($line !~ m/^>/)
        {
            my $length = length($line);
            print "$length\n";
        }
    }
}
