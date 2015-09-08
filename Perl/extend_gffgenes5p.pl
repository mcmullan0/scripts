#!/usr/bin/perl
use strict;
use warnings;

# Generates a coordinates .txt file of gene positions and then takes this file and extends features of first 5' end
# of the gene, mRNA, and first exon.

use Getopt::Std;
my %opts;
getopts('g:e:', \%opts);

unless ($opts{g} && $opts{e})
{
    print "\n######################################## extend_gffgenes5p #######################################";
    print "\nGenerates a coordinates .txt of gene positions file fron your gff and then takes this file";
    print "\nand extends features of first 5' end by given length or 1 less than previous gene";
    print "\nIf genes overlap the extension is to that of the previous non-overlapping gene on the same strand";
    print "\nOutput is saved to the gff file prefix with a .txt or ext.txt suffix";
    print "\nEnter:\n  -g <gff file>\n  -e 5' extenstion length";
    print "\n##################################################################################################\n\n";
    exit;
}

# First use awk to print a coordinates .txt file
# Then use this file for the extenstion and print in a new coodinates file
# Last use the new coordinates file to create the new extended.gff

my ($prefix) = $opts{g} =~ /(.*)?\./;
my ($ext) = $opts{g} =~ /(\.[^.]+)$/;

# First use awk to print a coordinates .txt file
system("awk '\$3==\"gene\" {print \$1,\$3,\$4,\$5,\$7,\$9}' $prefix$ext > $prefix.txt");

my $firstline = 0;
my @line1;						# The line containing the gene before the focal gene
my @line2;						# The subsequent line for the gene to be extended
my @prev_plus;						# In case 2 genes overlap this is the last + strand gene preceeding @line1
my @prev_minus;						# In case 2 genes overlap this is the last - strand gene preceeding @line1
my $proximity = 0;
open(TXTFILE, "<$prefix.txt") or die "cannot open fasta < $prefix.txt: $!";
open(OUTFILE, ">$prefix.ext.txt");
foreach my $line (<TXTFILE>)
{
    chomp $line;
    if ($firstline == 1)				# Load the first line in first and then compare pairs of lines
    {
        if ($line1[4] eq '+')				# Put line1 either in the prev+ or prev- depeding on strand in case of overlap
        {
            @prev_plus = @line1;
        }
        else
        {
            @prev_minus = @line1;
        }
        @line1 = @line2;				# Load revious line into line2 and newline into line1
        @line2 = split /\s+/, $line;
        my $plus_or_minus = $line2[4];          	# Which strand we are on is important if genes overlap as we need to find prev
        my $newstart = $line2[2] - 1000;
        if ($newstart <= 0)				# If the gene is close to the beggining of the scaff don't extend past first bp
        {
            $newstart = 1;
        }
        if ($line1[0] eq $line2[0])			# If both genes are from the same scaffold check distance else print
        {
            if ($line1[4] eq $line2[4])			# If both genes are on the same strand check distance else print
            {
                my $less1000 = $line2[2]-$line1[3]-1;	# This gives the number of bp between genes
                if ($less1000 < 0)			# If negative they overlap so extend $opts{e} or to prev gene on same strand
                {
                    if ($plus_or_minus eq '+' && $newstart > $prev_plus[3]) # If + but long way from prev_plus = print
                    {
                        print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=overlap_far+\n";
                    }
                    elsif ($plus_or_minus eq '+' && $newstart <= $prev_plus[3]) # If + but near prev_plus = add 1 to end of prev_plus
                    {
                        $newstart = $prev_plus[3] + 1;
                        print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=overlap_near+\n";
                    }
                    elsif ($plus_or_minus eq '-' && $newstart > $prev_minus[3]) # If - but long way from prev_minus = print
                    {
                        print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=overlap_far-\n";
                    }
                    elsif ($plus_or_minus eq '-' && $newstart <= $prev_minus[3]) # If + but near prev_minus = +1 to end of prev_minus
                    {
                        $newstart = $prev_minus[3] + 1;
                        print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=overlap_near-\n";
                    }
                }
                elsif ($less1000 < $opts{e})		# If samller than $opts{e} then extend to previous end +1
                {
                    $newstart = $line1[3]+1;
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=proximity\n";
                }
                else
                {
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5]\n";
                }
            }
            else					# Else gene1 & gene2 are on diff strands =check end of prev gene of same strand
            {
                if ($plus_or_minus eq '+' && $newstart > $prev_plus[3]) # If + but long way from prev_plus = print
                {
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=Nooverlap_far+\n";
                }
                elsif ($plus_or_minus eq '+' && $newstart <= $prev_plus[3]) # If + but near prev_plus = add 1 to end of prev_plus
                {
                    $newstart = $prev_plus[3] + 1;
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=Nooverlap_near+\n";
                }
                elsif ($plus_or_minus eq '-' && $newstart > $prev_minus[3]) # If - but long way from prev_minus = print
                {
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=Nooverlap_far-\n";
                }
                elsif ($plus_or_minus eq '-' && $newstart <= $prev_minus[3]) # If + but near prev_minus = +1 to end of prev_minus
                {
                    $newstart = $prev_minus[3] + 1;
                    print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5] -here=Nooverlap_near-\n";
                }
            }
        }
        else
        {
            print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5]\n";
            # Also, reset @prev_plus @prev_minus as these will now both contain data from the previous scaffold. Therefore, use @prev_xxx[3] = 0 to force $newstart = $prev_plus[3] + 1 = 1
            @line1 = ("scaff","feature",0,0,"strand");
            @prev_plus = ("scaff","feature",0,0,"strand");
            @prev_minus = ("scaff","feature",0,0,"strand");
        }
    }
    else
    {
        @line2 = split /\s+/, $line;	# (Gets passed to line1 in the next step)
        my $newstart = $line2[2] - 1000;
        if ($newstart <= 0)
        {
            $newstart = 1;
        }
        print OUTFILE "$line2[0]\t$line2[1]\t$newstart\t$line2[3]\t$line2[4]\t$line2[5]\n";
        $firstline = 1;
        $line1[4] = "EMPTY";				# Provide something to line1 instead of + or - to prevent saving to prev_plus
    }
}
close(TXTFILE);
print "\nYour outfiles are:\n$prefix.txt (Gene designation)\n$prefix.ext.txt (extensions)\n\n";

# Testfile
# scaffold1 . gene 44902 46151 . - . ID=First_Gene
# scaffold1 . gene 47537 48736 . - . ID=Second_Gene_not_so_close
# scaffold1 . gene 48836 49856 . + . ID=Third_gene_close_but_on_a_different_strand_so_should_be_47836_not_48737
# scaffold1 . gene 51243 53111 . - . ID=Fourth_gene_not_so_close
# scaffold1 . gene 53702 55361 . + . ID=Fith_gene_not_so_close
# scaffold2 . gene 55500 57000 . - . ID=1st_gene_new_scaff_bumps_previous_gene/scaff_should_be_54500_not_55362
# scaffold3 . gene 850 6223 . + . ID=Now_scaff_new_gene_near_start,_should_be_1
# scaffold3 . gene 950 13064 . + . ID=Next_gene_overlaps_so_should_go_to_1
# scaffold3 . gene 999 15644 . - . ID=Third_gene_also_overlaps_but_now_-_should_still_go_1
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
