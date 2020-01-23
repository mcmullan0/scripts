#!/usr/bin/env bash


# Gets PAML YN00 result for each gene (fasta)
#
# Prints the relevent YN00 runfiles (check settings)
#
# Converts fasta to phylip
# Premature stops unfortuantly mean running YN00 twice (quick)
# Once to identify genes with polyM producing premature stops (and romove from list = fasta.list.stops-removed-${population})
# Second to do the analysis

# Provide a file containing a list of directories you want to analyse
## Directories will contain a fasta file for each gene with entries for each individual/sequence
## Remove any trailing '/' from each line
## Output is stored in present dir no matter the path of the directories provided


RAND=$((1 + RANDOM % 999999))
# -f takes the directory file
# -c states that the control file exists already and to use it and run anyway
CTL=0
while getopts "f:c" opt
do
  case $opt in
    f)
      DIRECTORY_FILE=$OPTARG
      DIRNO=$(cat $DIRECTORY_FILE | wc -l)
      echo "Analysing $DIRNO directories/populations"
      ;;
    c)
      CTL=1
      ;;
  esac
done

if [ -z ${DIRECTORY_FILE+f} ]
then
  echo -ne "\n\n######################################################## paml-yn00-diversity.sh ############################################################\n"
  echo -ne "# Uses a directory of (multi-individual) gene fastas to return average dnds (YN00) for each gene\n"
  echo -ne "# Can be run on multiple directories (or populaitons)\n"
  echo -ne "# (Run after vcf2gene.sh)\n"
  echo -ne "# Requires:\n"
  echo -ne "#\t-f a file containing the full path to each population directory\n"
  echo -ne "#\t\tDirectories will contain a fasta file for each gene with entries for each individual/sequence\n"
  echo -ne "#\t\tRemove any trailing '/' from each line\n"
  echo -ne "#\t-c if you don't want this script to print a YN00 control file (if you have one of your own).\n"
  echo -ne "# Accepts output from vcf2gene.sh which generates gene fastas from a vcf and a reference fasta genome\n"
  echo -ne "#\tConverts fasta to phylip\n"
  echo -ne "#\tIdentifies genes with a premature stop codon polymorphism (see POPULATION.stops-present.list) which are not run\n"
  echo -ne "#\tRuns all remaining genes through YN00 and calculates the mean dnds see POPULATION.yn00.mean.txt\n"
  echo -ne "#\t\t<POPULATION> comes from the name of the directory listed in -f\n"
  echo -ne "#\t\tWhich is expected to appear POPULATION__outputdir\n"
  echo -ne "# Output is stored in present dir\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi




PAMLCTL='yn00.ctl'
if [ $CTL -eq "0" ]
then
  if [ -f "$PAMLCTL" ]
  then
    echo -e "\n\n$PAMLCTL exists"
    echo -e "You may want to use your own yn00.ctl which is already in the directory.\nIf so add the -c option"
    echo -e "However, plese add 'MM.sedreplace.MM' and 'MM.sedreplace.MM' to as seqfile and outfile entries\n"
    exit
  else
    echo "producing yn00.ctl file"
    echo -e "      seqfile = MM.sedreplace.MM * sequence data file name\n      outfile = MM.sedreplace.MM.yn           * main result file\n      verbose = 0  * 1: detailed output (list sequences), 0: concise output\n\n        icode = 0  * 0:universal code; 1:mammalian mt; 2-10:see below\n\n    weighting = 0  * weighting pathways between codons (0/1)?\n   commonf3x4 = 0  * use one set of codon freqs for all pairs (0/1)?\n*       ndata = 1\n\n\n* Genetic codes: 0:universal, 1:mammalian mt., 2:yeast mt., 3:mold mt.,\n* 4: invertebrate mt., 5: ciliate nuclear, 6: echinoderm mt.,\n* 7: euplotid mt., 8: alternative yeast nu. 9: ascidian mt.,\n* 10: blepharisma nu.\n* These codes correspond to transl_table 1 to 11 of GENEBANK.\n" > $PAMLCTL
  fi
fi

