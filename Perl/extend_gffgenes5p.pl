#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Tie::File;
# Generates a coordinates .txt file of gene positions and then takes this file and extends features of first 5' end
# of the gene, mRNA, and first exon.
# Added Tie::File feature which can load each line into an array.  It apparently doesn't load it all into memory though..

my %opts;
getopts('g:i:e:', \%opts);

unless ($opts{g} && $opts{i} && $opts{e})
{
    print "\n######################################## extend_gffgenes5p #######################################";
    print "\nGenerates a coordinates .txt of gene positions file fron your gff and then takes this file";
    print "\nand extends features of first 5' end by given length or 1 less than previous gene";
    print "\nIf genes overlap the extension is to that of the previous non-overlapping gene on the same strand";
    print "\nOutput is saved to the gff file prefix with a .txt or ext.txt suffix";
    print "\nEnter:\n  -g <genome.fa> for scaffold lengths\n  -i <gff file>\n  -e 5' extenstion length";
    print "\n\nNB.  This script will fail to produce propper output where more than two genes overlap within extension area";
    print "\n##################################################################################################\n\n";
    exit;
}

# 1 use awk to print a coordinates .txt file
# 2 Then use this file for the extenstion and print in a new coodinates file
# 	> 1.1 This requires that we know scaffold lengths so now we need to load the genome.fa...
# 3 use the new coordinates file to create the new extended.gff
# 4 use new coordinates file to print new extended gff

my ($prefix) = $opts{i} =~ /(.*)?\./;			# Get prefix for outfiles
my ($ext) = $opts{i} =~ /(\.[^.]+)$/;			# Get extension for outfile

### 1 use awk to print a coordinates .txt file
system("awk '\$3==\"gene\" {print \$1,\$3,\$4,\$5,\$7,\$9}' $prefix$ext > $prefix.txt");
my @gfftxtfile;                                         # Array of $prefix.txt allows us to look ahead in .gff to find next - gene
tie @gfftxtfile, 'Tie::File', "$prefix.txt";


###	> 1.1 This requires that we know scaffold lengths so now we need to load the genome.fa...
print STDERR "\nextend_gffgenes5p:\nCreating genome.fa index...\n";
my @fasseqs;
my @scafflengths;
my %scaff_lenghts;					# A hash of scaffold names (key) and lengths (values)
tie @fasseqs, 'Tie::File', "$opts{g}";

my $scaff_hash;
my $length_hash;
foreach my $element (@fasseqs)
{
    if ($element =~ m/^>/)
    {
        my @temp = split /\s+/, $element;		# Split because the scaffld name had a space in it and some extra unwanted data
        $scaff_hash = $temp[0];
        $scaff_hash = reverse $scaff_hash;
        chop $scaff_hash;
        $scaff_hash = reverse $scaff_hash;
    }
    else
    {
        $length_hash = length($element);
        $scaff_lenghts{$scaff_hash} = $length_hash;
    }
}
untie @fasseqs;
my $no_scaffs = scalar(keys %scaff_lenghts);
print STDERR "\nIndex created\nThere are $no_scaffs sequences in $opts{g}.\n";
print STDERR "\nGenerating extended positions file:\n($prefix.ext.txt)...\n\n";


