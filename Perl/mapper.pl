#!/usr/bin/perl
use strict;
use warnings;

# first index your reference file "bwa index fasta.fas"
# run bwa-mem (map) | samtools view (sam>bam) | samtools rmdup (remove duplicates) | sort | index
# provide -q the cluster queue, the -f reference fasta, a file of -l R1 and a file of -r R2 reads, -o a file of a list of outfile names
# print a test bsub line instead of submtting to the cluster -p.  Use with '> filename' to check if your files match up

use Getopt::Std;


my %opts;
# accept input directory -d (argument)
getopts('q:f:l:r:b:e:s:n:p', \%opts);

# Collect all the flag data or end
unless ($opts{q} && $opts{l})
{
  print "\nHelp:\nRuns a pipeline taking three lists of files (in1, in2 and out prefix).  Select pipeline by commenting out.";
  print "\nThe first step (prior to this) is to index your reference file -bwa index fasta.fas\nAlso, source bwa-0.7.7; samtools-0.1.19\n";
  print "\nthis script will run:";
  print "\nbwa-mem (map) | samtools view (sam>bam) | samtools rmdup (remove duplicates) | sort | index\n or";
  print "\nbwa aln | bwa sampe | samtools view | samtools | rmdup | sort | index\n or";
  print "\nPull out R1 reads from a .bam and get depth - view -b -h -f 0x0040 allreads.bam > read1s.bam | depth\n or";
  print "\ntrim fq reads using sickle";
  print "\ninput:\n -q <cluster queue>\n -f <reference.fasta>\n a file of containing a list of filenames for";
  print "\n   -l <R1 reads>\n   -r <R2 reads>\n   -b <out-prefix>";
  print "\n -e <jobname> save lsf out to file instead of emailing";
  print "\n If you run sickle:\n   -s <base score>, trim bases < score\n   -n minimum length read";
  print "\n -p print test lines instead of submtting to the cluster.  Use with > filename\n\n";
  exit;
}
unless ($opts{b})
{
  print "\nEnter -b out-bam-prefix (a file containing a list of outfile names\n\n";
  exit;
}
my $emailout = ();
if ($opts{e})
{
  $emailout = "-o $opts{e}";
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
if ($opts{r})
{
  open(INFILE, $opts{r});
  foreach my $line (<INFILE>)
  {
    chomp $line;
    push(@read2list, "$line");
  }
  close INFILE;
}
my @readolist = ();
open(INFILE, $opts{b});
foreach my $line (<INFILE>)
{
  chomp $line;
  push(@readolist, "$line");
}
close INFILE;


for (my $i = 0; $i < $lineno; $i++)
{
# bwa mem | samtools view | samtools | rmdup | sort | index
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-r.bam; samtools sort -m 2000000000 $readolist[$i]-r.bam $readolist[$i]-r-s; samtools index $readolist[$i]-r-s.bam; rm $readolist[$i]-r.bam\"\n";
#  }
# else
#  {
#    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-r.bam; samtools sort -m 2000000000 $readolist[$i]-r.bam $readolist[$i]-r-s; samtools index $readolist[$i]-r-s.bam; rm $readolist[$i]-r.bam\"");
#  }
#
# bwa mem | samtools view | samtools | sort | index
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} $emailout \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] > $readolist[$i].sam; samtools view -S -b $readolist[$i].sam $readolist[$i].bam; samtools sort -m 2000000000 $readolist[$i].bam $readolist[$i]-s; samtools index $readolist[$i]-s.bam; rm $readolist[$i].bam\"\n";
#  }
# else
#  {
#    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] > $readolist[$i].sam; samtools view -S -b $readolist[$i].sam $readolist[$i].bam; samtools sort -m 2000000000 $readolist[$i].bam $readolist[$i]-s; samtools index $readolist[$i]-s.bam; rm $readolist[$i].bam\"");
#  }
#
# bwa aln | bwa sampe | samtools view | samtools | rmdup | sort | index
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} \"bwa aln $opts{f} $read1list[$i] > $read1list[$i].sai; bwa aln $opts{f} $read2list[$i] > $read2list[$i].sai; bwa sampe $opts{f} $read1list[$i].sai $read2list[$i].sai $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-aln-r.bam; samtools sort -m 2000000000 $readolist[$i]-aln-r.bam $readolist[$i]-aln-r-s; samtools index $readolist[$i]-aln-r-s.bam\"\n";
#  }
#  else
#  {
#    system("bsub -q $opts{q} \"bwa aln $opts{f} $read1list[$i] > $read1list[$i].sai; bwa aln $opts{f} $read2list[$i] > $read2list[$i].sai; bwa sampe $opts{f} $read1list[$i].sai $read2list[$i].sai $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-aln-r.bam; samtools sort -m 2000000000 $readolist[$i]-aln-r.bam $readolist[$i]-aln-r-s; samtools index $readolist[$i]-aln-r-s.bam\"");
#  }
#
# Pull out R1 reads from a .bam and get depth
  if ($opts{p})
  {
    print "bsub -q $opts{q} $emailout-[$i].lsf \"samtools view -b -h -f 0x0040 $read1list[$i] > $readolist[$i]_r1.bam; samtools depth $readolist[$i]_r1.bam > $readolist[$i]_r1.depth\"\n";
  }
  else
  {
    system("source samtools-0.1.19; bsub -q $opts{q} $emailout-[$i].lsf \"samtools view -b -h -f 0x0040 $read1list[$i] > $readolist[$i]_r1.bam; samtools depth $readolist[$i]_r1.bam > $readolist[$i]_r1.depth\"");
  }
#
# trim fq reads using prinseq   -This line has never been tested
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} $emailout \"prinseq -fastq $read1list[$i] -fastq2 $read2list[$i] -trim_qual_right 30 -trim_qual_window 3 -trim_qual_step 1 -min_len 120 -out_good $readolist[$i]\"\n";
#  }
#  else
#  {
#    system("source prinseq-0.20.3; bsub -q $opts{q} $emailout \"prinseq -fastq $read1list[$i] -fastq2 $read2list[$i] -trim_qual_right 30 -trim_qual_window 3 -trim_qual_step 1 -min_len 120 -out_good $readolist[$i]\"");
#  }
#
# trim fq reads using sickle
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} $emailout-$readolist[$i] \"sickle pe -f $read1list[$i] -r $read2list[$i] -t sanger -o $readolist[$i]-R1-trim$opts{s}.fq -p $readolist[$i]-R2-trim$opts{s}.fq -s $readolist[$i]single.fq -q $opts{s} -l $opts{n} -x\"\n";
#  }
#  else
#  {
#    system("source sickle-1.2; bsub -q $opts{q} $emailout-$readolist[$i] \"sickle pe -f $read1list[$i] -r $read2list[$i] -t sanger -o $readolist[$i]-R1-trim$opts{s}.fq -p $readolist[$i]-R2-trim$opts{s}.fq -s $readolist[$i]single.fq -q $opts{s} -l $opts{n} -x\"");
#  }
}
                                                                                                                                                                                                                                                                                                                                              