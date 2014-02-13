#!/usr/bin/perl
use strict;
use warnings;

# Counts the number of nucleotide ambigeous sites in a fasta file (for each seq)
# Replaces the ambigious sites for n's (-n)
use File::Path;

# Check directory and make a list of fasta files (remove hidden files)
use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('d:o:nfr', \%opts);
unless ($opts{d})
{
    print "\n\nDONT put this script in the same directory as your fasta files, put it above that directory\n\n";
    print "\nCounts the number of nucleotide ambigeous sites in a fasta file (for each seq)";
    print "\nReplaces the ambigious sites for n's (-n)";
    print "\nEnter -d  directory of fastas (full path pwd)\nEnter an outfile name -o\n";
    print "\nYou can also check the script finds all your fasta files by running the -f flag\n";
    print "\nuse -r to remove the previous directory if you run this program repeatedly\n\n";
    exit;
}

my $directory = "$opts{d}/remove_amb";
if ($opts{r})
{
    rmtree ("$directory", 0, 0);
}
# Collect fasta files in @files
opendir (DIR, $opts{d}) or die "\nCannot open directory\n$!\n\n";
my @files = readdir DIR;
closedir DIR;
# Remove any hidden files/directory names from @files -> @fastas
my @fastas = ();
foreach my $files (@files)      # push files to @fastas unless start with .
{
    push(@fastas, $files) unless("$files" =~ /^\./);
}

mkdir $directory;


# Check if you have all the files you want
if ($opts{f})
{
    print "\nAre these all your fastas you want to include?\nFastas = @fastas\n\n";
    exit;
}

my $line = ();
my @info = ();
my $bases = ();
my $title = ();
my $replace = 0;
if ($opts{n})
{
    $replace = 1;
}
open (OUTFILE, ">$directory/$opts{o}");
print OUTFILE "";
close OUTFILE;
open (OUTFILE, ">>$directory/$opts{o}");
print OUTFILE "Sequence,M,R,W,S,Y,K,V H D or B,n,Total,";

foreach my $fastas (@fastas)
{
    open (INFILE, "<$opts{d}/$fastas");
    if ($opts{n})
    {
        open (OUTFAS, ">$opts{d}/remove_amb/$fastas.n.fas");
    }
    foreach $line (<INFILE>)
    {
        my $nline = ();
        if ($line =~ m/^>/)
        {
            chomp $line;
            $line = "$line,";
            $title = $line;
        }
        else
        {
            chomp $line;
            $nline = $line;                     # Used to replace n's
            my $spc = $line =~ tr/\-//;
            $bases = length($line) - $spc;
            my $m = $line =~ tr/m//;
            my $r = $line =~ tr/r//;
            my $w = $line =~ tr/w//;
            my $s = $line =~ tr/s//;
            my $y = $line =~ tr/y//;
            my $k = $line =~ tr/k//;
            my $M = $line =~ tr/M//;
            my $R = $line =~ tr/R//;
            my $W = $line =~ tr/W//;
            my $S = $line =~ tr/S//;
            my $Y = $line =~ tr/Y//;
            my $K = $line =~ tr/K//;
            my $n = $line =~ tr/n//;
            my $N = $line =~ tr/N//;
            my $v = $line =~ tr/v//;
            my $h = $line =~ tr/h//;
            my $d = $line =~ tr/d//;
            my $b = $line =~ tr/b//;
            my $V = $line =~ tr/V//;
            my $H = $line =~ tr/H//;
            my $D = $line =~ tr/D//;
            my $B = $line =~ tr/B//;
            my $eM = $m + $M;
            my $aR = $r + $R;
            my $Wu = $w + $W;
            my $eS = $s + $S;
            my $wY = $y + $Y;
            my $Ky = $k + $K;
            my $eN = $n + $N;
            my $triplets = $v + $h + $d + $b + $V + $H + $D + $B;
            $eM = "$eM,";
            $aR = "$aR,";
            $Wu = "$Wu,";
            $eS = "$eS,";
            $wY = "$wY,";
            $Ky = "$Ky,";
            $eN = "$eN,";
            $triplets = "$triplets,";
            my $revtitle = reverse($title);
            chomp $revtitle;
            $title = reverse($revtitle);
            push (@info, ($title, $eM, $aR, $Wu, $eS, $wY, $Ky, $triplets, $eN, $bases));
            if ($opts{n})
            {
                $nline =~ tr/m, r, w, s, y, k, M, R, W, S, Y, K, v, h, d, b, V, H, D, B/n/;
                print OUTFAS "$title$bases\n$nline\n";
            }
        }
        print OUTFILE "\n@info";
        @info = ();
    }
}