### 2 print extensions in a new coodinates file
my $line_tiefile = -1;					# Counter to identify which line we are on in the gff txt file array.
my $lgfftxtfile = scalar(@gfftxtfile);			# So we know when we have reached the end of the gff file (-gene)
my $firstline = 1;
my @line2;						# The focal line (line 1 was replaced with prev + prev -)
my @prev_plus;						# In case 2 genes overlap this is the last + strand gene preceeding @line1
my $prev_plus_empty = 0;				# Have we seen a plus gene in this scaffold yet?
my @prevprev_plus;                                      # The plus before the previous (incase of an overlap)
my $prevprev_plus_empty = 0;
my @prev_minus;						# In case 2 genes overlap this is the next - strand gene preceeding @line1
my $newstart;						# The new start position of a gene (usually old start - $opts{e}
#my $proximity = 0;
open(TXTFILE, "<$prefix.txt");
open(OUTFILE, ">$prefix.ext.txt");
foreach my $line (<TXTFILE>)
{
    chomp $line;
    $line_tiefile++;
    my @precurser = split /\s+/, $line;
    
    my $plus_or_minus = $precurser[4];                  # Which strand we are on (+) or (-)
    if ($firstline == 0)				# Load the first line in first and then compare pairs of lines
    {
        if ($line2[4] eq '+')
        {
            if ($prev_plus_empty == 1)			# Keep the previous precurser in case precurser overlaps with line 2
            {
                @prevprev_plus = @prev_plus;
                $prevprev_plus_empty = 1;
            }
            @prev_plus = @line2;
            $prev_plus_empty = 1;
        }
        @line2 = @precurser;
        if ($plus_or_minus eq "+")			# Split script in to + and - to search left or right for prev gene
####################################################### extend LHS ###################################################
        {
            $newstart = $line2[2] - $opts{e};
            if ($newstart < 1)                         			# Don't extend past first bp
            {
                $newstart = 1;
            }
            elsif ($prev_plus_empty == 1 && $newstart != 1)		# Check for prev gene on same scaff else print newsetar
            {
                if ($line2[0] eq $prev_plus[0])
                {
                    my $already_overlap = $line2[2] - ($prev_plus[3]+1);
                    if ($already_overlap < 0 && $prevprev_plus_empty == 1)# If our gene & prev + overlap && use prevprev+ if availible
                    {
                        @prev_plus = @prevprev_plus;
                        $prevprev_plus_empty = 0;
                    }
                    my $less1000 = $newstart-($prev_plus[3]+1);		# This gives the number of bp between genes
                    if ($less1000 < 0)                      		# If negative they overlap = extend $opts{e} to prev gene
                    {
                        $newstart = $prev_plus[3] + 1;
                    }
                }
                else
                {
                    $prev_plus_empty = 0;
                    $prevprev_plus_empty = 0;
                }
            }
            print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5]\n";
        }
        else
######################################################## extend RHS ###################################################
        {
            # find the next negative ON SAME SCAFF, if next scaff get the scaff end position, ADD $opts{e} to $line2[3], if $line2[3] > scaff length $line2[3] = scaff length
            $newstart = $line2[3] + $opts{e};
            my $current_scaff = $line2[0];
            my $end_of_current_scaff = $scaff_lenghts{$current_scaff};
            if ($newstart > $end_of_current_scaff)			# Don't extend past last bp
            {
                $newstart = $end_of_current_scaff;
            }
            elsif ($newstart = $end_of_current_scaff)
            {								# For while loop:
                my $next_neg = "+";                                     	# Start as a plus highlight when we find a minus
                my $startfrom = $line_tiefile;					# Start counting from the line we are on
                my $leavloop_nextstartfrom = $startfrom;		# A hacky way to leave the loop as $startfrom++ is at start
                # Move through gff txt file from next position until we find the next -ve
                while ($next_neg eq "+" && $startfrom < $lgfftxtfile && $leavloop_nextstartfrom < $lgfftxtfile)
                {
                    $startfrom++;
                    @prev_minus = split /\s+/, $gfftxtfile[$startfrom];
                    $next_neg = $prev_minus[4];
                    $leavloop_nextstartfrom = $startfrom + 1;
                }
		# If found a - on same scaff, before gff txt file end and -gene start overlaps with next- end continue search
                if ($next_neg eq "-" && $line2[0] eq $prev_minus[0] && $line2[3] > $prev_minus[2])
                {
                    $next_neg = "+";
                    while ($next_neg eq "+" && $startfrom < $lgfftxtfile)
                    {
                        $startfrom++;
                        @prev_minus = split /\s+/, $gfftxtfile[$startfrom];
                        $next_neg = $prev_minus[4];
                    }
                }
                # If we found a - on same scaff, before gff txt file end and it is greater than beg of next gene reduce
                if ($next_neg eq "-" && $line2[0] eq $prev_minus[0] && $newstart > $prev_minus[2])
                {
                    $newstart = $prev_minus[2] - 1;
                }
            }
            print OUTFILE "$line2[0]\t$line2[1]\t$line2[2]\t$newstart\t$line2[4]\t$line2[5]\n";
        }
    }
    else 								# This is the first line of the input run seperatly
    {
        @line2 = @precurser;        			
        if ($plus_or_minus eq '+')					# If + else -
######################################################## extend LHS ###################################################
        {
            $newstart = $line2[2] - $opts{e};
            if ($newstart < 1)
            {
                $newstart = 1;
            }
            print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5]\n";
        }
        else								# Else it negative find the next negative or end of scaffold
