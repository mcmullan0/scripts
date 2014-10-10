#!/usr/bin/perl
use strict;
use warnings;


# Run after fast2column.pl so that you can iterate through rows of base 1, 2, 3, etc.
# This script contains a usful tally counter (hash) you might want to use again in the future
# NB if we find multiple Hetz sites or more than 3 SNPs in a base position we score that as an 'N' (or 1)

use Getopt::Std;
my %opts;
# accept input file -i (argument)
getopts('i:', \%opts);

if ($opts{i})
{
    if (open(INFILE, $opts{i}))
    {
        my %header_data;
        my @headers_in_order = ("MSNP", "MSNP_Ind", "mSNP", "mSNP_Ind", "HSNP", "HSNP_Ind", "indel", "ambig", "total", "SNP", "Hetz", "ignore");
        my @numberic_headers_in_order = ("MSNP_Ind", "mSNP_Ind", "HSNP_Ind", "indel", "ambig");
        my @homz = ("A", "T", "C", "G");
        my @hetz = ("M", "R", "W", "S", "Y", "K");
        my @ambiguity = ("V", "H", "D", "B", "N");
        my $indel = "-";
        foreach my $line (<INFILE>)
        {
            my %polyM= ();                  # Open a hash table for polymorphisms
            foreach (@headers_in_order)     # Reset header data to X to highlight if it has not beed delt with.
            {
                $header_data{$_} = 'X';
            }
            $header_data{'ambig'} = 0;    # As yet no 3-fold ambigious sites
            $header_data{'indel'} = 0;
            my $Hcounter = 0;
            my $hcounter = 0;       # Count Homz sites if just 1 then set mSNP and mSNP_Ind to 0
            chomp $line;
            if ($line =~ m/^>/)
            {
                print "# Population level polyM data for:\n#$line\n#MSNP,MSNP_Ind,mSNP,mSNP_Ind,HSNP,HSNP_Ind,Indel,Ambig,Total,SNP,Hetz,ignore\n";
            }
            else
            {
                my @bp = split(/,/, $line);
                # Tally each base at that position
                foreach (@bp)
                {
                    $polyM{$_}++;
                }
                # Now I will deal with the base types (headers) in the hash
                # Is there an indel?
                if (exists $polyM{$indel})
                {
                    $header_data{'indel'} = 1;
                }
                # Are there any Hetz sites
                $Hcounter = 0;       # Count Hetz sites if more than 1 then set ambig to '1'
                $header_data{'HSNP'} = 0;
                $header_data{'HSNP_Ind'} = 0;
                foreach (@hetz)
                {
                    if (exists $polyM{$_})
                    {
                        $Hcounter++;
                        $header_data{'HSNP'} = $_;
                        $header_data{'HSNP_Ind'} = $polyM{$_};
#                        print "\n\nHetz sites? $header_data{'HSNP'} x $header_data{'HSNP_Ind'}\n";
                    }
                }
                # More than one Hetz site (3 SNPs)?
#                print "\nHcounter = $Hcounter";
                if ($Hcounter > 1)
                {
                    $header_data{'ambig'}++;
                }
                # Any 3 base ambiguity codes?
                foreach (@ambiguity)
                {
                    if (exists $polyM{$_})
                    {
                        $header_data{'ambig'}++;
                    }
                }
                # Remaining we have true bases, either one Major or a Major/minor
                # I could pull out the A, T, C, G but then I could still pull out one OR two
                # First store each base in a temporary holder then ask which is Major and minor to store in %header_data hash
                my $temp1base;
                my $temp1baseNo;
                my $temp2base;
                my $temp2baseNo;
                foreach (@homz)
                {
                    if (exists $polyM{$_})
                    {
                        # First store either 1st and second base in temporary holders
                        $hcounter++;
                        if ($hcounter == 1)
                        {
                            $temp1base = $_;
#                            print "\nThis should be a base = $_";
                            $temp1baseNo = $polyM{$_};
#                            print "\nThis should be the number of bases = $temp1baseNo\n";
                        }
                        elsif ($hcounter == 2)
                        {
                            $temp2base = $_;
#                            print "\nThis should be another base = $_";
                            $temp2baseNo = $polyM{$_};
#                            print "\nThis should be the number of other bases = $temp2baseNo\n";
                        }
                        else
                        {
                            $header_data{'ambig'}++;
                        }
                        if ($hcounter > 1)
                        {
                            if ($temp1baseNo >= $temp2baseNo)
                            {
                                $header_data{MSNP} = $temp1base;
                                $header_data{MSNP_Ind} = $temp1baseNo;
                                $header_data{mSNP} = $temp2base;
                                $header_data{mSNP_Ind} = $temp2baseNo;
                            }
                            else
                            {
                                $header_data{MSNP} = $temp2base;
                                $header_data{MSNP_Ind} = $temp2baseNo;
                                $header_data{mSNP} = $temp1base;
                                $header_data{mSNP_Ind} = $temp1baseNo;
                            }
                        }
                        else
                        {
                            $header_data{MSNP} = $temp1base;
                            $header_data{MSNP_Ind} = $temp1baseNo;
                            $header_data{mSNP} = 0;
                            $header_data{mSNP_Ind} = 0;
                        }
                        # Get total No Ind (will be less than true total if we have multiple 3-fold amb sites)
                        my $temptotal = 0;
                        foreach (@numberic_headers_in_order)
                        {
                            #print "should print all numberic headers = $numberic_headers_in_order[$_]\n";
                            $temptotal = $temptotal + $header_data{$_};
                        }
                        $header_data{total} = $temptotal;
                    }
                }
                # Print %header_data
                $header_data{SNP} = $hcounter - 1;	# This is here becuase I count bases. An 'A' at a site is 1 base but it is 0 SNPs so 1-1=0SNPs
                $header_data{Hetz} = $Hcounter;
                $header_data{ignore} = 0;
                if ($header_data{'indel'} || $header_data{'ambig'} >= 1)
                {
                    $header_data{ignore} = 1;
                    $header_data{SNP} = 0;		# Without this SNPs will = -1 becuase of '$header_data{SNP} = $hcounter - 1' above 
                }
                print "$header_data{MSNP},$header_data{MSNP_Ind},$header_data{mSNP},$header_data{mSNP_Ind},$header_data{'HSNP'},$header_data{'HSNP_Ind'},$header_data{'indel'},$header_data{'ambig'},$header_data{total},$header_data{SNP},$header_data{Hetz},$header_data{ignore}\n";     # if exists $polyM{$indel};
                #This is the printline of the tally of the data.
#                my $printline = "";
#                foreach (reverse sort {$polyM{$a} <=> $polyM{$b}} keys %polyM)
#                {
#                    $printline = "$printline$_,$polyM{$_},";
#                }
#                print "$printline\n";
            }
        }
    }
    else
    {
        print "\nI Can't open file\nClosing script\n\n";
        exit;
    }
}
else
{
    print "\nThe Second sliding window script designed to print a hash table per row of data";
    print "\nRun after fast2column.pl so that you can iterate through rows of base 1, 2, 3, etc.";
    print "\nConsider running fastchar.pl to remove character data from the fasta?";
    print "\nEnter infile -i (produces at tempMM files)\n\n";
    exit;
}
