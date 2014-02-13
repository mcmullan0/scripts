#!/usr/bin/perl -w
use strict;
use warnings;

# Remove multple lines from the sequence section of a fasta file

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:aq', \%opts);
if ($opts{i})
{
    unless (open(INFILE, $opts{i}))
    {
        print "\n\nCannot open infile\nClosing script\n\n$!";
        exit;
    }
}
else
{
    print "\nRemoves multiple lines from within the sequence of a fasta (or fastq) file.  Output is always in fastA";
    print "\nEnter -i filename\nState fastA or fastQ (-a -q)\n\n";
    exit;
}

# IF fasta
if ($opts{a})
{
    # First remove all carriage returns that are not in a line with '>' in it.
    my $seq = ('');
    foreach my $line (<INFILE>)
    {
        if ($line =~ m/^>/)         # Print if title line
        {
            if ($seq eq '')         # Print only if this title line is the first line of the file
            {
                print "$line"
            }
            else                    # Else print the sequence of previous title line before next title line
            {
                print "$seq\n$line";
                $seq = ();              # Reset seqeunce for new title line
            }
        }
        else
        {
            chomp $line;
            $seq = "$seq$line";
        }
    }

    # Now print the last line
    print "$seq";
    print "\n";
}

# If fastq convert to fasta with 1 line per sequence.
if ($opts{q})
{
    my $at = 0;                     # Print @ lines and lines after until +
    my $counter = 0;
    my $seq = ('');
    my $rpa = ">";
    foreach my $line (<INFILE>)
    {
        if ($line =~ m/^@/ && $counter == 0)    # This section says:
        {                                       #If this line starts with an @
            $at = 1;                            #then print it.  However, in 
        }                                       #some cases the sequence quality
        if ($line =~ m/\+/)                     #line may start with an @ and 
        {                                       #I don't want this line to print
            $at = 0;                            #so I count the lines between
        }                                       #the @ (title) amd the + (start
        if ($at == 1)                           #of the quality where @s could
        {                                       #be) and prevent printing @s
            $counter = $counter + 1;            #where the counter is greater
        }                                       #than 0.
        if ($at == 0)                           #
        {                                       #So:
            $counter = $counter - 1;            #Print if this line starts with
        }                                       #@ unless counter is > 0
        if ($at == 1 && $counter > 1)
        {
            chomp $line;
            $seq = "$seq$line";
        }
        if ($at == 1 && $counter == 1)
        {
            if ($seq eq '')
            {
                $line =~ s/^.//;
                print "$rpa$line";
            }
            else
            {
                $line =~ s/^.//;                # Remove first character
                print "$seq\n$rpa$line";
                $seq = ();
            }
        }
    }
    # Now print the last line
    print "$seq";
    print "\n";
}

else
{
    print "\nState fastA or fastQ (-a -q)\n\n";
}
