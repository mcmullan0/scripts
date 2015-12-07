#!/usr/bin/perl
use strict;
use warnings;

# Counts all the characters in a fasta file
# Does not count characters in the title line

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:sc', \%opts);
unless ($opts{i})
{
    print "\nCount all the characters in a fasta file";
    print "\nDoes not count characters in the title line";
    print "\nEnter infile -i\nEnter -s if you want to keep a file of all characters in the sequence line (tempfile2.MM -not just nucleotides)";
    print "\nEnter -c to output a file of only upercase secuence\n\n";
    exit;
}

# Open file
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open file\nClosing script\n";
    exit;
}

my $temporyfile = 'tempfile.MM'; # A tempory file into which I copy all sequence lines
open (OUTFILE, ">$temporyfile");
print OUTFILE "";
close OUTFILE;
open (OUTFILE, ">>$temporyfile");

my $ucfasta = ();
if ($opts{c})
{
    $ucfasta = "$opts{i}UPPERCASE.MM";
    open (UPOUTFILE, ">$ucfasta");
}

foreach my $line (<INFILE>)
{
    if ($line =~ m/^>/)
    {
        if ($opts{c})
        {
            print UPOUTFILE "$line";
        }
    }
    else
    {
        print OUTFILE "$line";
        if ($opts{c})
        {
            my $LINE=uc$line;
            print UPOUTFILE "$LINE";
        }
        
    }
}

# awk the tempfile
system('awk \'{ for ( i=1; i<=length; i++ ) arr[substr($0, i, 1)]++ }END{ for ( i in arr ) { print i, arr[i] } }\' tempfile.MM > tempfile2.MM');
# Use 'awk \'{ for ( i=1; i<=length; i++ ) arr[substr($0, i, 1)]++ }END{ for ( i in arr ) { print i, arr[i] } }\' tempfile.MM'  (Without backslash precursors to single quotes in a real system commant)
# use backticks to load the output into a variable (e.g. $nol = `wc -l`)

# Rather than saving in tempfile2.MM I could just print the awk to screen.
# However this hacky method allows me to print the results in the order I want.
if($opts{s})
{
    print "\nFor All Characters (including those not supposed to be present, see tempfile2.MM\n\n";
}
# print bases in order
system("grep -i 'a' tempfile2.MM; grep -i 't' tempfile2.MM; grep -i 'w' tempfile2.MM");
system("grep -i 'c' tempfile2.MM; grep -i 'g' tempfile2.MM; grep -i 's' tempfile2.MM");
system("grep '-' tempfile2.MM; grep -i 'n' tempfile2.MM; grep -i 'm' tempfile2.MM; grep -i 'r' tempfile2.MM; grep -i 'y' tempfile2.MM; grep -i 'k' tempfile2.MM; grep -i 'v' tempfile2.MM; grep -i 'h' tempfile2.MM; grep -i 'd' tempfile2.MM; grep -i 'b' tempfile2.MM; grep -i 'x' tempfile2.MM");
print "(N = - or > 3 base ambiguity)\n";
# Print total and GC ratio
system("CBP=\$(grep 'C' tempfile2.MM | awk '{print \$2}'); GBP=\$(grep 'G' tempfile2.MM | awk '{print \$2}'); ABP=\$(grep 'A' tempfile2.MM | awk '{print \$2}'); TBP=\$(grep 'T' tempfile2.MM | awk '{print \$2}'); awk -v a=\$ABP -v t=\$TBP -v c=\$CBP -v g=\$GBP 'BEGIN {print \"Total bp:\",a+t+c+g,\"\\n\"\"GC ratio:\",(c+g)/(a+t+c+g)}'");
system("rm tempfile.MM");
unless($opts{s})
{
    system("rm tempfile2.MM");
}
print "\n";
