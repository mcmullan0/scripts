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
infile = open(sys.argv[1])

# Make an array containing each line (.readlines) of the infile
accession_list = infile.readlines()
infile.close()
for accession in accession_list:                # For varriable in array
    accession = accession.replace("\n","")      # Remove newline (at the end of line) then go to url
    abpage = urllib2.urlopen("http://www.ebi.ac.uk/ena/data/warehouse/filereport?accession="+accession+"&result=read_run&fields=study_accession,secondary_study_accession,sample_accession,secondary_sample_accession,experiment_accession,run_accession,scientific_name,instrument_model,library_layout,fastq_ftp,fastq_galaxy,submitted_ftp,submitted_galaxy,col_tax_id,col_scientific_name,reference_alignment")
    readpage = abpage.read()                    # store page text in variable
    pairedsplit = readpage.split("PAIRED")      # split expereiment 1 and 2 based on text PAIRED
    try:
	print ("\n"+accession)
	colonsplit = pairedsplit[1].split(";")      # split fq 1 and 2 based on ;
        os.system ("ftp ftp://"+colonsplit[0].replace("\t", ""))    # download each fq in exp 1 (remove tab)
        os.system ("ftp ftp://"+colonsplit[1].split()[0])
        #print ("ftp ftp://"+colonsplit[0].replace("\t", ""))    # download each fq in exp 1 (remove tab)
        #print ("ftp ftp://"+colonsplit[1].split()[0])
	
    except:
        print ("\n\n\n\nPlease check "+accession+" as there appears to be no experiment 1")
    try:
        colonsplit = pairedsplit[2].split(";")                      # split exp 2 based on ;
        os.system ("ftp ftp://"+colonsplit[0].replace("\t", ""))    # download each fq in exp 2
        os.system ("ftp ftp://"+colonsplit[1].split()[0])
        #print ("ftp ftp://"+colonsplit[0].replace("\t", ""))    # download each fq in exp 2
        #print ("ftp ftp://"+colonsplit[1].split()[0])

    except:
        print ("\n\n\n\nPlease check "+accession+" as there appears to be no experiment 2")
