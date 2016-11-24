#!/usr/bin/env python

import sys
import re

# Pull out the 3rd bp from each codon across all fasta sequences in a fasta file
# Make sure that the file is in frame and has only whole codons


# Get file and name outfile
infile = sys.argv[1]
prefix = infile.split(".fas")
ext = ".3rd.fas"
outfile = prefix[0] + ext

# Open infile read each line and remove first and second base of each codon if not a header
with open(infile, "r") as fi, open(outfile, "w") as fo:
  for line in fi:
    if re.match(r'^>', line):
      fo.write(line)
    else:
      line2 = line[2:][::3] + "\n"
      fo.write(line2)

