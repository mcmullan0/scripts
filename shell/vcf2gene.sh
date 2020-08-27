#!/usr/bin/env bash

# I hope this script will take a genome fasta and a multisample vcf and pull out the genes for all individuals.

# Required Reference fasta
## Index with picardtools
# A filtered vcf
# A table of mean depth + coverage per gene per individual

RAND=$((1 + RANDOM % 999999))
RANDSLURM=$((1 + RANDOM % 999))
DURATION=1
REGROUP=0

while getopts "r:g:v:L:p:kq:d:o:R" opt
do
  case $opt in
    r)
      INFILE=$OPTARG
      echo -en "\n\nThe genome fasta is called $INFILE\n" >&2
      ;;
    g)
      INGFF=$OPTARG
      echo -en "The gff is called $INGFF\n" >&2
      ;;
    v)
      VCF=$OPTARG
      echo -en "The multisample vcf $VCF\n" >&2
      ;;
    L)
      INDLIST=$OPTARG
      INDNO=$(cat $INDLIST | wc -l)
      echo -en "There are $INDNO individuals in your $INDLIST file\n" >&2
      ;;
    p)
      VCFPLOID=$OPTARG
      if [ "$VCFPLOID" == "h" ]
      then
        echo -en "Individuals are coded in the vcf as haploid (1:)\n" >&2
      elif [ "$VCFPLOID" == "d" ]
      then
        echo -en "Individuals are coded in the vcf as diploid (unphased, 1/1:)\n" >&2
      elif [ "$VCFPLOID" == "p" ]
      then
        echo -en "Individuals are coded in the vcf as diploid (phased, 1|1:)\n" >&2
      else
        echo -en "I don't recognise your ploidy input.\nUse h, d OR p haploid, dipolid (unphased 0/1) OR diploid (phased 0|1)\n" >&2
        exit 1
      fi
      ;;
    k)
      FIXED=1
      echo -en "Keep intermediate vcf and WG-fasta files\n"
      ;;
    q)
      DURATION=$OPTARG
      ;;
    d)
      KEEPGENES=1
      PRESTABLE=$OPTARG
      echo -en "You have provided a file, a table that lists gene presence per individual\n"
      ;;
    o)
      MULTIOUT+=("$OPTARG")
      ;;
    R)
      REGROUP=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# If you have not instructed a Regroup run (which relies on this script already having been run once && lost os stuff is missing then
