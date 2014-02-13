#!/usr/bin/perl
use strict;
use warnings;

# Adds a name designation onto the existing name of each seq in a fasta

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:t:b', \%opts);
unless ($opts{i})
{
    print "\nAdds a name designation onto the existing name of each seq in a fasta";
    print "\nEnter -i input fasta -t text and (optional) -b for beggining of title line (after >)\n\n";
    exit;
}
unless ($opts{t})
{
    print "\nEnter -t text to add to each title line\n\n";
    exit;
}

# Open file
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open fasta file\nClosing script\n";
    exit;
}
my $rpa = '>';
my $beggining = 0;
if ($opts{b})
{
    $beggining = 1;
}
foreach my $line (<INFILE>)
{
    if ($line =~ m/^>/)
    {
        chomp $line;
        if ($beggining == 1)
        {
            my $eltit = reverse($line);
            chop $eltit;
            $line = reverse($eltit);
            $line = "$rpa$opts{t}$line\n";
        }
        else
        {
            $line = "$line$opts{t}\n";
        }
    }
    print "$line"
}