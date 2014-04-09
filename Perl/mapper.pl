#!/usr/bin/perl
use strict;
use warnings;

# first index your reference file "bwa index fasta.fas"
# run bwa-mem (map) | samtools view (sam>bam) | samtools rmdup (remove duplicates) | sort | index
# provide -q the cluster que, the -f reference fasta, a file of -l R1 and a file of -r R2 reads, -o a file of a list of outfile names
# print a test bsub line instead of submtting to the cluster -p.  Use with '> filename' to check if your files match up

use Getopt::Std;


my %opts;
# accept input directory -d (argument)
getopts('q:f:l:r:o:p', \%opts);

# Collect all the flag data or end
unless ($opts{q})
{
  print "\nHelp:\nThe first step (prior to this) is to index your reference file -bwa index fasta.fas\nAlso, source bwa-0.7.7; samtools-0.1.19\n";
  print "\nthis script will run:";
  print "\nbwa-mem (map) | samtools view (sam>bam) | samtools rmdup (remove duplicates) | sort | index";
  print "\ninput:\n -q the cluster que\n -f reference fasta\n a file of containing a list of filenames for";
  print "\n  -l R1 reads\n  -r R2 reads\n  -o outfile names";
  print "\n -p print test lines instead of submtting to the cluster.  Use with > filename\n\n";
  exit;
}

unless ($opts{f})
{
  print "\nEnter -r reference.fas\n\n";
  exit;
}

unless ($opts{l})
{
  print "\nEnter -l read1-file\n\n";
  exit;
}
unless ($opts{r})
{
  print "\nEnter -r read2-file\n\n";
  exit;
}

unless ($opts{o})
{
  print "\nEnter -o outfile (a file containing a list of outfile names\n\n";
  exit;
}

# Open read files and outfiles containing the names of the files and load them into arrays
my $lineno = 0;           # A line counter for the for loop below
my @read1list = ();
open(INFILE, $opts{l});
foreach my $line (<INFILE>)
{
  chomp $line;
  push(@read1list, "$line");
  $lineno = $lineno+1;
}
close INFILE;

my @read2list = ();
open(INFILE, $opts{r});
foreach my $line (<INFILE>)
{
  chomp $line;
  push(@read2list, "$line");
}
close INFILE;

my @readolist = ();
open(INFILE, $opts{o});
foreach my $line (<INFILE>)
{
  chomp $line;
  push(@readolist, "$line");
}
close INFILE;


for (my $i = 0; $i < $lineno; $i++)
{
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-rmdup.bam; samtools sort -m 2000000000 $readolist[$i]-rmdup.bam $readolist[$i]-rmdup-sorted; samtools index $readolist[$i]-rmdup-sorted.bam\"\n";
#  }
#  else
#  {
#    system("bsub -q $opts{q} \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-rmdup.bam; samtools sort -m 2000000000 $readolist[$i]-rmdup.bam $readolist[$i]-rmdup-sorted; samtools index $readolist[$i]-rmdup-sorted.bam\"");
#  }
  if ($opts{p})
  {
    print "bsub -q $opts{q} \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - > $readolist[$i].bam; samtools sort -m 2000000000 $readolist[$i].bam $readolist[$i]-sorted; samtools index $readolist[$i]-sorted.bam\"\n";
  }
  else
  {
    system("bsub -q $opts{q} \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - > $readolist[$i].bam; samtools sort -m 2000000000 $readolist[$i].bam $readolist[$i]-sorted; samtools index $readolist[$i]-sorted.bam\"");
  }
}





#system("bsub -q $que 'cp test test2'");


   