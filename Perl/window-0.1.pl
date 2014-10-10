#!/usr/bin/perl
use strict;
use warnings;


# Run after sliding-0.3.pl
# Shift and push each element up one then add a new line
# grep -v '#' temp.window-summary | awk 'BEGIN { FS="," }; {print $10}' | ./window-0.1.pl -i - -w 5000 > temp.window-5000

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:w:p', \%opts);

if ($opts{i})
{
    if (open(INFILE, $opts{i}))
    {

        my $position = sprintf("%.0f", $opts{w}/2);	# Set the base position column to start at the mid point of the window
        my @shiftpush;                  		# The array (window) I will collect sites into
        foreach my $line (<INFILE>)
        {
            if ($line =~ /^[+-]?\d+$/ )
            {
                chomp $line;
                push(@shiftpush, $line);
                my $windowfull = scalar @shiftpush;
                if ($windowfull == $opts{w})    	# Sample only after the array is full (= window size) if full print mean
                {
                    my $sum = 0;
                    foreach my $element (@shiftpush)
                    {
                        $sum = $sum + $element;
                    }
                    my $mean = $sum/$opts{w};
                    if ($opts{p})
                    {
                        print "$position,$mean\n";
                        $position++;
                    }
                    else
                    {
                        print "$mean\n";
                    }
                    shift @shiftpush;
                }
                
            }
        }
    }
    else
    {
        print "\nI Can't open file\nClosing script\n\n";
        exit;
    }
}
else
{
    print "\nWill generate a column of data for a sliding window accepts a column of data";
    print "\nRun after sliding-0.3.pl";
    print "\nEnter infile -i (produces at tempMM files)\nEnter the window size -w\nWould you like a column of positions?";
    print "\n\npull out the relevent column from a csv using grep\nfor column 10 excluding hash lines use:";
    print "\ngrep -v '#' temp.window-summary | awk 'BEGIN { FS="," }; {print $10}' | ./window-0.1.pl -i - -w 5000 > temp.window-5000";
    print "\n\nConsider sending to 'Rscript windowplotter.R' for a quick plot = Rplots.pdf\n\n";
    exit;
}
