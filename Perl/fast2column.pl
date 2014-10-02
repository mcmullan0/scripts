#!/usr/bin/perl
use strict;
use warnings;

# A 'Transpose' for fasta files (fasta > column)

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:o:', \%opts);
unless ($opts{i})
{
    print "\nA 'Transpose' for fasta files (fasta > column.csv)";
    print "\nConsider running fastchar.pl to remove character data?";
    print "\nEnter infile -i (produces at tempMM files)\nEnter outfile (prefix) -o\n\n";
    exit;
}

# Open file
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open file\nClosing script\n";
    exit;
}

my $NoSeqs = 0;
foreach my $line (<INFILE>)
{
    chomp $line;
    if ($line =~ m/^>/)
    {
        $NoSeqs++;
        open (OUTFILE, ">>$opts{o}-$NoSeqs.csv");
        print OUTFILE "$line,\n";
    }
    else
    {
        foreach my $base (split //, $line)
        {
            print OUTFILE "$base,\n"
        }
    }
}
close OUTFILE;
my $finalfilename = 'paste -d \'\0\' ';
for (my $i = 1; $i < ($NoSeqs+1); $i++)
{
    $finalfilename = "$finalfilename$opts{o}-$i.csv ";
}
$finalfilename = "$finalfilename \> $opts{o}.fas; rm $opts{o}-*";
system($finalfilename);





