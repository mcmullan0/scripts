#!/usr/bin/perl
use strict;
use warnings;

# Adds a name designation onto the existing name of each seq in a fasta

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:t:bf', \%opts);
unless ($opts{i})
{
    print "\nAdds a name designation onto the existing name of each seq in a fasta";
    print "\nEnter -i input fasta\n-t text or filename\n if -t filename for different name for each line use -f";
    print "\n CHECK that filenames match using grep '>' | paste - filenames.txt";
    print "\n-b (optional) for beggining of title line (after >)\n\n";
    exit;
}
unless ($opts{t})
{
    print "\nEnter -t text to add to each title line\n\n";
    exit;
}
# if there is a name file, open and load into @textfile
my @textfile = ();
if ($opts{f})
{
    open(NAMES, "<$opts{t}") or die $!;
    foreach my $line (<NAMES>)
    {
    chomp $line;
    push(@textfile, "$line");
    }
}

# Open file count lines for for loop below (I don't think I can use a foreach as I need to $i for the @textfile and I'm tired and I want to go home)
my $lines=0;
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open fasta file\nClosing script\n";
    exit;
}
$lines++ while (<INFILE>);
close INFILE;

open(INFILE, "<$opts{i}") or die $!;

my $rpa = '>';
my $beggining = 0;
if ($opts{b})
{
    $beggining = 1;
}
for (my $i = 0; $i < $lines; $i++)
{
    my $line = (<INFILE>);
    my $j=$i/2+0.5;
    if ($line =~ m/^>/)
    {
        chomp $line;
        if ($beggining == 1)
        {
            my $eltit = reverse($line);
            chop $eltit;
            $line = reverse($eltit);
            if ($opts{f})
            {
                $line = "$rpa$textfile[$j]$line\n";
            }
            else
            {
                $line = "$rpa$opts{t}$line\n";
            }
        }
        else
        {
            if ($opts{f})
            {
                $line = "$line$textfile[$j]\n";
            }
            else
            {
                $line = "$line$opts{t}\n";
            }
        }
    }
    print "$line";
}