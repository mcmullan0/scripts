#!/usr/bin/perl
use strict;
use warnings;

# GC-window.pl
# as input
# fasta file
# Test file:
#>scaff-_1
#AAaAatttttcccccggggg
#>scaff2
#tttttcccccgggggaaaaa
#>spacy3
#Aa-Aa-----ccCCcG--GG
#>lostsgone4
#aA_a-tNnnt__ccGgGgG
#
# You could have this print a 4th column which would be a count of the number of sites (after removal of N and -)
# If you want to add this later the variable you are loking for is $length and $space.  Make sure to check for all the
# different print statements.

use Getopt::Std;
my %opts;
getopts('i:w:s:An', \%opts);

unless ($opts{i})
{
    print "\n######################################## GC-window ########################################";
    print "\nGC-window.pl calculates GC content within a window across a multi-sequence fasta file (handels both upper and lower case)";
    print "\nConsider first running fastchar.pl to check you don't have any unusual text in your sequences";
    print "\nOutput contains three columns which are scaff-name, window midpoint and GC content";
    print "\nDivides by window size minus the number of 'n' and/or 'N' and/or '-'";
    print "\n-i Provide input fasta file";
    print "\n-w Window size (default = 100000)";
    print "\n-s Slide width (default = 100000 = jumping window)";
    print "\n-A will calculate the AC content";
    print "\n-n will calculate the n|N|_|- (gap) content";
    print "\n############################################################################################\n\n";
    exit;
}

######################################## Set vairables ########################################
unless ($opts{w})
{
    $opts{w}=100000;
}
unless ($opts{s})
{
    $opts{s}=100000;
}
my $whatbase;
if ($opts{A})
{
  $whatbase = "AT";
}
elsif ($opts{n})
{
  $whatbase = "n or N or _ or -";
}
else
{
  $whatbase = "GC";
}
print "# $whatbase content for infile = $opts{i}; window = $opts{w}; slide = $opts{s}\n";

my $header;             # Store fasta name / scaffld
my $output;             # Store window ouput
my $G = "G";            # Set important bp
my $C = "C";
if ($opts{A})
{
    $G = "A";
    $C = "T";
}
my $dash = "-";
my $unscr = "_";
my $N = "N";

###################################### Run script #####################################

open(FASTA, "<$opts{i}") or die "cannot open < $opts{i}: $!";
foreach my $line (<FASTA>)
{
    my $start = 0;
    my $start1;             # Start posisiton + 1 (deal with first base zero in perl)
    my $end1;               # End posisiton + 1 (deal with first base zero in perl)
    chomp($line);
    if ($line =~ m/^>/)
    {
        $header = reverse($line);
        chop $header;
        $header = reverse($header);
    }
    else
    {
        my $window = substr $line, $start, $opts{w};    # Collect line then subset first window
        $start1 = $start + 1;
        $end1 = $start + $opts{w};
        chomp $window;
        my $ucwindow = uc $window;			# Uppercase window
        # Count bases G and C and spaces
        my $Gc = () = $ucwindow =~ /$G/g;
        my $Cc = () = $ucwindow =~ /$C/g;
        my $dashc = () = $ucwindow =~ /$dash/g;
        my $unscrc = () = $ucwindow =~ /$unscr/g;
        my $Nc = () = $ucwindow =~ /$N/g;
        # Sum the groups
        my $GC = $Gc + $Cc;
        my $space = $dashc + $unscrc + $Nc;
        if ($opts{n})
        {
            $output = $space/$opts{w};
        }
        else
        {
            if ($opts{w} == $space)                 # If all the window is space save program from dividing by zero
            {
                $output = 0;
            }
            else
            {
                $output = $GC/($opts{w} - $space);
            }
        }
        print "$header  $start1 $end1   $output\n";
        my $length = length($ucwindow);
        while ($length == $opts{w})
        {
            $start = $start + $opts{s};                             # Set the new window
            $start1 = $start + 1;
            $end1 = $start + $opts{w};
            my $window = substr $line, $start, $opts{w};            # Grab the window from the line
            chomp $window;                                          # Remove \n
            $ucwindow = uc $window;                                 # Change to caps
            $Gc = () = $ucwindow =~ /$G/g;
            $Cc = () = $ucwindow =~ /$C/g;
            $dashc = () = $ucwindow =~ /$dash/g;
            $unscrc = () = $ucwindow =~ /$unscr/g;
            $Nc = () = $ucwindow =~ /$N/g;
            $GC = $Gc + $Cc;
            $space = $dashc + $unscrc + $Nc;
            $length = length($ucwindow);
            if ($length == $opts{w})
            {
                if ($opts{n})
                {
                    $output = $space/$opts{w};
                }
                else
                {
                    if ($length == $space)                 # If all the window is space save program from dividing by zero
                    {
                        $output = 0;
                    }
                    else
                    {
                        $output = $GC/($opts{w} - $space);
                    }
                }
                print "$header  $start1 $end1   $output\n";
            }
            else
            {   
                if ($length > 0)
                {
                    if ($opts{n})
                    {
                        $output = $space/$length;
                    }
                    else
                    {
                        if ($length == $space)                 # If all the window is space save program from dividing by zero
                        {
                            $output = 0;
                        }
                        else
                        {
                            $output = $GC/($length - $space);
                        }
                    }
                    print "$header  $start1 $end1   $output\n";
                }
            }
        }
    }
}
