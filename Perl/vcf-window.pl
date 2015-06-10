#!/usr/bin/perl
use strict;
use warnings;

# Counts the number of lines (or density of features) in a sliding window over a vcf
# provide -i input.vcf -w Window size -s slide distacne
#

use Getopt::Std;
my %opts;
getopts('i:f:w:s:', \%opts);

# Get random number for temp file suffix
my $max = 999999999;
my $rand = int(rand($max));

unless ($opts{i})
{
    print "\n######################################## vcf-window ##############################################";
    print "\nProduces sliding window density data from a .vcf (requires reference fasta for scaffold lengths).";
    print "\nWindow slides through column 2 (POS) of vcf input can be a multisample vcf.";
    print "\nOutput is the proportion of effected sites per window.\n";
    print "\n-i Provide .vcf file\n-f Provide reference.fasta";
    print "\n-w Window size (default = 100000)";
    print "\n-s Slide width (default = 100000 = jumping window)";
    print "\n\nPrint output:\nScaff_name	Start	Stop	Value";
    print "\n##################################################################################################\n\n";
    exit;
}
######################################## Set vairables ########################################
unless ($opts{w} && $opts{f})
{
    $opts{w}=100000;
}
unless ($opts{s})
{
    $opts{s}=100000;
}
print "infile = $opts{i}; window = $opts{w}; slide = $opts{s}\n";
my $winstart = 1;
my $winend = $winstart + $opts{w} - 1;
my $denominator = $winend - ($winstart - 1);

########## Open fasta and record scaffold lengths from fasta in temporary file ##################
open(FASFILE, "<$opts{f}") or die "cannot open fasta < $opts{f}: $!";
my $tempout = "MM.vcf-window.pl.$rand.MM";
open(TEMPOUT, ">>$tempout");
my $header;
my $fasta;
my $chars;
foreach my $line (<FASFILE>)
{
    chomp($line);
    if ($line =~ /^>/)
    {
        $header = $line;
        $header = reverse $header;
        chop($header);
        $header = reverse $header;
    }
    else
    {
        $chars = length($line);
        print TEMPOUT "$header\t$chars\n";
    }
}
close (TEMPOUT);
############################## Load vcf feature postions into an array ###########################
# Read in vcf
# split line at whitespace
# for each scaffold
# load in all feature positions to an array
# count the elements betweeen window boundaries

open(VCFFILE, "<$opts{i}") or die "cannot open < $opts{i}: $!";
my $scaffname;      # Check scaffname and scaffarray are the same (have I moved to a new scaffold?)
my @scaffarray;     # Save all scaffold names in array
my @bparray;        # Save all base positions in array
my $lastscaff;      # Save scaffold name for last line of file
my $output;         # Save output (bp/window)
foreach my $line (<VCFFILE>)
{
    my @split = split /\s+/, $line;
    push @scaffarray, $split[0];
    push @bparray, $split[1];
}
my $length_scaffarray = scalar(@scaffarray);
##################### Generate window positions for each scaffold and count elements #########################
open(TEMPOUT, "<$tempout");
foreach my $line (<TEMPOUT>)     # Generate a Start and End array containing Start and End postions
{
    # Generate window Start and End positions from temporary file (from fasta sequence lengths)
    my @header_length = split /\s+/, $line;
    my @windowS;
    my @windowE;
    for (my $i=1; $i<$header_length[1]; $i+=$opts{s})
    {
        push @windowS, $i;
    }
    for (my $i=($opts{w}); $i<=$header_length[1]; $i+=$opts{s})
    {
        push @windowE, $i;
    }
    push @windowE, $header_length[1];
    my $lastwindow = scalar(@windowE);
    $lastwindow--;
    
    
    # Count @bparray elements which match the saffold > @bpmatch...
    my @bpmatch;    # Array of event positions from our focal scaffold
    for (my $element=0; $element<$length_scaffarray; $element++)
    {
        if ($scaffarray[$element] eq $header_length[0])
        {
            push @bpmatch, $bparray[$element];
        }
    }
    # For each window (@windowS) cycle through @bpmatch for those values within the window and count and print
    my $windowN = scalar(@windowS);
    for (my $element=0; $element<$windowN; $element++)              # For each window
    {
        my $counter = 0;                                            # Reset counter
        my $length_bpmatch = scalar(@bpmatch);
        for (my $bpevent=0; $bpevent<$length_bpmatch; $bpevent++)      # Check each bp is within it
        {
            if ($bpmatch[$bpevent]>=$windowS[$element] && $bpmatch[$bpevent]<=$windowE[$element])
            {
                $counter++                                          # And count
            }
        }
        $output = $counter/$denominator;
        if ($element>$lastwindow)
        {
            print "$header_length[0]\t$windowS[$element]\t$windowE[$lastwindow]\t$output\n";
        }
        else
        {
            print "$header_length[0]\t$windowS[$element]\t$windowE[$element]\t$output\n";
        }
    }
}
system("rm $tempout");

