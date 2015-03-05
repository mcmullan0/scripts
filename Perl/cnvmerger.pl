#!/usr/bin/perl
use strict;
use warnings;

# Merges CNV information from multiple CNVnator runs
# -i Provide an index of the start and dtop positions of each scaffold (scaff-name[tab]start[tab]stop)  [I might not use this]
# -d Provide a direcory that contains all CNVnator output files
# -p Provide a column number (5-8) for the p-values you want to use
# -a Privide an alpha value for p-value acceptance criteria (default = 0.05)
# -e or -u to curate dEletions or dUplications (this is done seperately so choose one OR the other)


use Getopt::Std;
my %opts;
getopts('i:d:p:a:eu', \%opts);

# Get random number for file suffix
my $max = 999999;
my $rand = int(rand($max));


# Check input directory and make a list of CNVnator files (remove hidden files)
unless ($opts{d} && $opts{p})
{
    print "\nMerges CNV information from multiple CNVnator runs\n";
    print "\n-i Provide an index of the start and dtop positions of each scaffold (scaff-name[tab]start[tab]stop)  [I might not use this]";
    print "\n-d Provide a direcory that contains all CNVnator output files";
    print "\n-p Provide a column number (5-8) for the p-values you want to use";
    print "\n-a Privide an alpha value for p-value acceptance criteria (default = 0.05)";
    print "\n-e or -u to curate dEletions or dUplications (this is done seperately so choose one OR the other)\n\n";
    print "\nOpens and removes a temporary file call tempcnvmerg-$rand.MM\n\n";
    exit;
}

# Set $deldup to capture requred CNV
my $deldup;
if ($opts{e})
{
    $deldup = "deletion";
}
elsif ($opts{u})
{
    $deldup = "duplication";
}
else
{
    print "\nSpecify whether or not you want the script to count deletions (-e) or duplications (-u)\n\n";
    exit;
}
# Set alpha value
unless ($opts{a})
{
    $opts{a}=0.05;
}
# Correct for counting zero in array
$opts{p}=$opts{p}-1;

opendir (DIR, $opts{d}) or die "\nCannot open directory\n$!\n\n";
my @files = readdir DIR;
closedir DIR;
# Remove any hidden files/directory names from @files -> @cnvfiles
my @cnvfiles = ();
foreach my $files (@files)
{
    push(@cnvfiles, $files) unless("$files" =~ /^\./);
}
print "CNVmerge.pl\nDirectory = $opts{d}\nCNV files = @cnvfiles\n";
print "\n\nSampling \"$deldup\" sites at alpha = $opts{a} (column $opts{p})\n\n";

# For each CNV file:
#   open for each line
#       ask is it a deletion or duplication? (filter)
#       ask is it significant at column -p (alpha -a) (filter)
#       split scaffold name from positions on ':' (save)
#       split positions on '-'
#       foreach position (min to max>) print "scaffold name - position" in an array
#           Generate array
#       foreach element in array
#           Add or cound in dictionary
#   Delete array or Name array IND-X (keep dictionary)

my $cnvcounter = 0;
my %eventhash;
foreach my $cnvfiles (@cnvfiles)
{
    my $filepath = "$opts{d}/$cnvfiles";
    $cnvcounter = $cnvcounter+1;
    open(CNVFILE, "<$filepath") or die "cannot open < $filepath: $!";
    foreach my $line (<CNVFILE>)
    {
        my @split = split /\s+/, $line;
        if ($split[0] eq $deldup)       # If it is a duplication or a deletion (depending on user)
        {
            if ($split[$opts{p}] <= $opts{a})   # If it is significant seperate out coords from scaff and 
            {
                my @eventarray;
                my $coordinates=$split[1];      
                my @scaff = split /:/, $coordinates;
                my @eventbp = split /-/, $scaff[1];
                for (my $i=$eventbp[0]; $i<=$eventbp[1]; $i++)
                {
                    push(@eventarray, "$scaff[0]_$i");
                }
                foreach (@eventarray)
                {
                    $eventhash{$_}++;
                }
            }
        }
    }
}

my $tempout = "tempcnvmerg-$rand.MM";
open (OUTFILE, ">$tempout");
print OUTFILE "";
close OUTFILE;

open (OUTFILE, ">$tempout");
foreach (keys %eventhash)
{
    print OUTFILE "$_\t$eventhash{$_}\n";
}
system("sort -t\"_\" -k2,2n -k3,3n tempcnvmerg-$rand.MM > tempcnvmerg-$rand.MM2");
print "Scaffold\tCNV\n";
system("cat tempcnvmerg-$rand.MM2; rm tempcnvmerg-$rand.MM tempcnvmerg-$rand.MM2");


