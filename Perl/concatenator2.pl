#!/usr/bin/perl
use strict;
use warnings;

# Concatenates (paste end to end) fasta sequences from mulitple files based on title line (>).
# Will write to a new file -o 
# Will add sequences (of the same name to the end of each line.
# If you want sequences to remain in synteny they must be the same length within each fasta file.
# Folder must only contain fasta files!
# Use fascutter.pl to trim sequence names in situations where names are different by a sting after the name
#  e.g. >Fasta_spA_Prot1 and Fasta_spA_Prot2 could be reduced to Fasta_spA in both files so that they can be
#  concatenated.


# Check directory and make a list of fasta files (remove hidden files)
use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('d:o:', \%opts);
if ($opts{d})
{
    print "\nlocating fastas at $opts{d}\n"
}
else
{
    print "\nConcatenates (paste end to end) fasta sequences from mulitple files based on identity of the title line (>).";
    print "\nIf you want sequences to remain in synteny they must be the same length within each fasta file.";
    print "\n\nFolder must only contain fasta files!";
    print "\n\nEnter -d  directory (full path)";
    print "\nEnter -o outfile name\n\n";
    exit;
}
if ($opts{o})
{
    # blank the output file
    open(OUT, ">$opts{o}");
    print OUT "";
    close (OUT);
}


opendir (DIR, $opts{d}) or die "\nCannot open directory\n$!\n\n";
my @files = readdir DIR;
closedir DIR;
# Remove any hidden files/directory names from @files -> @fastas
my @fastas = ();
foreach my $files (@files)
{
    push(@fastas, $files) unless("$files" =~ /^\./);
}
print "Fastas = @fastas\n\nAre these all your fastas? Are there any other files?\n";


#open fasta[i], collect filenames in array.
my @nme = ();   # Store for fasta names
my $slash = "/";    # To add to the filepath
foreach my $fastas (@fastas)
{
    my $filepath = "$opts{d}$slash$fastas";
    open(FAS, "<$filepath");
    foreach my $line (<FAS>)
    {
        if ($line =~ m/^>/)
        {
            push(@nme, "$line");
        }
    }
}
# Print all fasta names so that the user can see if the sequences are the same
# in each file.
my $AllFastaNames = "names.txt";
open(NAME, ">$AllFastaNames");
print NAME "Check if each file contains the same filename:\n@nme";


# Here we have all the sequence names in @nme.
# Sort sequences into Alpha-numerical order
# Remove duplicate names
# Go though each file to pull out the SEQUENCE for each name
# Add to a given element of an array (based on the name)
my @sortednme = sort(@nme);

# Remove duplicates from @sortednme
shift @sortednme;
my $duplicate = $sortednme[0];
@nme = ();
foreach my $sortednme (@sortednme)
{
    if ($duplicate ne $sortednme)
    {
        push(@nme, $duplicate);
        $duplicate = $sortednme;
    }
}
$duplicate = pop(@sortednme);
push(@nme, $duplicate);

# Go though each file again and add sequence to @seq
my @seq = ();
my $nloops = scalar @nme;                   # count the number of seqs
print "\nIGNORE -Use of uninitialized value in concatenation-\n";
foreach my $fastas (@fastas)
{
    my $filepath = "$opts{d}$slash$fastas";     # Set the filename for this loop
    for (my $i = 0; $i < $nloops; $i++)
    {
        open(FAS2, "<$filepath");
        while (my $line = <FAS2>)
        {
            if ($line eq $nme[$i])
            {
                my $fasline = (<FAS2>);
                $seq[$i] = "$seq[$i]$fasline";
            }
        }
    }
}


# There is a carriage return at the end of each sequence this must be removed
# I retain the carriag return in the sequence name as this is handy
foreach my $seq (@seq)
{
    $seq =~ s/[\n\r\s]+//g;
}


# Print to file if provided
my $stop = scalar @nme;
for (my $i = 0; $i < $stop; $i++)
{
    if ($opts{o})
    {
        open(OUT, ">>$opts{o}");
        print OUT "$nme[$i]$seq[$i]\n";
    }
    else
    {
        print "$nme[$i]$seq[$i]\n";
    }
}
if ($opts{o})
{
    close (OUT);
}
else
{
    print "No output specified (-o)\n"
}
print "\n";
