#!/usr/bin/perl
use strict;
use warnings;

# Generates contig files (a file for each contig in a fasta) from multiple individuals
# where all of those individuals have been mapped to the same referecnce (i.e. have the same contig references).
# Samples fasta sequences by name from multiple files and creates a new file for each set of sequences.
# Designed to generate contig sets from multiple genome alignments to the same reference.
#
# Folder must only contain fasta files!
# Use fastaCutter.pl to trim sequence names in situations where names are different by a string after the name
#  e.g. >Fasta_spA_Prot1 and Fasta_spA_Prot2 could be reduced to Fasta_spA in both files so that they can be
#  concatenated.
#
# Based on concatinator2.pl which adds seqences from multiple files to the same line.

# Check directory and make a list of fasta files (remove hidden files)
use Getopt::Std;
my %opts;
# accept input directory -d (argument)
getopts('d:r:x:o:f', \%opts);
unless ($opts{d})
{
    print "\n\nDONT put this script in the same directory as your fasta files, put it above that directory\n\n";
    print "\nGenerates contig files (a file for each contig in a fasta) from multiple individuals";
    print "\nwhere all of those individuals have been mapped to the same referecnce";
    print "\n(i.e. have the same contig references).";
    print "\nDesigned to generate contig sets from multiple genome alignments to the same reference.\n";
    print "\nEnter -d  directory of fastas (full path -pwd)\nEnter -r ref.fas \nEnter -x 'regex' for outfile name.\n";
    print "        Use a regex that will find the contig number from the title line of the sequence name\n";
    print "        Try txt2re.com to generate your regular expression.\n";
    print '        Put your regex in single quates.  .*?\d+.*?(\d+) will pull the number out of CONTIG_X_blabla';
    print "\nEnter an outfile name -o\n";
    print "\nYou can also check the script finds all your fasta files by running the -f flag\n\n";
    exit;
}

opendir (DIR, $opts{d}) or die "\nCannot open directory\n$!\n\n";
my @files = readdir DIR;
closedir DIR;
# Remove any hidden files/directory names from @files -> @fastas
my @fastas = ();
foreach my $files (@files)      # push files to @fastas unless start with .
{
    push(@fastas, $files) unless("$files" =~ /^\./);
}


# Check if you have all the files you want
if ($opts{f})
{
    print "\nAre these all your fastas you want to include?\nFastas = @fastas\n\n";
    exit;
}


# Open reference fasta, collect filenames in array.
my @nme = ();   # Store for fasta names
my $filepath = "$opts{d}/$opts{r}";
open(REFFAS, "<$filepath");
foreach my $line (<REFFAS>)
{
    if ($line =~ m/^>/)
    {
        chomp $line;
        push(@nme, "$line");
    }
}


# Foreach title line line ($nme[x]) from the reference,
# take the contig number (_X_) for the outfile name
# open all other files in the directory and pull out matching sequences
mkdir "$opts{d}/$opts{o}_contigs";
foreach my $nme(@nme)               # Foreach title line
{
    my $contig = ();                # Get contig No.
    if ($nme =~ m/$opts{x}/is)
    {
        $contig = $1;
    }
    my $outfilename = "$opts{d}/$opts{o}_contigs/contig_$contig.fas";
    open(OUTFAS, ">$outfilename");
    print OUTFAS "";
    close OUTFAS;
    open(OUTFAS, ">>$outfilename");
    foreach my $fastas(@fastas)
    {
        my $prefix = '((?:[a-z][a-z0-9_]*))';
        if ($fastas =~ m/$prefix/is)
        {
            $prefix = $1;
            my $underscore = '_';
            $prefix = ">$prefix$underscore";
        }
        my $faspath = "$opts{d}/$fastas";
        open(FAS, "<$faspath") or die "can't open this file";
        while (my $fasline = <FAS>)
        {
            chomp $fasline;
            if ($fasline eq "$nme")
            {
                $fasline =~ s/^.//;                 # Remove first character (>)
                print OUTFAS "$prefix$fasline\n";   # Print title line with fasta filename prefix
                my $nextline = <FAS>;
                print OUTFAS "$nextline";
            }
        }
    }
}
