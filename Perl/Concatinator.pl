#!/usr/bin/perl -w
use strict;
use warnings;

# Combines fasta files from multiple contigs
# Concatenates fasta sequences from each file
# Assumes that fasta sequences are in the same order in each file
# Assumes that the folder contains only fasta sequences and no subdirectories


# Ask for folder of files to be concatenated
print "\nEnter location/directory of infiles\n\n";
my $direction = <STDIN>;
chomp $direction;

# Ask for file name for the outfile:
print "\nEnter filename of outfile\n\n";
my $outfilename = <STDIN>;
chomp $outfilename;

# Open directory and store all filenames in @fastas
opendir (DIR, $direction) or die "\nCannot open directory\n$!\n\n";
my @fastas = readdir DIR;
closedir DIR;

# Open first fasta file after removal of directory elements and sort
shift (@fastas);
shift (@fastas);
my @sorted = sort @fastas;
@fastas = @sorted;
my $DirFasfile = "$direction/$fastas[0]";
open (FAS, $DirFasfile) or die "\nSorry,\nno cigar\n$!\n\n";
# Store each line in array
my @lines = <FAS>;
close FAS;
# Find all names and store in @lines array and remove whitspace
my $Gr8rthn = ">";
my @names = grep/$Gr8rthn/,@lines;
for (@names){
	s/\s+$//;
}

# For each file in DIR concatenate sequence
# First set up the array
open (FAS, $DirFasfile) or die "\nSorry,\nno cigar\n$!\n\n";
my @Concat = <FAS>;
for (@Concat){
	s/\s+$//;
}
my $reps = scalar(@fastas);
for (my $loop = 1; $loop < $reps; $loop++) {
	my $DirFasfile = "$direction/$fastas[$loop]";
	open (FAS, $DirFasfile) or die "\n$!\n\n";
	@lines = <FAS>;
	for (@lines){
		s/\s+$//;
	}
	my $stop = scalar(@Concat);
	for (my $j = 0; $j < $stop; $j++) {
		my $inter1 = "$Concat[$j]$lines[$j]";
		$Concat[$j] = "$inter1";
	}
}

my @Output;	# Final array
my $fastxt;	# Intermediary scalar for fasta data from @Concat
my $fasNo;	# Number to convert fast from $i in @Concat to $i @Output
my $nmeNo;	# Number to convert name from $i in @Concat to $i @Output
my @nmeout;	# arrey of all names in all fasta files
my $rep2 = scalar(@names);
for (my $i = 0; $i < $rep2; $i++) {
	$fasNo = $i * 2 + 1;
	$nmeNo = $i * 2;
	@Output[$i] = "$names[$i]\n$Concat[$fasNo]\n";
	@nmeout[$i] = "$Concat[$nmeNo]";
}

my $DirFasOutfile ="$direction/$outfilename";
open (OUTFAS, ">$DirFasOutfile");
print OUTFAS "@Output";
close (OUTFAS);
my $DirFasOutname ="$direction/$outfilename.nme";
open (OUTNME, ">$DirFasOutname");
print OUTNME "Here Check that all names are found in correct order\n@nmeout";
close (OUTNME);

