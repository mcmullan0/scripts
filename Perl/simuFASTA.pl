#!/usr/bin/perl -w
use strict;
use warnings;

# Takes simuPOP output, sequences in CSV format and converts them into fasta.
# The command used to get sequences within simupop is:
#	sample = drawRandomSample(pop, sizes=[3]*10)
#	sim.utils.saveCSV(sample, filename='SampleDataTEST40000.csv'),

# Ask whichfile and get file else close:
print "\nEnter filename for simu.csv > Fasta\n\n";
my $flnme = <STDIN>;
chomp $flnme;
unless (open(FlNme, $flnme)){
  print "\nI Can't open simu.csv file\nClosing script\n";
  exit;}
my $i;
for ($i = 0; $i < 4; $i ++){
  chop $flnme;
}
my $fas = '.fas';
my $Output = "$flnme$fas";
my $clear = "";				# Clear the outfile as later I append
open(OUTFILE, ">$Output");
print OUTFILE "$clear";
close(OUTFILE);

print "\nHow many individuals did you sample from each population?\n";
my $nummax = <STDIN>;
chomp $nummax;

# Saving sequence names using a 'name' and a pop flag P
print "\nWhat shall I call these sequences?\n\n";
my $LgrTn = '>';
my $seq = <STDIN>;
chomp $seq;
my $UndScr ='_';
$seq = "$seq$UndScr";
my $Ind = '_Ind_';
my $No = 0;
my $Pop = 'P';
my $a = 'a';
my $b = 'b';				# Px_Ind_ya or Px_Ind_yb
my $counter = -1;			# Clicks pop number ($num) up by 1
my $num = 1;
my $line = <FlNme>;			# Dispose of header line

#Load subsequent lines into array after removing whitespace
foreach $line (<FlNme>){
  $line =~ s/\s//g;
  $No = $No+1;
  $counter = $counter+1;
  if ($counter > $nummax){
    $counter = 1;
  }
  if ($counter == $nummax){
    $num = $num+1;
  }
  my @fasta12 = split(',', $line);
  # Split fasta12 into fasta1 (odd array entries) and fasta2 (even array entries).
  my $nuc;				# copies nucleotides to fasta1 or fasta2
  my @fasta1;
  my @fasta2;
  my $length = scalar(@fasta12);
  for ($i = 0; $i<$length; $i++){	# Check that I don't need to add 1 to $length
    my $oddevn = $i % 2;		# Remainder 0=even (or zero) remainder 1=odd
    $nuc = $fasta12[$i];
    if ($oddevn == 0){
      push(@fasta1, $nuc);
    }
    else{
          push(@fasta2, $nuc);
    }
  }
  my $fasnme1 = "$LgrTn$seq$Pop$num$Ind$No$a";
  my $fasnme2 = "$LgrTn$seq$Pop$num$Ind$No$b";
  shift @fasta1;			# Removes first element of array (either sex or affect)
  shift @fasta2;
  open(OUTFILE, ">>$Output");
  print OUTFILE "$fasnme1\n@fasta1\n$fasnme2\n@fasta2\n";
  close(OUTFILE);
}


