#  This generates new directories and converts fasta files in original dirs to Phylip
## Assumes the old directory name  ends in ..._outputdir
### Pangenome: In the case that the individuals with this gene are not present in this analysis
### count lines in the fasta to determine whether to use it.
while read DIRECTORY
do
  HOLDER=$(echo "${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  mkdir -p "$NEWDR"
  ls $DIRECTORY/*.fas | awk -F '/' '{print $NF}' | cut -d '.' -f 1 > ${NEWDR}.fas.list
  source fastx_toolkit-0.0.13.2
  submit-slurm.pl -j phy-mm_${NEWDR} -i "\
  cd ${NEWDR}
  while read FAS
  do
    EMPTY=\$(cat ${DIRECTORY}/\${FAS}.fas | wc -l)
    if [ \${EMPTY} -ne \"0\" ]
    then
      fastx_collapser -i ${DIRECTORY}/\${FAS}.fas | Fasta2Phylip.pl - \${FAS}.temp
      cat <(sed -n '1p' \${FAS}.temp | awk '{l=\$2-3; print \$1,l}') <(sed '1d' \${FAS}.temp | sed 's/...\$//') | sed \$'s/\t/  /' > \${FAS}.phy
      rm \${FAS}.temp
    else
      echo -e \"${NEWDR} \${FAS}.fas has zero haplotypes in this population/set.\"
    fi
  done < ../${NEWDR}.fas.list
  cd ../"
done < $DIRECTORY_FILE

## Await completion of previos jobs
CONTINUE=$(squeue -u mcmullam | grep -c 'MM-phy-m')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (population fasta to phylip convrsions)."
while [ $CONTINUE -gt "0" ]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u mcmullam | grep -c 'MM-phy-m')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (population fasta to phylip convrsions)."
done

# Running YN00 through once to check for premature stop codons.
# These genes won't be run through paml to collect dnds data.
# However they will be stored in a file called POPULATION.fas.stops-present.list

echo -e "\n\nRunning YN00\nFirst to check for premature stop codons which won't be run through paml to collect dnds data. However they will be stored in POPULATION.fas.stops-present.list and removed from ${NEWDR}.fas.stops-removed.list.\nSecond to collect dnds information\n\n"

source paml-4.9
while read DIRECTORY
do
  HOLDER=$(echo "../${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  # Make a list of genes which I can remove genes with early stop codons from and a list that contains them.
  cp ${NEWDR}.fas.list ${NEWDR}.fas.stops-removed.list
  > ${NEWDR}.fas.stops-present.list
  submit-slurm.pl -j yn00-mm_${NEWDR} -i "cd $NEWDR
  while read GENES
  do 
    sed \"s/MM\.sedreplace\.MM/\${GENES}.phy/\" ../yn00.ctl > yn00-run_${HOLDER}-\${GENES}.ctl
    echo -e \"$DIRECTORY\n$HOLDER\n$NEWDR\n\${GENES}\"
    wc -l yn00-run_${HOLDER}-\${GENES}.ctl
    STOP=\$(yn00 yn00-run_${HOLDER}-\${GENES}.ctl | grep 'stop codon' | wc -l)
    echo \"\$GENES \$STOP\"
    if [ \$STOP -eq \"0\" ]
    then
      echo \"no stops\"
      yn00 yn00-run_${HOLDER}-\${GENES}.ctl
      BBOYS=\$(wc -l \${GENES}.phy | awk '{n=\$1-1; b=(n*(n-1))/2; l=7+b; print l}')
      grep -A \$BBOYS \"(B) Yang & Nielsen (2000) method\" \${GENES}.phy.yn > \${GENES}.phy.yn.yn00
    else
      echo \"stops\"
      grep -v \$GENES ../${NEWDR}.fas.stops-removed.list > MM.stops.removed.MM-\${GENEs}-${NEWDR}; mv MM.stops.removed.MM-\${GENEs}-${NEWDR} ../${NEWDR}.fas.stops-removed.list
      echo \"\${GENES}\" >> ../${NEWDR}.fas.stops-present.list
    fi
  done < ../${NEWDR}.fas.list
  rm *.phy yn00-run_*.ctl rst* rub 2YN*
  cd ../"
done < $DIRECTORY_FILE


## Await completion of previos jobs
CONTINUE=$(squeue -u mcmullam | grep -c 'MM-yn00-')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (YN00)."
while [ $CONTINUE -gt "0" ]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u mcmullam | grep -c 'MM-yn00-')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (YN00)."
done

echo -e "\nGenerating a table of mean dnds for each gene (ds>0)\n"
# Collect data (mean dnds) from the YN00 output
# If there was no output print NA
# If after removal of all of the ds=0 values (causing dnds=99) there are no lines print NA

while read DIRECTORY
do
  HOLDER=$(echo "../${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  submit-slurm.pl -j mean_${NEWDR} -i "cd $NEWDR
  while read STOPSREMOVED
  do
    NOLINE8=\$(cat \${STOPSREMOVED}.phy.yn.yn00 | wc -l | awk '{k=\$1-8; print k}')
    echo \"\$STOPSREMOVED\"
    if [ \"\$NOLINE8\" -eq \"0\" ]
    then
      echo -e \"NA\tNA\tNA\tNA\tNA\tNA\tNA\"
    else
      tail -n \$NOLINE8 \${STOPSREMOVED}.phy.yn.yn00 | awk '\$11>0' > MM.\${STOPSREMOVED}.phy.yn.yn00.ds-gt0.MM
      NOLINEMORE=\$(cat MM.\${STOPSREMOVED}.phy.yn.yn00.ds-gt0.MM | wc -l)
      if [ \"\$NOLINEMORE\" -eq \"0\" ]
      then
        echo -e \"NA\tNA\tNA\tNA\tNA\tNA\tNA\"
      else
        awk -v OFS='\t' '{S+=\$3; N+=\$4; t+=\$5; kappa+=\$6; omega+=\$7; dN+=\$8; dS+=\$11} END {print S/NR, N/NR, t/NR, kappa/NR, omega/NR, dN/NR, dS/NR}' MM.\${STOPSREMOVED}.phy.yn.yn00.ds-gt0.MM
      fi
    fi
  done < ../${NEWDR}.fas.stops-removed.list | paste - - > MM.temp.yn00.out-${NEWDR}.MM
  # Add headers and clean up
  cat <(echo -e \"Gene\tS\tN\tt\tkappa\tomega\tdN\tdS\") MM.temp.yn00.out-${NEWDR}.MM > ../${NEWDR}.yn00.mean.txt
  rm MM.temp.yn00.out-${NEWDR}.MM
  cd ../
  rm -r $NEWDR"
done < $DIRECTORY_FILE

## Await completion of previos jobs
CONTINUE=$(squeue -u mcmullam | grep -c 'MM-mean')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (table generation and cleanup)."
while [ $CONTINUE -gt "0" ]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u mcmullam | grep -c 'MM-mean')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (table generation and cleanup)."
done

mkdir paml-yn00-diversity_slurmout
mv phy-mm*.slurm yn00-mm*.slurm mean_*.slurm *yn00.fas.list *.stops-present.list paml-yn00-diversity_slurmout
rm *.stops-removed.list

echo -ne "\n\n\tRun complete\n\n"

exit


