#!/usr/bin/perl
use strict;
use warnings;

# Originally ran using ~/Documents/Circos/circos-0.67-5/data/hf_data/cha_soap_ope_lmp_k111r.scafSeq.fasta.out.all-repeeats-combiined.23.gff.merge.bed
# as input
# head = 
# combiined.23.gff.merge.bed
# scaffold1	0	8602
# scaffold1	9722	9981
# scaffold1	10068	12442
# scaffold1	14945	24848

use Getopt::Std;
my %opts;
getopts('i:w:s:', \%opts);

# Get random number for temp file suffix
my $max = 999999999;
my $rand = int(rand($max));

unless ($opts{i})
{
    print "\n######################################## gff-window ########################################";
    print "\nProduces sliding window data from a merged .gff file (bedtools merge -i infile > merged.bed";
    print "\nProportion of effected sites per window\n";
    print "\n-i Provide input file";
    print "\n-w Window size (default = 100000)";
    print "\n-s Slide width (default = 100000 = jumping window)";
    print "\nCAUTION prints data for windows with nothing in only until the end of the last feature.  Fine for circos but not for correlations -Add feature";
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
print "infile = $opts{i}; window = $opts{w}; slide = $opts{s}\n";

###################################### Print position for each attribute in TEMPOUT file##############################################
my $tempout = "MM.gff-window.pl.$rand.MM";
open(TEMPOUT, ">>$tempout");
open(BEDFILE, "<$opts{i}") or die "cannot open < $opts{i}: $!";
foreach my $line (<BEDFILE>)
{
    my @split = split /\s+/, $line;
    for (my $i=$split[1]; $i<=$split[2]; $i++)
    {
        unless ($i == 0)
        {
            print TEMPOUT "$split[0]-$i\n";
        }
    }
}
#################################################### Curate TEMPOUT into sliding window ##############################################
close(BEDFILE);
close(TEMPOUT);
if ($opts{w} >= $opts{s})   # If it is a jumping window open the file only once and work through
{
    open(TEMPOUT, "<$tempout");     # Get the first scaffold name for later (to tell if we move to a new scaffold or not)
    my $firstline = (<TEMPOUT>);
    my @scaffcheck = split /-/, $firstline;
    close(TEMPOUT);
    
    my $winstart = 1;
    my $winend = $winstart + $opts{w} - 1;
    my $counter = 0;                        # A counter for event bp
    my $newscaffemptywindow = 0;             # A correction so that if the first window of a new scaff is empty we print zero and save the 1 value for the first full scaff.  This could be cased if we read in scaff2-6 in a 5 bp window we count the 1 (as in bp No. six) and then wait until the window moves to position 6-15 and then record the 1

    open(TEMPOUT, "<$tempout");     # collect data in remainder of file
    foreach my $line (<TEMPOUT>)
    {
        my @scaffold = split /-/, $line;
        if ($scaffold[0] eq $scaffcheck[0])
        {
            if ($scaffold[1] <= $winend)        # What if there is nothing in a window????? It prints the next window event though the data has actually jumped further than this
            {
                $counter++;
                $newscaffemptywindow = 1;
            }
            else
            {
                # Print data for previous window (or print $newscaffemptywindow if this is a new scaffold)
                if ($newscaffemptywindow == 0)
                {
                    print "$scaffold[0]    $winstart    $winend $newscaffemptywindow\n";
                    # Increment window until we have data
                    $winstart = $winstart + $opts{s};
                    $winend = $winend + $opts{s};
                    while ($scaffold[1] > $winend)
                    {
                        print "$scaffold[0]    $winstart    $winend 0\n";
                        $winstart = $winstart + $opts{s};
                        $winend = $winend + $opts{s}; 
                    }
#                    $newscaffemptywindow = 1;
                }
                else    # If this is not a new scaffold window
                {
                    my $proportionbp = $counter/$opts{w};
                    print "$scaffold[0]    $winstart    $winend $proportionbp\n";
                    # Increment window until we have data
                    $winstart = $winstart + $opts{s};
                    $winend = $winend + $opts{s};
                    while ($scaffold[1] > $winend)
                    {
                        print "$scaffold[0]    $winstart    $winend 0\n";
                        $winstart = $winstart + $opts{s};
                        $winend = $winend + $opts{s}; 
                    }
                    $counter = 1;
                }
            }
        }
        else        # We have moved on to a new scaffold
        {
            $counter++;
            my $proportionbp = $counter/$opts{w}; # divide by size of last window not $opts{w} to include only those regions that are deffinetely present.  I could later incorprae a scafolld length feature but that would require another input file
            print "$scaffcheck[0]    $winstart    $winend $proportionbp\n";
            $winstart = 1;
            $winend = $winstart + $opts{w} - 1;
            $scaffcheck[0] = $scaffold[0];
            $counter = 1;
            $newscaffemptywindow = 0;
        }
    }
    $counter++;
    my $proportionbp = $counter/$opts{w};       # Print last set of data once outside the loop
    print "$scaffcheck[0]    $winstart    $winend $proportionbp\n";
    close(TEMPOUT);
    system("rm $tempout");
}
else
{
    print "\nYou need to write this part because an overalpping windows mean re-opening the temporary file $tempout";
}
