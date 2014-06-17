#!/usr/bin/perl
use strict;
use warnings;

# Takes fasta filnames and cuts them to length x
# Could by used before concatenator2.pl
# Use fastaCutter.pl to trim sequence names in situations where names are different by a sting after the name
#  e.g. >Fasta_spA_Prot1 and Fasta_spA_Prot2 could be reduced to Fasta_spA in both files so that they can be
#  concatenated.

use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('i:x:', \%opts);
if ($opts{i})
{
    open(FAS, "<$opts{i}") or die("Could not open log file.");
#    my $temp = "temporaryfile01.txt";
#    open(FAS2, ">$temp");
#    my $clear = "";
#    print FAS2 "$clear";
#    close FAS2;
#    open(FAS2, ">>$temp");
    
    foreach my $line (<FAS>)
    {
        if ($line =~ /^>/)
        {
            my $len = length($line);
            while ($len > $opts{x})
            {
                chop $line;
                $len = length($line);
            }
            print "$line\n";
        }
        else
        {
            print "$line\n";
        }
    }
    close (FAS);
}
else
{
    print "\nTakes fasta filnames and cuts them to length x";
    print "\n\nEnter input fasta file (-i)\nEnter desired name length (-x)\n";
}
print "\n";