# print help
if [ -z ${INFILE+x} ] || [ -z ${INGFF+x} ] || [ -z ${INDLIST+x} ] || [ -z ${VCF+x} ] || [ -z ${VCFPLOID+x} ] || [ ${#MULTIOUT[@]} -eq 0 ]
then
  echo -ne "\n\n########################################################### vcf2gene.sh ###############################################################\n"
  echo -ne "# Uses a multisample vcf and a reference to generate a reference fasta per individual\n"
  echo -ne "# Individuals references genes are renamed and put in numerical order.  A conversion table is stored as gff.contig_conversion.txt\n"
  echo -ne "# The original gff is not overwritten\n"
  echo -ne "# Requires:\n"
  echo -ne "#\t-r Reference.fasta\n"
  echo -ne "#\t-g Reference.gff\n"
  echo -ne "#\t-v multisample.vcf\n"
  echo -ne "#\t-L a text file containing a list of individuals in the vcf\n"
  echo -ne "#\t-d a text file containing a list of genes (c1) and then a 1 or 0 to represent gene presence or absence per column\n"
  echo -ne "#\t\tsubsequent (individual) columns should be headed with the individual's name used in the vcf file\n"
  echo -ne "#\t-p Ploidy as coded in the vcf\n"
  echo -ne "#\t\tuse h, d OR p haploid, dipolid (unphased 0/1) OR diploid (phased 0|1)\n"
  echo -ne "#\t-k to keep intermediate vcf and WG-fasta files\n"
  echo -ne "#\t-q to set the number of minutes to wait to check for jobs completing (default = 1)\n"
  echo -ne "#\t\tLarger vcfs (Gb) will require longer (Reduces unecessary output)\n"
  echo -ne "#\t-o One or more file containing lists of individuals (population) you want to compare. Flag can be used multiple times\n"
  echo -ne "#\t-R REGROUP can be used to skip to the end of the run and regroup gene fastas into a new population group (use -o)\n"
  echo -ne "# Use DNAsp on these data to return diversity measures.  Use paml-yn00-diversity.sh to return mean dnds\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi
# Or if you have instructed a regroup run but haven't added any groups then print help
if [ "$REGROUP" -eq 1 ] && [ ${#MULTIOUT[@]} -eq 0 ]
then
  echo -ne "\n\n########################################################### vcf2gene.sh ###########################################################\n"
  echo -ne "# -R REGROUP can be used to skip to the end of the run and regroup gene fastas into a new population group (use -o)\n"
  echo -ne "# Regroup is run after this script has been run once to extract genes present in each individual.\n"
  echo -ne "# Once this has been done you can run -R with -o to specify that you want genes from individuals from different groups\n"
  echo -ne "#\tor populations to be included in the same file.i\n"
  echo -ne "#\t-o One or more file containing lists of individuals (population) you want to compare. Flag can be used multiple times\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi

echo -en "You have provided ${#MULTIOUT[@]} files containing a list of individuals which you want to compare\n"
echo -en "This output will be saved in the directory:\n"
for ii in "${MULTIOUT[@]}"
do
  OUTPUT=$ii
  OUTPRFX=$(echo "${OUTPUT%.*}")
  OUTDIR="${OUTPRFX}_outputdir"
  echo -e "\t - $OUTDIR"
done

# Does the genome fasta have a '.fa' extension? if not make one
FA='fa'
EXTNSON=$(echo "$INFILE" | awk -F '.' '{print $NF}')
PREFIX=$(echo "${INFILE%.*}")
FAS="$PREFIX.$FA"
GFFPREFIX=$(echo "${INGFF%.*}")
GFFEXTENSION=$(echo "$INGFF" | awk -F '.' '{print $NF}')

if [ "$EXTNSON" != "$FA" ]
then
  echo -e "\nCopying $INFILE to $FAS simply becuase Picard requres a .fa extension"
  cp $INFILE $FAS
fi

mkdir -p slurmout

if [ "$REGROUP" -eq 0 ]
then 
  echo -e "\nIndexing reference (Picard)"
  DICT='dict'
  source picardtools-2.1.1
  source jre-8u92
  java -jar /tgac/software/testing/picardtools/2.1.1/x86_64/bin/picard.jar CreateSequenceDictionary R=$FAS O=$PREFIX.$DICT
  echo "Indexing reference (Samtools)"
  source samtools-1.5
  samtools faidx $FAS
  echo "Reference indexed"
  
  
  echo -e "\nExtract individual vcfs (remove ref/ref calls)"
  while read IND
  do
    submit-slurm.pl -j ${RANDSLURM}extract-$IND -i "source vcftools-0.1.13
    vcftools --vcf $VCF --indv $IND --recode --out ${IND}-${PREFIX}
    vcf-ref-ref.sh -i ${IND}-${PREFIX}.recode.vcf -${VCFPLOID}
    rm ${IND}-${PREFIX}.recode.vcf
    mv ${IND}-${PREFIX}.recode.no-refref.no-missing.recode.vcf ${IND}-${PREFIX}.no-refref.no-missing.recode.vcf"
  done < $INDLIST
  echo "Awaiting production of individual vcfs"
  HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}ex")
  COUNTER=0
  while [[ "$HOLD" != "0" ]]
  do
    sleep ${DURATION}m
    HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}ex")
    COUNTER=$(( $COUNTER + $DURATION ))
    echo -e "... production of individual vcfs, $HOLD jobs remaining ($COUNTER minutes passed)"
  done
  echo "VCFs extracted and ref-ref sites removed"
  
  
  echo -e "\nProduce individual reference fastas"
  for IVCF in *-${PREFIX}.no-refref.no-missing.recode.vcf
  do
    submit-slurm.pl -j ${RANDSLURM}ref-maker-$IVCF -m 16G -e -i "source gatk-3.5.0
    source jre-7.11
    java -jar /tgac/software/testing/gatk/3.5.0/x86_64/bin/GenomeAnalysisTK.jar -T FastaAlternateReferenceMaker -R $FAS -V $IVCF -o $IVCF.fasta
    rm $IVCF"
  done
  echo "Awating production of individual reference fastas"
  HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}re")
  COUNTER=0
  while (( "$HOLD" != "0" ))
  do
    sleep ${DURATION}m
    HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}re")
    COUNTER=$(( $COUNTER + $DURATION ))
    echo -e "... production of individual fastas, $HOLD jobs remaining ($COUNTER minutes passed)"
  done
  
  echo -e "\nConverting multiline fasta to single line fas"
  while read IFAS
  do
   submit-slurm.pl -j ${RANDSLURM}fas-$IFAS -m 4G -i "fastline.pl -i ${IFAS}-${PREFIX}.no-refref.no-missing.recode.vcf.fasta -a > ${IFAS}.filt.fas
    rm ${IFAS}-${PREFIX}.no-refref.no-missing.recode.vcf ${IFAS}-${PREFIX}.no-refref.no-missing.recode.vcf.fasta"
  done < $INDLIST
  echo "Awaiting production of single line fastas"
  HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}fa")
  COUNTER=0
  while [[ "$HOLD" != "0" ]]
  do
    sleep ${DURATION}m
    HOLD=$(squeue -u mcmullam | grep -c "M/M-${RANDSLURM}fa")
    COUNTER=$(( $COUNTER + $DURATION ))
    echo -e "... production of single line fastas\n... ... $HOLD jobs remaining ($COUNTER minutes passed)"
  done 
 
  echo "To remove wierd characters in contig headers I rename contigs numerically in ind.fastas and .gff"
  echo "I'd do this first (manually grepping) becuase it is difficult to automate.  Though I do try to automate it here"
  echo "Numbering genes from 1..n in both individual reference fastas ind.filt.fas > ind.filt.n.fas"
  echo "as well as converting these in a new $INGFF file"
  
  echo -e "\n\n\n\n####################################################################################################"
  echo -e "This section may fall over because people put weird characters in scaffold names"
  echo "If you see errors, check the ${GFFPREFIX}.contig-no.${GFFEXTENSION} file"
  echo "If this is the case try renaming and rerunning.  Remember to rename in fas gff and vcf"
  echo -e "####################################################################################################\n\n\n\n"
  grep '>' $FAS | sed 's/^>//' | uniq > MM.${RAND}-headers
  COUNTTO=$(cat MM.${RAND}-headers | wc -l)
  for (( COUNTER=1; COUNTER<=$COUNTTO; COUNTER++ ))
  do
    echo "$COUNTER"
  done > MM.${RAND}-counter
  paste MM.${RAND}-counter MM.${RAND}-headers > ${INGFF}.contig_conversion.txt
  rm MM.${RAND}-counter MM.${RAND}-headers
  echo -ne "######################################\n${INGFF}.contig_conversion.txt\n######################################\n"
  head ${INGFF}.contig_conversion.txt
  echo -e "...\t...\n...\t...\n...\t..."
  
  echo "${INGFF}.nohash"
  grep -v '#' $INGFF > ${INGFF}.nohash
  while read CONVERT
  do
    REMOVE=$(echo "$CONVERT" | awk '{print $2}' | xargs)
    REPLACE=$(echo "$CONVERT" | awk '{print $1}' | xargs)
    grep "$REMOVE" ${INGFF}.nohash | sed "s/$REMOVE/$REPLACE/"
  done < ${INGFF}.contig_conversion.txt > ${GFFPREFIX}.contig-no.${GFFEXTENSION}
  rm ${INGFF}.nohash
  echo -e "\n\nIf you can see a ton of errors above then the plan to replace contig header names with numbers has failed"
  echo -e 'You might have some windows characters in there (remove with tr -d \\015)'
  echo -e "If not, cracking.  You probably didn't put rediculus characters in your contig names"
  
  # Now that wh have converted contig names to numbers we can grab the first part of the name in the fasta
  # which was put there by picard
  echo -ne "\nConverting individual fasta contig names to numbers\n"
  for FASNO in *.bam.filt.fas
  do
    awk '{print $1}' $FASNO > test-$FASNO
    sleep 1
    mv test-$FASNO $FASNO
  done
  
  ls *.bam.filt.fas | sed 's/\.fas//' > ind-fas.list
  
  echo -ne "\nExtracting gene sequences per individual\n"
  while read INF
  do
    source cufflinks-2.2.1_gk
    gffread ${GFFPREFIX}.contig-no.${GFFEXTENSION} -g ${INF}.fas -x $INF.cds.fasta
  done < ind-fas.list
  echo -ne "\nGene sequences extracted\nConverting to single line fastas\n"
  
  while read INF
  do
    fastline.pl -i ${INF}.cds.fasta -a > ${INF}.cds.fas
    rm ${INF}.cds.fasta
  done < ind-fas.list
  
  # Extract genes for each individual 
  
  cat *.bam.filt.cds.fas | grep '>' | awk '{print $1}' | sed 's/>//' | sort -V | uniq > gene.list
  
  # If we are keeping only genes in our presence table
  mkdir -p individuals_genes
  if [ "$KEEPGENES" -eq 1 ]
  then
    ## First use the presence absence table (-d) to remove genes from the fasta flagged as missing in the file
    ### Record the column number for each isoalte in the conversion table
    head -n 1 $PRESTABLE | tr '\t' '\n' > MM-${PRESTABLE}.headers-MM
    CONVERSIONNO=0
    while read CONVERSIONHEADERS
    do
      CONVERSIONNO=$(( $CONVERSIONNO + 1))
      echo "$CONVERSIONNO"
    done < MM-${PRESTABLE}.headers-MM > MM-${PRESTABLE}.columns-MM
    paste MM-${PRESTABLE}.headers-MM  MM-${PRESTABLE}.columns-MM > MM-${PRESTABLE}.headcols-MM
    rm MM-${PRESTABLE}.headers-MM  MM-${PRESTABLE}.columns-MM
    
    ### Then, for every ind pull out a list of all the genes that are present (slower than absent but easier to code)
    echo -e "\nKeep genes with a 1 in the conversion file $PRESTABLE from each individual's cds.fas"
    while read IND
    do
      submit-slurm.pl -j ${RANDSLURM}replace-genes-$IND -i "GETCOLUMN=\$(grep \"$IND\" MM-${PRESTABLE}.headcols-MM | awk '{print \$2}')
      awk -v OFS='\t' -v g=\$GETCOLUMN '{print \$1,\$g}' ${PRESTABLE} | awk '\$2==1' > ${IND}.genes-present.txt
      > individuals_genes/${IND}.filt.cds.present.fas
      while read GENESTOGET
      do
        GETGENE=\$(echo \"\$GENESTOGET\" | awk '{print \$1}')
        grep -A 1 \"\$GETGENE\" ${IND}.filt.cds.fas >> individuals_genes/${IND}.filt.cds.present.fas
      done < ${IND}.genes-present.txt
      rm ${IND}.filt.cds.fas ${IND}.genes-present.txt"
    done < $INDLIST
    echo "Awaiting production of individual fastas (present genes only)"
    
    HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}re")
    COUNTER=0
    while [[ "$HOLD" != "0" ]]
    do
      sleep ${DURATION}m
      HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}re")
      COUNTER=$(( $COUNTER + $DURATION ))
      echo -e "... production of individual's (present) gene fastas, $HOLD jobs remaining ($COUNTER minutes passed)"
    done
    echo "present genes extracted per individual in individuals_genes/....filt.cds.present.fas"
    rm MM-${PRESTABLE}.headcols-MM
  else
    echo "Apparently all genes are present in all individuals.  Renaming fasta files to add individuals_genes/...'present'.fas"
    while read IND
    do
      mv ${IND}.filt.cds.fas individuals_genes/${IND}.filt.cds.present.fas
    done < $INDLIST
  fi
