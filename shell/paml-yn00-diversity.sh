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
kleen=0
# FYI $USER is assumed to be set to the current user for checking when jobs have finished in the queue

while getopts "f:ck" opt
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
    k)
      kleen=1
      ;;
  esac
done


if [[ -z ${DIRECTORY_FILE+f} ]]
then
  echo -ne "\n\n######################################################## paml-yn00-diversity.sh ############################################################\n"
  echo -ne "# Uses a directory of (multi-individual) gene fastas to return average dnds (YN00) for each gene\n"
  echo -ne "# Can be run on multiple directories (or populations)\n"
  echo -ne "# (Run after vcf2gene.sh)\n"
  echo -ne "# Requires:\n"
  echo -ne "#\t-f a file containing the full path to each population directory\n"
  echo -ne "#\t   Directories will contain a fasta file for each gene with entries for each individual/sequence\n"
  echo -ne "#\t   Remove any trailing '/' from each line\n"
  echo -ne "#\t-c if you don't want this script to print a YN00 control file (if you have one of your own).\n"
  echo -ne "#\t-k if you want to keep all the intermediate phylip and YN00 control files and output.\n"
  echo -ne "# Accepts output from vcf2gene.sh which generates gene fastas from a vcf and a reference fasta genome\n"
  echo -ne "#\tConverts fasta to phylip\n"
  echo -ne "#\tIdentifies genes with a premature stop codon polymorphism (see POPULATION.fas.stops-present.list) which are not run\n"
  echo -ne "#\tIdentifies genes with CDS not a multiple of 3 (codon) caused by models that ae 'incomplete CDS' and shortens to 3\n"
  echo -ne "#\tRuns all remaining genes through YN00 and calculates the mean dnds see POPULATION.yn00.mean.txt\n"
  echo -ne "#\t\t<POPULATION> comes from the name of the directory listed in -f\n"
  echo -ne "#\t\tWhich is expected to appear POPULATION_outputdir\n"
  echo -ne "#\tInfo field records:\n"
  echo -ne "#\t\tPolyM\n"
  echo -ne "#\t\tNoPolyM\n"
  echo -ne "#\t\tStoPolyM\t-stop present as polymorphism -no YN00 data\n"
  echo -ne "#\t\tCDSincmp\t-PolyM + incomplete CDS idnetified by CDS not multiple of 3 (not a catch all)\n"
  echo -ne "#\t\tINFINITY\t-Division by zero (ds=o dn>0) takes precedence over previous\n"
  echo -ne "# Output is stored in present dir\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi


PAMLCTL='yn00.ctl'
if [[ "$CTL" -eq "0" ]]
then
  if [[ -f "$PAMLCTL" ]]
  then
    echo -e "\n\n$PAMLCTL exists"
    echo -e "You may want to use your own yn00.ctl which is already in the directory.\nIf so add the -c option"
    echo -e "However, plese add 'MM.sedreplace.MM' and 'MM.sedreplace.MM' to as seqfile and outfile entries\n"
    exit 1
  else
    echo "producing yn00.ctl file"
    echo -e "      seqfile = MM.sedreplace.MM * sequence data file name\n      outfile = MM.sedreplace.MM.yn           * main result file\n      verbose = 0  * 1: detailed output (list sequences), 0: concise output\n\n        icode = 0  * 0:universal code; 1:mammalian mt; 2-10:see below\n\n    weighting = 0  * weighting pathways between codons (0/1)?\n   commonf3x4 = 0  * use one set of codon freqs for all pairs (0/1)?\n*       ndata = 1\n\n\n* Genetic codes: 0:universal, 1:mammalian mt., 2:yeast mt., 3:mold mt.,\n* 4: invertebrate mt., 5: ciliate nuclear, 6: echinoderm mt.,\n* 7: euplotid mt., 8: alternative yeast nu. 9: ascidian mt.,\n* 10: blepharisma nu.\n* These codes correspond to transl_table 1 to 11 of GENEBANK.\n" > $PAMLCTL
  fi
fi

