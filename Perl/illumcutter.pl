#!/usr/bin/perl -w
use strict;
use warnings;

# Reduces the number of sequences in a .fastq file

# Get fastq file and outfule
print "\nEnter file and path\n\n";
my $infile = <STDIN>;
chomp $infile;
print "\nEnter outfilename\n";
my $outfile = <STDIN>;
chomp $outfile;
unless (open(INFILE, $infile)){ 
  print "\nI Can't open the fastq file\nClosing script\n$!\n";
  exit;}

# Sample reads from the beggining or end
BEGINEND:
print "\nWould you like to take reads from:\nthe beggining (1)\nthe end (2)\nof the fastq file?\n";
my $input = <STDIN>;
chomp $input;
if (($input <1) || ($input >2)){
  goto BEGINEND;}

# Count the number of reads and find out how many to sample
my $lines = `wc -l < $infile`;
chomp $lines;
my $reads = $lines/4;
print "\nThere are $lines lines making $reads reads in this file.\nHow many READS would you like to use in your analyses?\n";
my $newreads = <STDIN>;
chomp $newreads;
my $newlines = $newreads*4;
my $reduce = $newreads/$reads;
print "\nThe new file ($outfile) will be $reduce the size of the old file\n";
my $spacer = "_";
$outfile = $outfile.$spacer.$reduce;
print "Outfile name = $outfile\n\n";

# Generate outfile of new reduced size
my $clear = "";
open (OUTFILE, ">$outfile");
print OUTFILE "$clear";
close OUTFILE;
open (OUTFILE, ">>$outfile");
my $endstart = 0;
my $counter = 0;			# Take reads from line 0
if ($input == 2){			# unless input = 2.
  $endstart = ($lines - $newlines);}

if ($input == 1){				# If from beginning
  while ($counter < $newlines){			# For each read
    my $line = <INFILE>;
    print OUTFILE "$line";
    $counter = $counter + 1;}
  }
else{						# else from end
  while ($counter < $lines){			# For each read
    my $line = <INFILE>;
    if ($counter >= $endstart){
      print OUTFILE "$line";}
    $counter = $counter + 1;}
  }
close(INFILE);
close(OUTFILE);
