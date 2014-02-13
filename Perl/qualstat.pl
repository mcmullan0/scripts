#!/usr/bin/perl -w
use strict;
use warnings;

# The mean for each read from a qual file.
# Use fastq_to_fasta.py to convert fastq to fasta.qual

use Getopt::Std;
{
    my %opts;
    # accept input file -i (argument)
    # accept genome size -g (argument)
    getopts('i:', \%opts);
    if ($opts{i})
    {
        unless (open(INFILE, $opts{i}))
        {
            print "\n\nCannot open infile\nClosing script\n$!\n";
            exit;
        }
        print "$opts{i}\n";
    }
    else
    {
        print "\nEnter -i filename of .qual file\nuse fastq_to_fasta.pl to generate .qual\n\n";
        exit;
    }
}
my @means = ();             # Stores the mean for each read
my @bpscores = ();          # Stores the scores for reads for each line
my @lineall = ();           # Stores the concatenated lines from pbscores over multiple lines
my $line = (<INFILE>);      # Skips the first title line

# These loops use the folowing title line (>) to compute the preceeding qual scores.
# I rempeat the first it loop at the end to get the final quals as there are no more >
foreach $line (<INFILE>)
{
    if ($line =~ m/^>/)
    {
        $line = ();
        my $div = scalar(@bpscores);
        my $mean = (eval (join '+', @bpscores))/$div;
        push (@means, $mean);
        @bpscores = ();
    }
    else
    {
        $line =~ s/\s/,/g;
        my @lineall = split(/,/, $line);
        push (@bpscores, @lineall);
    }
}
my $div = scalar(@bpscores);
my $mean = (eval (join '+', @bpscores))/$div;
push (@means, $mean);

print "@means\n";

print "\n";