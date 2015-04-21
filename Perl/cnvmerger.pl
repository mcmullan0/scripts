#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('d:p:a:teu', \%opts);

# Get random number for file suffix
my $max = 999999999;
my $rand = int(rand($max));


# Check input directory and make a list of CNVnator files (remove hidden files)
unless ($opts{d})
{
    print "\nMerges CNV information from multiple CNVnator runs\n";
    print "\n-d Provide a direcory that contains all CNVnator output files";
    print "\n-p Provide a column number (5-8) for the p-values you want to use (default = 5)";
    print "\n-a Privide an alpha value for p-value acceptance criteria (default = 0.05)";
    print "\n-e or -u to curate dEletions or dUplications (this is done seperately so choose one OR the other)\n\n";
    print "\n-t If you want save a pairwise distance table of cnv differences between individuals\n\n";
    print "\nOpens and removes a temporary file call tempcnvmerg-$rand.MM\n\n";
    exit;
}

#################################### Set vairables #################################
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

# Set p-value column
unless ($opts{p})
{
    $opts{p}=5;
}
# Set alpha value
unless ($opts{a})
{
    $opts{a}=0.05;
}

# Correct for pvalue column for counting zero in array
$opts{p}=$opts{p}-1;
my $addone = $opts{p}+1;    # Used in print below

################################### Collect infiles ##############################

opendir (DIR, $opts{d}) or die "\nCannot open directory\n$!\n\n";
my @files = readdir DIR;
closedir DIR;
# Remove any hidden files/directory names from @files -> @cnvfiles
my @cnvfiles = ();
foreach my $files (@files)
{
    push(@cnvfiles, $files) unless("$files" =~ /^\./);
}
print "CNVmerge.pl\nrandom number = $rand\nDirectory = $opts{d}\nCNV files = @cnvfiles\n";
print "\n\nSampling \"$deldup\" sites at alpha = $opts{a} (column $addone)\n\n";

#################################### Script logic ###############################
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
#Add pairwise distance funtionality 
##################################################################################
my %eventhash;
my $noind = scalar @cnvfiles;
my @allcnv;

my $pairWout;
if ($opts{t})
{
    $pairWout = "temp_pairwise-$rand.MM";
    open (PAIROUTFILE, ">>$pairWout");
}

foreach my $cnvfiles (@cnvfiles)
{
    my $cnvcounter = 0;
    my $cnvbp = 0;
    my $filepath = "$opts{d}/$cnvfiles";
    open(CNVFILE, "<$filepath") or die "cannot open < $filepath: $!";
    foreach my $line (<CNVFILE>)
    {
        my @split = split /\s+/, $line;
        if ($split[0] eq $deldup)       # If it is a duplication or a deletion (depending on user)
        {
            if ($split[$opts{p}] <= $opts{a})   # If it is significant seperate out coords from scaff and 
            {
                $cnvcounter = $cnvcounter + 1;
                my @eventarray;
                my $coordinates=$split[1];      
                my @scaff = split /:/, $coordinates;
                my @eventbp = split /-/, $scaff[1];
                for (my $i=$eventbp[0]; $i<=$eventbp[1]; $i++)
                {
                    push(@eventarray, "$scaff[0]_$i");
                    $cnvbp++;
                }
                foreach (@eventarray)
                {
                    $eventhash{$_}++;
                }
                if ($opts{t})   # If parwise distance table is required generate an array for each ind to save all the cnv sites
                {
                    my $scal = join(",", @eventarray);
                    print PAIROUTFILE "$scal\n";
                }
            }
        }
    }
    print "$cnvfiles\t$cnvcounter\t$cnvbp\n";
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
print "\nScaffold\tCNV\n";
system("cat tempcnvmerg-$rand.MM2; rm tempcnvmerg-$rand.MM tempcnvmerg-$rand.MM2");

# Really do the pairwise stuff that was collected in PAIROUTFILE
# Compare each line of the output file to each line of the same file.
# This file contains a line for each ind of the names of every position with a cnv in the genome
my @cnvsites;   # Stores the number of cnv sites for each focal ind for addtion to a matrix later
if ($opts{t})
{
    close PAIROUTFILE;
    open (PAIROUTFILE1, "<$pairWout") or die "cannot open < $pairWout: $!";
    my %paireventhash;
    foreach my $fline (<PAIROUTFILE1>)
    {
        open (PAIROUTFILE2, "<$pairWout");
        my @sharedsites;
        my @focal = split /,/, $fline;                  # Generate a focal array
        my @query;					# For the file2 array (when we open it)
        push @cnvsites, scalar $fline;                  ##### Total event No. bp (Focal) #####
        foreach my $qline (<PAIROUTFILE2>)              # Compare to each line of the query
        {   
            @query = split /,/, $qline;                 # Generate a query array
            push @query, @focal;                        # Add the focal array to it to be counted in the hash
            my $sharedsitescount = 0;                   # Count the sites that are shred for each query comparison and add each to
            my $sharedsitespropr = 0;			# Generate the proportion of shared sites given the total No. cnv sites
            foreach (@query)                            # Add each element to the hash and/or count it
            {
                $paireventhash{$_}++;
            }
            while ((my $key, my $value) = each (%paireventhash))
            {
                if ($value == 2)
                {
                    $sharedsitescount++;
                }
                push (@sharedsites, $sharedsitescount); ##### No. Shared sites (Focal / Query) #####
            }
            my $f = scalar @focal;
            my $q = scalar @query;
            if ($f >= $q)                               ##### No. Shared sites (Focal / Query) #####
            {
                $sharedsitespropr = $sharedsitescount / $f
            }
            else
            {
                $sharedsitespropr = $sharedsitescount / $q
            }
            # The Total event No per focal can be printed at the end.
            # Here, save both No. Shared sites (Focal / Query) and No. Shared sites (Focal / Query) to an array
            # to print at the end of this focal indivdial
        }
        close PAIROUTFILE2;
    }
    close PAIROUTFILE1;
    #system("rm temp_pairwise-$rand.MM");
}

# At this stage I should have generated a large file with a line for each indivdiual with each cnv base seperated by a comma.
