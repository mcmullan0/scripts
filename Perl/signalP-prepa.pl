#!/usr/bin/perl
use strict;
use warnings;

# Pulls out each gene and its longest mRNA from Hymenoscyphus_fraxineus_v2.0_annotation.grep23.gff3

use Getopt::Std;
my %opts;
getopts('i:t', \%opts);

unless ($opts{i})
{
    print "\n######################################## signalP-prepa ###########################################";
    print "\nPulls out each 'gene' and its longest 'mRNA' transcript from .gff3.";
    print "\n-i Provide .gff3 file";
    print "\n\nIn order to prevent this script failing where output on the negative strand has coordinates in reverse";
    print "\nrun: awk '{if ((\$7==\"+\")||(\$7==\".\")) [print columns 1-9 in order e.g. (\$1\"\\t\"\$2\"\\t...)];\n if (\$7==\"-\") [print (reverse c4 & c5)] input.gff | sort –k1,1 > out";
    print "\n##################################################################################################\n\n";
    exit;
}

# Load first line and save in the geneline holder
# Run through all lines (process mRNA lines) printing on subsequent 'gene' lines
# Iterate one more time for last line (as last line is not followed by 'gene')

my $geneline;   # A holder for the line if it is a "gene" line
my @mrnalines;  # A holder for all lines other than the gene line (and ###)
my @mrnalines2; # A holder for one or more mRNA lines (there can be multiple) that are filtered out of mrnalines
my @mrnalines3; # A holder for all lines after mRNA lines have been removed
my $winner;     # A holder for the longest mRNA transctipt
my $firstline = 1;
my $infile = $opts{i};
open(GFFFILE, "<$infile") or die "cannot open fasta < $infile: $!";
foreach my $line (<GFFFILE>)
{
    chomp $line;
    if ($line =~ m/##gff-version 3/)
    {
        print "$line\n";
    }
    else
    {
        my @separate = split /\s+/, $line;
        if ($firstline == 1)        # If is the first line of the file load it into the geneline holder
        {
            $geneline = $line;
            $firstline = 0;
        }
        else
        {
# If $separate[0] not equal to ### then:
            if ($separate[0] eq "###")
            {
                $separate[2] = "BLANK";
            }
            if ($separate[2] eq "gene")
            {
                foreach my $element (@mrnalines)				# Load each mRNA line into mrnalines2 then systematically remove them. then print the gene line, winner and ramaining lines
                {
                    my @splitelementholder = split /\s+/, $element;		# Split out each element to see if it has mRNA in column 3
                    if ($splitelementholder[0] eq "###")
                    {
                        push @mrnalines3, $element;
                    }
                    elsif ($splitelementholder[2] eq "mRNA")			# If it does move it to a new array and remove it from the original
                    {
                        push @mrnalines2, $element;
                    }
                    else
                    {
                        push @mrnalines3, $element;
                    }
                }
                my $multtranscript2 = scalar(@mrnalines2);			# mRNA line count
                my $multtranscript3 = scalar(@mrnalines3);			# rest lines count
                if ($multtranscript2 == 1)					# If there is just one mRNA then print the gene line, the mRNA line and then the rest of the lines
                {
                    print "$geneline\n$mrnalines2[0]\n";
                    for ( my $i = 0; $i < $multtranscript3; $i++)
                    {
                        print "$mrnalines3[$i]\n";
                    }
                }
                else							        # Else print the gene line, the longest mRNA line ($winner) and then the rest of the lines
                {
                    my $firstforloop = 1;
                    for (my $i = 1; $i < $multtranscript2; $i++)    	        # For each mRNA transcript compare with previous to find largest
                    {
                        my $h = $i-1;
                        if ($firstforloop == 1)     			        # In the first loop find the winner (in subsequent loops use winner from previous loop)
                        {
                            $firstforloop = 0;
                            my @first = split /\s+/, $mrnalines2[$h];
                            my @second = split /\s+/, $mrnalines2[$i];
                            my $flength = $first[4] - $first[3];
                            my $slength = $second[4] - $second[3];
                            if ($flength >= $slength)
                            {
                                $winner = $mrnalines2[$h];
                            }
                            else
                            {
                                $winner = $mrnalines2[$i];
                            }
                        }
                        else
                        {
                            my @first = split /\s+/, $winner;
                            my @second = split /\s+/, $mrnalines[$i];
                            my $flength = $first[4] - $first[3];
                            my $slength = $second[4] - $second[3];
                            if ($slength > $flength)
                            {
                                $winner = $mrnalines2[$i];
                            }
                        }
                    }
                    print "$geneline\n$winner\n";
                    for ( my $i = 0; $i < $multtranscript3; $i++)
                    {
                        print "$mrnalines3[$i]\n";
                    }
                }
                    @mrnalines = ();
                    @mrnalines2 = ();
                    @mrnalines3 = ();
                    $winner = ();
                    $geneline = $line;
            }
            else	                                        # With this else we load all lines into the @mrnalines which we must sort mRNA out of later (above when we hit a 'gene' line
            {
                push @mrnalines, $line;
            }
        }
    }
}
# One lst iteration for the last line:
foreach my $element (@mrnalines)				# Load each mRNA line into mrnalines2 then systematically remove them. then print the gene line, winner and ramaining lines
{
    my @splitelementholder = split /\s+/, $element;		# Split out each element to see if it has mRNA in column 3
    if ($splitelementholder[2] eq "mRNA")			# If it does move it to a new array and remove it from the original
    {
        push @mrnalines2, $element;
    }
    else
    {
        push @mrnalines3, $element;
    }
}
my $multtranscript2 = scalar(@mrnalines2);			# mRNA line count
my $multtranscript3 = scalar(@mrnalines3);			# rest lines counti
if ($multtranscript2 == 1)					# If there is just one mRNA then print the gene line, the mRNA line and then the rest of the lines
{
    print "$geneline\n$mrnalines2[0]\n";
    for ( my $i = 0; $i < $multtranscript3; $i++)
    {
        print "$mrnalines3[$i]\n";
    }
}
else							# Else print the gene line, the longest mRNA line ($winner) and then the rest of the lines
{
    my $firstforloop = 1;
    for (my $i = 1; $i < $multtranscript2; $i++)    	# For each mRNA transcript compare with previous to find largest
    {
        my $h = $i-1;
        if ($firstforloop == 1)     			# In the first loop find the winner (in subsequent loops use winner from previous loop)
        {
            $firstforloop = 0;
            my @first = split /\s+/, $mrnalines2[$h];
            my @second = split /\s+/, $mrnalines2[$i];
            my $flength = $first[4] - $first[3];
            my $slength = $second[4] - $second[3];
            if ($flength >= $slength)
            {
                $winner = $mrnalines2[$h];
            }
            else
            {
                $winner = $mrnalines2[$i];
            }
        }
        else
        {
            my @first = split /\s+/, $winner;
            my @second = split /\s+/, $mrnalines[$i];
            my $flength = $first[4] - $first[3];
            my $slength = $second[4] - $second[3];
            if ($slength > $flength)
            {
                $winner = $mrnalines2[$i];			# If second length is greater than first (previous winner) use second as winner (else winner stays the same).
            }
        }
    }
    print "$geneline\n$winner\n";
    for ( my $i = 0; $i < $multtranscript3; $i++)
    {
        print "$mrnalines3[$i]\n";
    }
}

close(GFFFILE);


# Test.file.gff3
#	##gff-version 3
#	C15937	TGAC_v2.0	gene	1	157	.	+	.	ID=HYMFR746836.2.0_000000010;Name=HYMFR746836.2.0_000000010
#	C15937	TGAC_v2.0	mRNA	1	147	.	+	.	ID=HYMFR746836.2.0_000000010.1;Parent=HYMFR746836.2.0_000000010;Name=HYMFR746836.2.0_000000010.1
#	C15937	TGAC_v2.0	CDS	1	157	.	+	.	ID=HYMFR746836.2.0_000000010.1.cds1;Parent=HYMFR746836.2.0_000000010.1
#	C15937	TGAC_v2.0	exon	1	157	.	+	.	ID=HYMFR746836.2.0_000000010.1.exon1;Parent=HYMFR746836.2.0_000000010.1
#	C15937  TGAC_v2.0       mRNA    1       137     .       +       .       ID=HYMFR746836.2.0_000000010.1;Parent=HYMFR746836.2.0_000000010;Name=HYMFR746836.2.0_000000010.1
#	###
#	C16391	TGAC_v2.0	gene	1	163	.	-	.	ID=HYMFR746836.2.0_000000020;Name=HYMFR746836.2.0_000000020
#	C16391	TGAC_v2.0	mRNA	1	133	.	-	.	ID=HYMFR746836.2.0_000000020.1;Parent=HYMFR746836.2.0_000000020;Name=HYMFR746836.2.0_000000020.1
#	C16391	TGAC_v2.0	CDS	1	163	.	-	.	ID=HYMFR746836.2.0_000000020.1.cds1;Parent=HYMFR746836.2.0_000000020.1
#	C16391	TGAC_v2.0	exon	1	163	.	-	.	ID=HYMFR746836.2.0_000000020.1.exon1;Parent=HYMFR746836.2.0_000000020.1
#	C16391  TGAC_v2.0       mRNA    1       143     .       -       .       ID=HYMFR746836.2.0_000000020.1;Parent=HYMFR746836.2.0_000000020;Name=HYMFR746836.2.0_000000020.1
#	###
#	C16393	TGAC_v2.0	gene	1	163	.	-	.	ID=HYMFR746836.2.0_000000030;Name=HYMFR746836.2.0_000000030
#	C16393	TGAC_v2.0	mRNA	1	133	.	-	.	ID=HYMFR746836.2.0_000000030.1;Parent=HYMFR746836.2.0_000000030;Name=HYMFR746836.2.0_000000030.1
#	C16393	TGAC_v2.0	CDS	1	163	.	-	.	ID=HYMFR746836.2.0_000000030.1.cds1;Parent=HYMFR746836.2.0_000000030.1
#	C16393	TGAC_v2.0	exon	1	163	.	-	.	ID=HYMFR746836.2.0_000000030.1.exon1;Parent=HYMFR746836.2.0_000000030.1
#	C16393  TGAC_v2.0       mRNA    1       143     .       -       .       ID=HYMFR746836.2.0_000000030.1;Parent=HYMFR746836.2.0_000000030;Name=HYMFR746836.2.0_000000030.1
