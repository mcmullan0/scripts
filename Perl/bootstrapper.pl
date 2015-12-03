#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
my %opts;
getopts('i:c:r:b:o:p', \%opts);

unless ($opts{i} && $opts{c} && $opts{r} && $opts{b} && $opts{o})
{
    print "\n######################################## bootstrapper ##############################################";
    print "\nPerforms a bootstrap test on a column of data by comparing one observed result (mean) to any number\nof artificical samples from the same column.";
    print "\n-i Provide a tab delimited file of data in columns";
    print "\n-c Which column is the target data in?";
    print "\n-r how many consequtive rows encompases the sample of the data";
    print "\n-b how many iterations to run?";
    print "\n-o which is the first row of the observed data?";
    print "\n-p Print the expected distribution in a MM.bootstrapper.xxxxxx.MM file";
    print "\n##################################################################################################\n\n";
    exit;
}
# Set variables
$opts{c}--;	# reduce column no to reflect array starts are zero
$opts{o}--;
my @expected;	# Store bootstrap mean results		(expected)
my @sorted;	# Store sorted mootstrap mean results	(expected)
my @observed;	# Store observed mean			(observed)

# open our data file and read in the relevent column > @data
my @data;
open(INFILE, "<$opts{i}");
foreach my $line (<INFILE>)
{
  my @splittemp = split /\s+/, $line;
  push @data, $splittemp[$opts{c}];
}
close(INFILE);

my $range = ((scalar(@data))-$opts{r});             # get the range of positions to sample from (minus the length of the sample window)

# For each iteration of the bootstrap calculate a mean
for (my $i=0; $i<$opts{b}; $i++)
{
  my $grab = int(rand($range));
  my @temp1 = @data;					# Array to splice from
  my @temp2 = splice @temp1, $grab, $opts{r};
  my $total = 0;
  foreach my $element (@temp2)
  {
    $total +=$element;
  }
  my $mean_window = $total/$opts{r};
  push @expected, $mean_window;
}

# Sort the observed data and retrieve confidence intervals
@sorted = sort { $a <=> $b } @expected;
# Generate POSITIONS: 	99%	97.5%	95%	50%	mean	5%	2.5%	1% positions
my $e99p = int(($opts{b}/100 * 99) + 0.5);
my $e98p = int(($opts{b}/100 * 97.5) + 0.5);
my $e95p = int(($opts{b}/100 * 95) + 0.5);
my $e50p = int(($opts{b}/100 * 50) + 0.5);
my $e5p = int(($opts{b}/100 * 5) + 0.5);
my $e3p = int(($opts{b}/100 * 2.5) + 0.5);
my $e1p = int(($opts{b}/100 * 1) + 0.5);
# Get corresponding values
my $e99 = $sorted[$e99p];
my $e98 = $sorted[$e98p];
my $e95 = $sorted[$e95p];
my $e50 = $sorted[$e50p];
my $e5 = $sorted[$e5p];
my $e3 = $sorted[$e3p];
my $e1 = $sorted[$e1p];
# Generate expected mean VALUE
my $total = 0;
foreach my $element (@sorted)
  {
    $total +=$element;
  }
my $emean = $total/$opts{b};
# Get observed data (mean)
@observed = splice @data, $opts{o}, $opts{r};
$total = 0;
foreach my $element (@observed)
{
  $total +=$element;
}
my $omean = $total/$opts{r};

print "99%	$e99\n97.5%	$e98\n95%	$e95\n50%	$e50\n5%	$e5\n2.5%	$e3\n1%	$e1\nexpMean	$emean\nobsMean	$omean\n";

# Get test statistic
my $array_pos = 0;
my $found = 0;
my $position = -1;
while ($found < 1 && $array_pos < $opts{b})
{
  if ($sorted[$array_pos] > $omean)
  {
    $position = $array_pos + 1;
    $found = 1;
  }
  $array_pos++;
}
my $percentile = $position/$opts{b};
print "observed value is in the $percentile percentile\n\n";
if ($percentile < 0)
{
  print "Percentile is negative.  Your observed is outside the distrubution. Check your data and or use more iterations (increase -b)\n\n";
}

if ($opts{p})
{
  # Get random number for temp file suffix
  my $max = 999999999;
  my $rand = int(rand($max));
  my $ext_dist_out = "MM.bootstrapper.$rand.MM";
  print STDERR "Saving expected distribution to MM.bootstrapper.$rand.MM";
  open(DISTOUT, ">>$ext_dist_out");
  foreach my $element (@sorted)
  {
    print DISTOUT "$element\n";
  }
}
close(DISTOUT);




