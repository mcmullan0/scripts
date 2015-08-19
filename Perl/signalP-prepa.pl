#!/usr/bin/perl
use strict;
use warnings;

# Pulls out each gene and its longest mRNA from Hymenoscyphus_fraxineus_v2.0_annotation.grep23.gff3

use Getopt::Std;
my %opts;
getopts('i:', \%opts);

unless ($opts{i})
{
    print "\n######################################## signalP-prepa ###########################################";
    print "\nPulls out each 'gene' and its longest 'mRNA' transcript from .gff3.";
    print "\n-i Provide .gff3 file";
    print "\n##################################################################################################\n\n";
    exit;
}

# Load first line and save in the geneline holder
# Run through all lines (process mRNA lines) printing on subsequent 'gene' lines
# Iterate one more time for last line (as last line is not followed by 'gene')

my $geneline;   # A holder for the line if it is a "gene" line
my @mrnalines;  # A holder for one or more mRNA lines (there can be multiple)
my $winner;     # A holder for the longest mRNA transctipt
my $firstline = 1;
my $infile = $opts{i};
open(GFFFILE, "<$infile") or die "cannot open fasta < $infile: $!";
foreach my $line (<GFFFILE>)
{
    if ($line ne "#")
    {
        chomp $line;
        my @separate = split /\s+/, $line;
        if ($firstline == 1)        # If is the first line of the file load it into the geneline holder
        {
            $geneline = $line;
            $firstline = 0;
        }
        else
        {
            if ($separate[2] eq "gene")
            {
                my $multtranscript = scalar(@mrnalines);
                if ($multtranscript > 1)
                {
                    # Just in case there are more than 2 transcripts
                    my $firstforloop = 1;
                    $winner = ();
                    for ( my $i = 1; $i < $multtranscript; $i++)    # For each mRNA transcript compare with previous to find largest
                    {
                        my $h = $i-1;
                        if ($firstforloop == 1)     # In the first loop find the winner (in subsequent loops use winner from previous loop)
                        {
                            $firstforloop = 0;
                            my @first = split /\s+/, $mrnalines[$h];
                            my @second = split /\s+/, $mrnalines[$i];
                            my $flength = $first[4] - $first[3];
                            my $slength = $second[4] - $second[3];
                            if ($flength >= $slength)
                            {
                                $winner = $mrnalines[$h];
                            }
                            else
                            {
                                $winner = $mrnalines[$i];
                            }
                        }
                        else
                        {
                            my @first = split /\s+/, $winner;
                            my @second = split /\s+/, $mrnalines[$i];
                            my $flength = $first[4] - $first[3];
                            my $slength = $second[4] - $second[3];
                            if ($slength > $flength)
                            {
                                $winner = $mrnalines[$i];
                            }
                        }
                    }
                print "$geneline\n$winner\n";
                }
                else
                {
                    print "$geneline\n$mrnalines[0]\n";
                }
                @mrnalines = ();
                $geneline = $line;
            }
            elsif ($separate[2] eq "mRNA")
            {
                push @mrnalines, $line;
            }
        }
    }
}

# One lst iteration for the last line:

my $multtranscript = scalar(@mrnalines);
if ($multtranscript > 1)
{
    # Just in case there are more than 2 transcripts
    my $firstforloop = 1;
    $winner = ();
    for ( my $i = 1; $i < $multtranscript; $i++)    # For each mRNA transcript compare with previous to find largest
    {
        my $h = $i-1;
        if ($firstforloop == 1)     # In the first loop find the winner (in subsequent loops use winner from previous loop)
        {
            $firstforloop = 0;
            my @first = split /\s+/, $mrnalines[$h];
            my @second = split /\s+/, $mrnalines[$i];
            my $flength = $first[4] - $first[3];
            my $slength = $second[4] - $second[3];
            if ($flength >= $slength)
            {
                $winner = $mrnalines[$h];
            }
            else
            {
                $winner = $mrnalines[$i];
            }
        }
        else
        {
            my @first = split /\s+/, $winner;
            my @second = split /\s+/, $mrnalines[$i];
            my $flength = $first[4] - $first[3];
            my $slength = $second[4] - $second[3];
            if ($slength > $flength)
            {
                $winner = $mrnalines[$i];
            }
        }
    }
print "$geneline\n$winner\n";
}
else
{
    print "$geneline\n$mrnalines[0]\n";
}

close(GFFFILE);