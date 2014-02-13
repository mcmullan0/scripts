#!/usr/bin/perl
use strict;
use warnings;

# Removes recombination events with unknown parents and will also remove asterisks
# from ambigious recombination Begin and End positions

use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('i:r:ua', \%opts);
# Remove * using unix command
if ($opts{a})
{
    system ("sed 's/\*//g' $opts{i} > mcmtemp; mv mcmtemp $opts{i}");
}

if ($opts{u})
{
    unless (open(INFILE, $opts{i}))
    {
        print "\n\nCannot open infile\nClosing script\n\n$!";
        exit;
    }
}
else
{
    print "\nRemoves recombination events with unknown parents and will also remove asterisks";
    print "\nfrom ambigious recombination Begin and End positions\n\nPrints to STOUT";
    print "\n\nEnter -i filename.csv\nState whether to remove unknowns (-u) and/or * (-a)";
    print "\nUse -r filename.csv to save the unknown events that were removed\n\n";
    exit;
}

# Remove whole events that have a parent which is unknown
# If there is an Unknown in the line, remove that line and other lines from that event
my @removed = ();
if ($opts{u})
{   # All options are stored in the output file:
    print "An RDP csv ($opts{i}) curated using rdpformat.pl which\n";
    if ($opts{u})
    {
        print "removed Unknown events\n";
        if ($opts{r})
        {
            print "saved Unknown events as $opts{r}\n";
        }
    }
    if ($opts{a})
    {
        print "removed asterisks from ambigious breakpoint positions\n"
    }
    while (my $line = <INFILE>)
    {
        if ($line =~ /Unknown/)
        {
            while ($line !~ /,,,,,,,,,,,,,,,,,,,/)
            {
                push (@removed, $line);
                $line = <INFILE>;
            }
        }
        else
        {
            if ($line !~ /,,,,,,,,,,,,,,,,,,,/)
            {
                print "$line";
            }
        }
    }
}
if ($opts{r})
{
    my $removed = "$opts{r}";
    open(REMOVED, ">$removed");
    print REMOVED "@removed";
    close REMOVED;
}
close INFILE;