######################################################## extend RHS ###################################################
        {
            # find the next negative ON SAME SCAFF, if next scaff get the scaff end position, ADD $opts{e} to $line2[3], if $line2[3] > scaff length $line2[3] = scaff length
            $newstart = $line2[3] + $opts{e};
            my $end_of_current_scaff = $scaff_lenghts{$line2[0]};
            if ($newstart > $end_of_current_scaff)
            {
                $newstart = $end_of_current_scaff;
            }
            else
            {
                my $next_neg = "+";
                my $startfrom = $line_tiefile;
                while ($next_neg eq "+" && $startfrom < $lgfftxtfile)
                {
                    $startfrom++;
                    @prev_minus = split /\s+/, $gfftxtfile[$startfrom];
                    $next_neg = $prev_minus[4];
                }
                if ($next_neg eq "-" && $line2[0] eq $prev_minus[0] && $line2[3] > $prev_minus[2])
                {
                    $next_neg = "+";
                    while ($next_neg eq "+" && $startfrom < $lgfftxtfile)
                    {
                        $startfrom++;
                        @prev_minus = split /\s+/, $gfftxtfile[$startfrom];
                        $next_neg = $prev_minus[4];
                    }
                }
                if ($next_neg eq "-" && $line2[0] eq $prev_minus[0] && $newstart > $prev_minus[2])
                {
                    $newstart = $prev_minus[2] - 1;
                }
            }
            print OUTFILE "$line2[0]\t$line2[1]\t$line2[2]\t$newstart\t$line2[4]\t$line2[5]\n";
        }
        $firstline = 0;
    }
}
close(TXTFILE);
untie @gfftxtfile;
print "\nYour outfiles are:\n$prefix.txt (Gene designation)\n$prefix.ext.txt (extensions)\n\n";

# The genome file was cha_soap_ope_lmp_k111r.scafSeq.fasta
# Testfile
# scaffold1 . gene 44902 46151 . - . ID=First_Gene
# scaffold1 . gene 47537 48736 . - . ID=Second_Gene_not_so_close
# scaffold1 . gene 48836 49856 . + . ID=Third_gene_close_but_on_a_different_strand_so_should_be_47836_not_48737
# scaffold1 . gene 51243 53111 . - . ID=Fourth_gene_not_so_close
# scaffold1 . gene 53702 55361 . + . ID=Fith_gene_not_so_close
# scaffold2 . gene 55500 57000 . - . ID=1st_gene_new_scaff_bumps_previous_gene/scaff_should_be_54500_not_55362
# scaffold3 . gene 850 6223 . + . ID=Now_scaff_new_gene_near_start,_should_be_1
# scaffold3 . gene 950 13064 . + . ID=Next_gene_overlaps_so_should_go_to_1
# scaffold3 . gene 15745 18357 . + . ID=Fourth_gene
# scaffold3 . gene 19285 23358 . + . ID=Fifth
# scaffold4 . gene 93004 96068 . + . ID=First
# scaffold4 . gene 97774 100985 . - . ID=Second
# scaffold4 . gene 103458 105308 . + . ID=Third
# scaffold4 . gene 104037 106495 . - . ID=Fourth
# scaffold4 . gene 106808 108235 . + . ID=Fifth
# scaffold5 . gene 69161 70353 . - . ID=First
# scaffold5 . gene 71000 75791 . + . ID=Second_overlap_with_firs_but_is_not_on_the_same_stand_should_be_70000
# scaffold5 . gene 75957 84122 . + . ID=Third,_will_overlap_second_so_should_start_at_75792
# scaffold5 . gene 84000 87411 . + . ID=Fourth_overlap_third_but_further_from_second_so_should_be_83000
# scaffold5 . gene 89406 91475 . + . ID=Fifth
# scaffold5 . gene 71000 75791 . + . ID=Second_overlap_with_firs_but_is_not_on_the_same_stand_should_be_70000
# scaffold6 . gene 75657 77567 . - . ID=First,_will_overlap_second_so_should_start_at_before_77900_(Third)
# scaffold6 . gene 77001 77800 . - . ID=Second_overlap_first_and_close_to_third_so_should_be_77899
# scaffold6 . gene 77900 3444800 . - . ID=Third_Should_end_at_scaffold_end_3444827
