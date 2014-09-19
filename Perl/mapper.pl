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
  print "\ninput:\n -q <cluster queue>\n -e <jobname> save lsf out to file instead of emailing\n -f <reference.fasta> (bwa index; samtools faidx before running this script)";
  print "\nA file of containing a list of filenames for";
  print "\n   -l <R1 reads>\n   -r <R2 reads>\n   -b <out-prefix>";
  print "\n If you run sickle:\n   -s <base score>, trim bases < score\n   -n minimum length read";
  print "\n -p print test lines instead of submtting to the cluster.  Use with > filename\n\n";
  exit;
}
unless ($opts{b})
{
  print "\nEnter -b out-bam-prefix (a file containing a list of outfile names\n\n";
  exit;
}
my $emailout = "$opts{e}";
my $bsubemailout = "$opts{e}/";
unless ($opts{p})
{
  if ($opts{e})
  {
    unless(mkdir $opts{e})
    {
      die "Unable to create $opts{e}\n$!";
    }
    $emailout = "-o $opts{e}/$opts{e}";
  }
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
# bwa mem | samtools -view | -sort | -rmdup | -index
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} -o $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort -@ 4 -m 4G - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s\"\n";
#  }
# else
#  {  
#    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort -@ 4 -m 4G - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s\"");
#  }
#
#
# mem | samtools -view | -sort | -rmdup | -index; then manual combined mpileup 
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} -o $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s.bam\"\n";
#  }
# else
#  {
#    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s.bam\"");
#  }
#
# mem | samtools -view | -sort | -rmdup | -index | -mpileup | bcftools view for raw .bcf
  if ($opts{p})
  {
    print "bsub -q $opts{q} -o $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s.bam; samtools mpileup -uf $opts{f} $readolist[$i]-sr.bam | bcftools view -bvcg - > $readolist[$i]-sr.raw.bcf\"\n";
  }
 else
  {
    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s.bam; samtools mpileup -ugf $opts{f} $readolist[$i]-sr.bam | bcftools view -bvcg - > $readolist[$i]-sr.raw.bcf\"");
  }
#
#
# bwa aln | bwa sampe | samtools view | samtools | rmdup | sort | index -you might want to change this to put the sort before rmdup
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} \"bwa aln $opts{f} $read1list[$i] > $read1list[$i].sai; bwa aln $opts{f} $read2list[$i] > $read2list[$i].sai; bwa sampe $opts{f} $read1list[$i].sai $read2list[$i].sai $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-aln-r.bam; samtools sort -m 2000000000 $readolist[$i]-aln-r.bam $readolist[$i]-aln-r-s; samtools index $readolist[$i]-aln-r-s.bam\"\n";
#  }
#  else
#  {
#    system("bsub -q $opts{q} \"bwa aln $opts{f} $read1list[$i] > $read1list[$i].sai; bwa aln $opts{f} $read2list[$i] > $read2list[$i].sai; bwa sampe $opts{f} $read1list[$i].sai $read2list[$i].sai $read1list[$i] $read2list[$i] | samtools view -S -b - | samtools rmdup - $readolist[$i]-aln-r.bam; samtools sort -m 2000000000 $readolist[$i]-aln-r.bam $readolist[$i]-aln-r-s; samtools index $readolist[$i]-aln-r-s.bam\"");
#  }
#
# bwa mem | samtools -view | -sort | -rmdup | -index | -Pull out R1 reads from a .bam | -depth
#  if ($opts{p})
#  {
#    print "bsub -q $opts{q} -o $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort -@ 4 -m 4G - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s; samtools view -b -h -f 0x0040 $readolist[$i]-sr.bam > $readolist[$i]-sr_r1.bam; samtools index $readolist[$i]-sr_r1.bam; samtools depth $readolist[$i]-sr_r1.bam > $readolist[$i]-sr_r1.depth; rm $readolist[$i]-s*.bam*\"\n";
#  }
#  else
#  {
#    system("source samtools-0.1.19; source bwa-0.7.7; bsub -q $opts{q} $emailout-[$i].lsf \"bwa mem -t 8 $opts{f} $read1list[$i] $read2list[$i] | samtools view -Sb - | samtools sort -@ 4 -m 4G - $readolist[$i]-s; samtools rmdup $readolist[$i]-s.bam $readolist[$i]-sr.bam; samtools index $readolist[$i]-sr.bam; rm $readolist[$i]-s; samtools view -b -h -f 0x0040 $readolist[$i]-sr.bam > $readolist[$i]-sr_r1.bam; samtools index $readolist[$i]-sr_r1.bam; samtools depth $readolist[$i]-sr_r1.bam > $readolist[$i]-sr_r1.depth; rm $readolist[$i]-s*.bam*\"");
#  }
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
#if ($opts{p})
#{
#  print "\nbsub -w \'ended($bsubemailout*)\' -q $opts{q} \"echo $emailout jobs are finsihed; echo the number of \'fail\'s is; grep \'fail\' $emailout/* | wc -l; echo the number of \'exit\'s is; grep \'exit\' $emailout/* | wc -l\"";
#}
#else
#{
#  system("bsub -w \'ended($bsubemailout*)\' -q $opts{q} \"echo $emailout jobs are finsihed; echo the number of \'fail\'s is; grep \'fail\' $emailout/* | wc -l; echo the number of \'exit\'s is; grep \'exit\' $emailout/* | wc -l\"");
}