################################ test.vcf #########################################
#Hymenoscyphus_fraxineus_v2_scaffold_1 108
#Hymenoscyphus_fraxineus_v2_scaffold_1 153
#Hymenoscyphus_fraxineus_v2_scaffold_1 158
#Hymenoscyphus_fraxineus_v2_scaffold_1 162
##Hymenoscyphus_fraxineus_v2_scaffold_1 165
#Hymenoscyphus_fraxineus_v2_scaffold_1 180
#Hymenoscyphus_fraxineus_v2_scaffold_1 401
#Hymenoscyphus_fraxineus_v2_scaffold_1 402
#Hymenoscyphus_fraxineus_v2_scaffold_1 1402
#Hymenoscyphus_fraxineus_v2_scaffold_1 1416
#Hymenoscyphus_fraxineus_v2_scaffold_1 1799
#Hymenoscyphus_fraxineus_v2_scaffold_2 26
#Hymenoscyphus_fraxineus_v2_scaffold_2 133
#Hymenoscyphus_fraxineus_v2_scaffold_2 245
#Hymenoscyphus_fraxineus_v2_scaffold_3 6
#Hymenoscyphus_fraxineus_v2_scaffold_3 33
#Hymenoscyphus_fraxineus_v2_scaffold_3 45
#Hymenoscyphus_fraxineus_v2_scaffold_4 1
#Hymenoscyphus_fraxineus_v2_scaffold_4 601
#Hymenoscyphus_fraxineus_v2_scaffold_4 602
#Hymenoscyphus_fraxineus_v2_scaffold_4 603
#Hymenoscyphus_fraxineus_v2_scaffold_4 604
#Hymenoscyphus_fraxineus_v2_scaffold_4 605
#Hymenoscyphus_fraxineus_v2_scaffold_4 606
#Hymenoscyphus_fraxineus_v2_scaffold_5 399
#Hymenoscyphus_fraxineus_v2_scaffold_5 409
#Hymenoscyphus_fraxineus_v2_scaffold_5 411
#Hymenoscyphus_fraxineus_v2_scaffold_5 420
#Hymenoscyphus_fraxineus_v2_scaffold_5 460
#Hymenoscyphus_fraxineus_v2_scaffold_5 466
#Hymenoscyphus_fraxineus_v2_scaffold_5 480
#Hymenoscyphus_fraxineus_v2_scaffold_5 481
#Hymenoscyphus_fraxineus_v2_scaffold_5 488
#Hymenoscyphus_fraxineus_v2_scaffold_5 499
#Hymenoscyphus_fraxineus_v2_scaffold_5 500
#Hymenoscyphus_fraxineus_v2_scaffold_5 501
#Hymenoscyphus_fraxineus_v2_scaffold_5 515
#Hymenoscyphus_fraxineus_v2_scaffold_5 520
#Hymenoscyphus_fraxineus_v2_scaffold_5 528
#Hymenoscyphus_fraxineus_v2_scaffold_5 529
#Hymenoscyphus_fraxineus_v2_scaffold_5 577
#Hymenoscyphus_fraxineus_v2_scaffold_5 580
#Hymenoscyphus_fraxineus_v2_scaffold_5 591
#Hymenoscyphus_fraxineus_v2_scaffold_5 593
######################################################################################
#### Create test.fas using this and neaten in vim by adding a newline after header ####
#echo '>Hymenoscyphus_fraxineus_v2_scaffold_1' > test.fas
#for i in {1..2056}; do echo "A" >> test.fas; done
#echo '>Hymenoscyphus_fraxineus_v2_scaffold_2' >> test.fas
#for i in {1..456}; do echo "B" >> test.fas; done
#echo '>Hymenoscyphus_fraxineus_v2_scaffold_3' >> test.fas
#for i in {1..156}; do echo "C" >> test.fas; done
#echo '>Hymenoscyphus_fraxineus_v2_scaffold_4' >> test.fas
#for i in {1..856}; do echo "C" >> test.fas; done
#echo '>Hymenoscyphus_fraxineus_v2_scaffold_5' >> test.fas
#for i in {1..1015}; do echo "D" >> test.fas; done
#cat test.fas | tr -d '\n' > test
#cat test | tr '>' '\n>' > test.fas
#vim test.fas

print "\n";
