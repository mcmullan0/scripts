#!/usr/bin/perl -w
use strict;
use warnings;

# Return the total number of reads and bases and the average (StDev)
# length of reads and the estimated coverage, if genome size is provided.

my $genome = 0;
my $rlengths = 0;
my $fasta = ();
use Getopt::Std;
{
    my %opts;
    # accept input file -i (argument)
    # accept genome size -g (argument)
    getopts('i:g:laq', \%opts);
    if ($opts{i})
    {
        unless (open(INFILE, $opts{i}))
        {
            print "\n\nCannot open infile\nClosing script\n$!\n";
            exit;
        }
        print "\n$opts{i}\n";
    }
    else
    {
        print "\nEnter -i filename\nAlso -g genome size Mb (optional)\nand -l (optional 'all lengths outfile)\n";
        print "also include an -a OR a -q flag for fastA OR fastQ\n\n";
        exit;
    }
    if ($opts{l})
    {
        $rlengths = 1;
    }
    if ($opts{a})
    {
        $fasta = 0;
        print "fastA file\n";
    }
    if ($opts{q})
    {
        $fasta = 1;
        print "fastQ file\n";
    }
        if ($opts{g})
    {
        $genome = ($opts{g}*1000000);
        print "Genome = $opts{g}Mb\n";
    }
}
my $nread = 0;          # Could use wc -l but I have to read each line anyway..
my $nbase = 0;          # Total number of bases in file
my $base = 0;           # No. bases for each sequence seperatly
my @bases = ();         # If -l collect all sequence lengths
my @basearray = ();     # Bases per sequence for stDEV
my $lbase = 0;		# Longest sequence
my $sbase = 1000000;	# Shortest sequence
my $counter = 0;
# Read each line and record information every 4th line (the qualtiy line)
foreach my $line (<INFILE>)
{
    $counter = $counter + 1;
    my $remain = ();
    if ($fasta == 0)
    {
        $remain = $counter % 2;
    }
    else
    {
        $remain = $counter % 4;
    }
    if ($remain == 0)
    {
        $nread = $nread + 1;                # Reads = + 1
        $line =~ s/^\s+|\s+$//g;            # Remove start and end whitespace
        $base = length($line);              # Count characters for base
        $nbase = $nbase + $base;            # Add base to nbase for total
        push(@basearray, $base);            # Store bases to calc Stdev
        if ($base > $lbase)                 # If most bases count
        {
            $lbase = $base;
        }
        if ($base < $sbase)
        {
            $sbase = $base;
        }
        if ($rlengths == 1)
        {
            push(@bases, $base);
        }
    }
}

# Calculate stDEV = (x - mean)^2 then average these values and get sqrt.
my $avreadl = (eval (join '+', @basearray))/$nread; # Average
my $stdev = 0;
my @sqararray = ();                                 # Array for squared values
foreach my $basearray (@basearray)
{
    $basearray = ($basearray - $avreadl)**2;
    push(@sqararray, $basearray)                    # Array of squared difference
}
$stdev = sqrt((eval (join '+', @sqararray))/$nread);

# Print values and exit
print "\nreads = $nread\nbases = $nbase\nmean read l = $avreadl (+-$stdev)\nLongest read = $lbase\nShortest read = $sbase\n";
if ($genome > 0)
{
    my $depth = $nbase/$genome;
    print "depth = $depth x\n"
}
if ($rlengths == 1)
{
    my $output = "lengths.MM.csv";
    open(OUTFILE, ">$output");
    foreach my $bases (@bases)
    {
        print OUTFILE "$bases\n";
    }
    close(OUTFILE);
}
print "\n";