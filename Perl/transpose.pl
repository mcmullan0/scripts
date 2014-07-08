#!/usr/bin/perl -w
use strict;
use warnings;

# Ask whichfile and get file else close:
print "\nEnter filename for Transpose\n\n";
my $TrnsPsfilename = <STDIN>;
chomp $TrnsPsfilename;
unless (open(TnsPs, $TrnsPsfilename)){
	print "\nCannot open Transpose file\nClosing script\n";
	exit;}
my $fas = '.fas';
my $Output = "$TrnsPsfilename$fas";

#my $TrnsPsfilename = 'Tt.csv';
#open(TnsPs, $TrnsPsfilename);


# Load in header data (1st line) and add > to each element
my $line = <TnsPs>;
$line =~ s/,/,>/g;			# add > to all names (except first)
my @header = split(',', $line);
my $symb = ">";				# add > to first name
my $header1 = $header[0];
my $symbHead1 = "$symb$header1";
$header[0] = "$symb$header1";
my $column = scalar(@header);
print "\nThere are $column columns of data\n";
print "\nOutput filename is: $TrnsPsfilename$fas\n\n";

# Load sequence data into first 'fasta' line to start array
$line = <TnsPs>;
my @fasta = split(',', $line);
# Loop next lines to add to each scalar of the fasta array
foreach $line (<TnsPs>){			# For each line
	my @addlne = split(',', $line);		# create array
	for (my $i = 0; $i < $column; $i++){	# for each array element
		my $Fele = $fasta[$i];		# take the corresponding Fasta element
		my $Lele = $addlne[$i];		# take the corresponding addline element
		my $FLele = "$Fele$Lele";	# combine them into FLele
		$fasta[$i] = $FLele;}		# put FLele into corresponding fasta element
	}
$fasta[$column-1] =~ s/\s//g;		# Remove whitespace
$header[$column-1] =~ s/\s//g;		# Remove whitespace
for (my $i = 0; $i < $column; $i++){
	my $Hele = $header[$i];
	my $Fele = $fasta[$i];
	my $HFele = "$Hele\n$Fele\n";
	$header[$i] = "$HFele";}

open(OUTFILE, ">$Output");
print OUTFILE "@header";
close(OUTFILE);
