#!/usr/bin/perl
use strict;
use warnings;

# Counts all the characters in a fasta file
# Does not count characters in the title line

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:s:', \%opts);
unless ($opts{i})
{
    print "\nCount all the characters in a fasta file";
    print "\nDoes not count characters in the title line";
    print "\nEnter infile -i\n\n";
    exit;
}

# Open file
unless (open(INFILE, $opts{i}))
{
    print "\nI Can't open file\nClosing script\n";
    exit;
}

my $temporyfile = 'tempfileMM.seq'; # A tempory file into which I copy all sequence lines
open (OUTFILE, ">$temporyfile");
print OUTFILE "";
close OUTFILE;
open (OUTFILE, ">>$temporyfile");

foreach my $line (<INFILE>)
{
    if ($line =~ m/^>/)
    {
        
    }
    else
    {
        print OUTFILE "$line";
    }
}

# awk the tempfile
system('awk \'{ for ( i=1; i<=length; i++ ) arr[substr($0, i, 1)]++ }END{ for ( i in arr ) { print i, arr[i] } }\' tempfileMM.seq > tempfile2MM.seq');
# Use 'awk \'{ for ( i=1; i<=length; i++ ) arr[substr($0, i, 1)]++ }END{ for ( i in arr ) { print i, arr[i] } }\' tempfileMM.seq'  (Without backslash precursors to single quotes in a real system commant)
# use backticks to load the output into a variable (e.g. $nol = `wc -l`)

# Rather than saving in tempfile2MM.seq I could just print the awk to screen.
# However this hacky method allows me to print the results in the order I want.
if($opts{s})
{
    print "\nFor All Characters (including those not supposed to be present, see tempfile2MM.seq\n\n";
}
print "\nA/T\n";
system("grep -i 'a' tempfile2MM.seq; grep -i 't' tempfile2MM.seq; grep -i 'w' tempfile2MM.seq");
print "\n\nC/G\n";
system("grep -i 'c' tempfile2MM.seq; grep -i 'g' tempfile2MM.seq; grep -i 's' tempfile2MM.seq");
print "\n\n- or n\n";
system("grep '-' tempfile2MM.seq; grep -i 'n' tempfile2MM.seq; grep -i 'm' tempfile2MM.seq; grep -i 'r' tempfile2MM.seq; grep -i 'y' tempfile2MM.seq; grep -i 'k' tempfile2MM.seq; grep -i 'v' tempfile2MM.seq; grep -i 'h' tempfile2MM.seq; grep -i 'd' tempfile2MM.seq; grep -i 'b' tempfile2MM.seq; grep -i 'x' tempfile2MM.seq");
system("rm tempfileMM.seq");
unless($opts{s})
{
    system("rm tempfile2MM.seq");
}