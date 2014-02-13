#!/usr/bin/perl -w

use strict;

#Try to find and replace all carriage returns with nothin
#using the substitution operator =~ s/from/to/g
#Must also get the sequence data from file using the filehandle:
#open(Handel, 'filename.txt')

print "\n\nFrom what file would you like to replace carriage returns:\n";

my $fastafilename = <STDIN>;
chomp $fastafilename

#Does the file exist?
if ( -e $fastafilename) {
	print "File \"$fastafilename\" doesn\'t seem to exist!\n";
	exit;
}
open(fasta1, $fastafilename);

close fasta1;
