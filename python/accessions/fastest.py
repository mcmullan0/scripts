#!/usr/bin/env python

# This script was written by Mark under instruction of Larry.
# It takes an accession list and goes to a site (http://www.ebi.ac.uk/ena/da...+accession+...).
# It uses 'PAIRED' to split the text in order to seperate the first and second experiments.
# It then uses a semicolon split to seperate out the first and second fq files.


# module for dealing with urls
import urllib2
# module for dealing with system commands
import sys
# Not sure 
import os

# Variable 'infile' is the first argument after the fasgetter.py command (fasgetter.py would be [0])

# Make an array containing each line (.readlines) of the infile
abpage = urllib2.urlopen("http://www.ebi.ac.uk/ena/data/view/ERS480843")
test = abpage.read()
print (test) 