#  This generates new directories and converts fasta files in original dirs to Phylip
## Assumes the old directory name  ends in ..._outputdir
### Pangenome: In the case that the individuals with this gene are not present in this analysis
### count lines in the fasta to determine whether to use it.
# If the gene too long fastx_collaper won't work so I do it myself (see LONFAS and FASLEN
# Added a section to rectify gene length for incomplete CDS
while read DIRECTORY
do
  HOLDER=$(echo "${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  mkdir -p "$NEWDR"
  > ${NEWDR}/${HOLDER}.fas.incomplete.cds.list
  submit-slurm.pl -j phy-mm_${NEWDR}_01 -i "source fastx_toolkit-0.0.13.2
  ls ${DIRECTORY}/ | grep '\.fas' | awk -F '/' '{print \$NF}' | sed 's/\.fas//' > ${HOLDER}.fas.list
  cd ${NEWDR}
  while read FAS
  do
    EMPTY=\$(cat ${DIRECTORY}/\${FAS}.fas | wc -l)
    if [[ \"\${EMPTY}\" -ne \"0\" ]]
    then
      LONFAS=\$(sed -n '2p' ${DIRECTORY}/\${FAS}.fas | wc -m)
      FASLEN=\$(( \$LONFAS - 4 ))
      if [[ \"\${FASLEN}\" -lt \"23500\" ]]
      then
        fastx_collapser -i ${DIRECTORY}/\${FAS}.fas | Fasta2Phylip.pl - \${FAS}.temp
        REMAIN=\$(( \$FASLEN % 3 ))
        if [[ \"\$REMAIN\" -eq \"0\" ]]
        then
          cat <(sed -n '1p' \${FAS}.temp | awk '{l=\$2-3; print \$1,l}') <(sed '1d' \${FAS}.temp | sed 's/...\$//') | sed \$'s/\t/  /' > \${FAS}.phy
        elif [[ \"\$REMAIN\" -eq \"1\" ]]
        then
          echo \"\${FAS}\" >> ${HOLDER}.fas.incomplete.cds.list
          cat <(sed -n '1p' \${FAS}.temp | awk '{l=\$2-4; print \$1,l}') <(sed '1d' \${FAS}.temp | sed 's/....\$//') | sed \$'s/\t/  /' > \${FAS}.phy
        elif [[ \"\$REMAIN\" -eq \"2\" ]]
        then
          echo \"\${FAS}\" >> ${HOLDER}.fas.incomplete.cds.list
          cat <(sed -n '1p' \${FAS}.temp | awk '{l=\$2-5; print \$1,l}') <(sed '1d' \${FAS}.temp | sed 's/.....\$//') | sed \$'s/\t/  /' > \${FAS}.phy
        fi
        rm \${FAS}.temp
      else
        echo \"\${FAS}.fas looks long, it's \${FASLEN} bp!  Running manual concatenation to haplotypes\"
        grep -v '>' ${DIRECTORY}/\${FAS}.fas > \${FAS}.temp
        ITERATOR=0
        while read CONCAT
        do
          ITERATOR=\$((\$ITERATOR+1))
          echo \"\$CONCAT\" > \${FAS}.temp.\${ITERATOR}
        done < \${FAS}.temp
        rm \${FAS}.temp
        md5sum \${FAS}.temp.* | sort -k1,1 -u | awk '{print \$2}' > \${FAS}.keep
        SEQNO=\$(cat \${FAS}.keep | wc -l)
        while read KEEP
        do
          paste -d ' ' <(echo \"\${KEEP}\" | rev | cut -d '.' -f 1 | rev) <(cat \$KEEP)
        done < \${FAS}.keep | sed 's/\(^\|[^ ]\) \($\|[^ ]\)/\1  \2/' > \${FAS}.temp
        cat <(echo \"\$SEQNO \$FASLEN\") <(sed 's/...\$//' \${FAS}.temp) > \${FAS}.phy
        rm \${FAS}.temp* \${FAS}.keep
      fi
    else
      echo -e \"${NEWDR} \${FAS}.fas has zero haplotypes in this population/set.\"
    fi
  done < ../${HOLDER}.fas.list
  cd ../"
done < $DIRECTORY_FILE

## Await completion of previos jobs
CONTINUE=$(squeue -u "$USER" | grep -c 'MM-phy-m')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (population fasta to phylip conversions)."
while [[ "$CONTINUE" -gt "0" ]]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u "$USER" | grep -c 'MM-phy-m')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (population fasta to phylip convrsions)."
done


# Running YN00 through once to check for premature stop codons.
# These genes won't be run through paml to collect dnds data.
# However they will be stored in a file called POPULATION.fas.stops-present.list

echo -e "\n\nRunning YN00\nFirst to check for premature stop codons which won't be run through paml to collect dnds data. However they will be stored in POPULATION.fas.stops-present.list and removed from ${HOLDER}.fas.stops-removed.list.\nSecond to collect dnds information\n\n"

while read DIRECTORY
do
  HOLDER=$(echo "../${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  # Make a list of genes which I can remove genes with early stop codons from and a list that contains them.
  cp ${HOLDER}.fas.list ${NEWDR}/${HOLDER}.fas.stops-removed.list
  > ${NEWDR}/${HOLDER}.fas.stops-present.list
  submit-slurm.pl -j yn00-mm_${NEWDR}_02 -i "source paml-4.9
  cd $NEWDR
  while read GENES
  do 
    sed \"s/MM\.sedreplace\.MM/\${GENES}.phy/\" ../yn00.ctl > yn00-run_${HOLDER}-\${GENES}.ctl
  done < ../${HOLDER}.fas.list
  for GENES in *.ctl
  do
    GENE=\$(echo \"\${GENES}\" | sed -e \"s/yn00-run_${HOLDER}-//\" -e 's/\.ctl//')
    STOP=\$(yn00 \$GENES | grep 'stop codon' | wc -l)
    if [[ \"\$STOP\" -eq \"0\" ]]
    then
      BBOYS=\$(wc -l \${GENE}.phy | awk '{n=\$1-1; b=(n*(n-1))/2; l=7+b; print l}')
      grep -A \$BBOYS \"(B) Yang & Nielsen (2000) method\" \${GENE}.phy.yn > \${GENE}.phy.yn.yn00
    else
      grep -v \$GENE ${HOLDER}.fas.stops-removed.list > MM.stops.removed.MM-\${GENEs}-${HOLDER}
      mv MM.stops.removed.MM-\${GENEs}-${HOLDER} ${HOLDER}.fas.stops-removed.list
      echo \"\${GENE}\" >> ${HOLDER}.fas.stops-present.list
    fi
  done
  rm rst rst1 rub 2YN*
  cd ../"
done < $DIRECTORY_FILE


## Await completion of previos jobs
CONTINUE=$(squeue -u "$USER" | grep -c 'MM-yn00-')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (YN00)."
while [[ "$CONTINUE" -gt "0" ]]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u "$USER" | grep -c 'MM-yn00-')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (YN00)."
done

echo -e "\nGenerating a table of mean dnds for each gene (ds>=0)\n"
# Collect data (mean dnds) from the YN00 output
# If there was no output print NA
# If after removal of all of the ds=0 values (causing dnds=99) there are no lines print NA

while read DIRECTORY
do
  HOLDER=$(echo "../${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
  NEWDR="${HOLDER}_yn00"
  > ${NEWDR}/${HOLDER}.no-diversity.list
  submit-slurm.pl -j mean_${NEWDR}_03 -i "cd $NEWDR
  while read ALLGENE
  do
    echo \"\$ALLGENE\"
    STOPOLYM=\$(grep \$ALLGENE ${HOLDER}.fas.stops-present.list | wc -l)
    if [[ \"\$STOPOLYM\" -eq \"1\" ]]
    then
      echo -e \"StoPolyM\tNA\tNA\tNA\tNA\tNA\tNA\tNA\"
    elif [[ \"\$STOPOLYM\" -eq \"0\" ]]
    then
      INCMPLTCDS=\$(grep \$ALLGENE $HOLDER.fas.incomplete.cds.list | wc -l)
      NOLINE8=\$(cat \${ALLGENE}.phy.yn.yn00 | wc -l | awk '{k=\$1-8; print k}')
      if [[ \"\$NOLINE8\" -eq \"0\" ]]
      then
        echo -e \"NoPolyM\tNA\tNA\tNA\tNA\tNA\tNA\tNA\"
        echo \${ALLGENE} >> ${HOLDER}.no-diversity.list
      elif [[ \"\$NOLINE8\" -gt \"0\" ]]
      then
        tail -n \$NOLINE8 \${ALLGENE}.phy.yn.yn00 > MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.MM
        if [[ \"\$INCMPLTCDS\" -eq \"1\" ]]
        then
          awk -v OFS='\t' -v x='CDSincmp' '{S+=\$3; N+=\$4; t+=\$5; kappa+=\$6; omega+=\$7; dN+=\$8; dS+=\$11} END {print x, S/NR, N/NR, t/NR, kappa/NR, omega/NR, dN/NR, dS/NR}' MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.MM > MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.mean.MM
        elif [[ \"\$INCMPLTCDS\" -eq \"0\" ]]
          then
          awk -v OFS='\t' -v x='PolyM' '{S+=\$3; N+=\$4; t+=\$5; kappa+=\$6; omega+=\$7; dN+=\$8; dS+=\$11} END {print x, S/NR, N/NR, t/NR, kappa/NR, omega/NR, dN/NR, dS/NR}' MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.MM > MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.mean.MM
        else
          echo \"Error with incomplete CDS\"
          exit 1
        fi
        INFINITYTRIGGER=0
        while read OUTPUT
        do
          MORTHNZEROS=\$(echo \$OUTPUT | awk '\$11>0' | wc -l)
          MORTHNZERON=\$(echo \$OUTPUT | awk '\$8>0' | wc -l)
          if [[ \$\"MORTHNZEROS\" -eq \"0\" ]] && [[ \$\"MORTHNZERON\" -gt \"0\" ]]
          then
            INFINITYTRIGGER=1
          fi
        done < MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.MM
        if [[ \$\"INFINITYTRIGGER\" -eq \"1\" ]]
        then
          awk -v OFS='\t' -v I='INFINITY' '{print I,\$2,\$3,\$4,\$5,\$6,\$7,\$8}' MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.mean.MM
        else
          cat MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.mean.MM
        fi
        rm MM.\${ALLGENE}.phy.yn.yn00.ds-eq0.mean.MM
      fi
    else
      echo \"Error with stop polymorphism\"
      exit 1
    fi
  done < ../${HOLDER}.fas.list | paste - - > MM.temp.yn00.out-${HOLDER}.MM
  # Add headers and clean up
  cat <(echo -e \"Gene\tInfo\tS\tN\tt\tkappa\tomega\tdN\tdS\") MM.temp.yn00.out-${HOLDER}.MM > ../${HOLDER}.yn00.mean.txt
  rm MM.temp.yn00.out-${HOLDER}.MM MM.*.phy.yn.yn00.ds-??0.MM
  mv *.list ../
  cd ../"
done < $DIRECTORY_FILE

## Await completion of previos jobs
CONTINUE=$(squeue -u "$USER" | grep -c 'MM-mean')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (table generation and cleanup)."
while [[ "$CONTINUE" -gt "0" ]]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u "$USER" | grep -c 'MM-mean')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (table generation and cleanup)."
done


if [[ "$kleen" -eq "0" ]]
then
  echo -e "\nYou have chosen to remove phylip and YN00 intermediate files and their directories\n"
  while read DIRECTORY
  do
    HOLDER=$(echo "../${DIRECTORY%_*}" | awk -F '/' '{print $NF}')
    NEWDR="${HOLDER}_yn00"
    echo "The directory I will remove is $NEWDR"
    submit-slurm.pl -j remove_${NEWDR}_03 -i "rm -r $NEWDR"
  done < $DIRECTORY_FILE
else
  echo -e "\nYou have chosen to preserve phylip and YN00 intermediate files in their directories\n"
fi

## If we are deleting intermediate files await completion of previos jobs

if [[ "$kleen" -eq "0" ]]
then
  CONTINUE=$(squeue -u "$USER" | grep -c 'MM-remo')
  WAITTIME=1
  TIMEWAIT=0
  echo -e "\nThere are $CONTINUE jobs running (removing intermediate files)."
  while [[ "$CONTINUE" -gt "0" ]]
  do
    sleep ${WAITTIME}m
    TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
    CONTINUE=$(squeue -u "$USER" | grep -c 'MM-remo')
    echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (removing intermediate files)."
  done
  rm remove_*.???.slurm
fi

mkdir paml-yn00-diversity_slurmout
mv phy-mm*.slurm yn00-mm*.slurm mean_*.slurm *.fas.list *.fas.incomplete.cds.list  *.fas.stops-present.list *.fas.stops-removed.list *.no-diversity.list paml-yn00-diversity_slurmout

echo -ne "\n\n\tRun complete\n\n"

exit 0

