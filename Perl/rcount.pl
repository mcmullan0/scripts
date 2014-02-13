#!/usr/bin/perl -w
use strict;
use warnings;

# Finds the number of recombination events per contig.
# The input file is a modified RDP output file.
# In this case the file is 'Oliver_500_Contigs_RDPout.csv'

my $inflnme = "Oliver_500_Contigs_RDPout.csv";
unless (open(INFILE, $inflnme)){
  print "\nI Can't open Contig file\nClosing script\n$!\n";
  exit;
  }

# Ask for file name for the outfile:
my $outfilename = "rcounted.csv";
my $line = "";
my $contig = "CONTIG";
open(OUTFILE, ">$outfilename");
print OUTFILE "$line";
close(OUTFILE);

foreach $line (<INFILE>){
  $line =~ s/\s//g;
  my @title = split(',', $line);
  my $t1 = $title[0];
  if ($t1 = $contig){
    open(OUTFILE, ">>$outfilename");
    print OUTFILE "$t1\n";
    close(OUTFILE);
  }
#  open(OUTFILE, ">>$outfilename");
#  print OUTFILE "@title\n";
#  close(OUTFILE);
}