fi

echo -e "\nGenerating a fasta for each gene containing the individuals listed in each of your (${#MULTIOUT[@]}) population files (-o)" 
# For each group of outputs make a directory and For each gene group the relevent individual's genes.
split -l 100 gene.list gene.list.${RAND}.
for POPULATIONS in ${MULTIOUT[@]}
do
  OUTPUT=$POPULATIONS
  OUTPRFX=$(echo "${OUTPUT%.*}")
  OUTDIR="${OUTPRFX}_outputdir"
  mkdir -p $OUTDIR
  for GENESETS in gene.list.${RAND}.*
  do
    submit-slurm.pl -j ${RANDSLURM}grep-${GENESETS}-${OUTPRFX} -q ei-short -t 0-00:45 -i "\
    while read ALLGENES
    do
      while read INDFAS
      do
        grep -A 1 \"\${ALLGENES}\" individuals_genes/\${INDFAS}.filt.cds.present.fas | sed \"s/>.*/>\${ALLGENES}-\${INDFAS}/\" >> ${OUTDIR}/\${ALLGENES}.fas
      done < ${POPULATIONS}
      EMPTY=\$(cat ${OUTDIR}/\${ALLGENES}.fas | wc -l)
      if [ \${EMPTY} -eq \"0\" ]
      then
        rm ${OUTDIR}/\${ALLGENES}.fas
      fi
    done <$GENESETS"
  done
done

# Wait until all jobs have finished
HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}")
COUNTER=0
while [[ "$HOLD" -ne "0" ]]
do
  sleep 5m
  HOLD=$(squeue -u mcmullam | grep -c "MM-${RANDSLURM}")
  COUNTER=$(( $COUNTER + 5 ))
  echo -e "... production of a fasta for each gene (per pop), $HOLD jobs remaining ($COUNTER minutes passed)"
done

echo -e "\n\n\nAll running slurm jobs finished, cleaning up\n\n"
rm gene.list.${RAND}.*
mv *.slurm slurmout

# Throw away intermidiat files (or keep)
if [ -z ${FIXED+x} ]
then
  rm *.filt.fas.fai ind-fas.list *.filt.fas *.idx
else
  mkdir -p vcf2gene-intermediates_run-${RAND}
  rm *.filt.fas.fai *.idx
  mv *.filt.cds.present.fas *ind-fas.list *.filt.fas 
fi


exit 1
