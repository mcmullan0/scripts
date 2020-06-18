#!/usr/bin/env bash

# Runs VCFtools 1000 times on 1 independently thinned vcf file.

RAND=$((1 + RANDOM % 999999))
THINBY=0
while getopts "v:a:w:b:s:" opt
do
  case $opt in
    v)
      VCF=$OPTARG
      ;;
    a)
      INDaLIST=$OPTARG
      ;;
    w)
      INDwLIST=$OPTARG
      ;;
    b)
      BOOTSTRAPPS=$OPTARG
      ;;
    s)
      THINBY=$OPTARG
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

if [ -z ${BOOTSTRAPPS+x} ] || [ -z ${INDaLIST+x} ] || [ -z ${INDwLIST+x} ] || [ -z ${VCF+x} ]
then
  echo -ne "\n\n################################################## vcftools-bootstrap_fst.sh ###################################################\n"
  echo -ne "# Runs VCFtools 1000 times on a VCF that can be optionally thinned.                                                            #\n"
  echo -ne "#                                                                                                                              #\n"
  echo -ne "# NOTE PITA: Ind must appear in order in the VCF as Pop1 Pop2 (left to right), sorry                                           #\n"
  echo -ne "#                                                                                                                              #\n"
  echo -ne "# Please set:                                                                                                                  #\n"
  echo -ne "#\t-v\tThe vcf filename                                                                                               #\n"
  echo -ne "#\t-a\tThe filname containing the list of ind in the first pop                                                        #\n"
  echo -ne "#\t-w\tThe filname containing the list of ind in the second pop                                                       #\n"
  echo -ne "#\t-b\tThe number of bootstrap replicates (final run must be 1000 use only lower numbers to test the script)          #\n"
  echo -ne "#\t-s\tThe rate of thinning which defines the number of SNPs per bp (Optional -reduces runtime)                       #\n"
  echo -ne "#\t\tThin sites so that no two sites are within the specified distance from one another.                            #\n"
  echo -ne "#\t\tSNPs are thinned once, not each bootstap                                                                       #\n"
  echo -ne "################################################################################################################################\n\n"
  exit 1
fi

echo -e "\nGenerating the COLLIST file containing sample namse (col1) and column numbers (col2)\n"
grep '#' ${VCF} | tail -n 1 | tr '\t' '\n' > MM-head.list.${RAND}-MM
COUNTO=$(cat MM-head.list.${RAND}-MM | wc -l)
for (( COUNT=1; COUNT<=$COUNTO; COUNT++ ))
do
  echo $COUNT
done > MM-headcountlist.${RAND}-MM
paste MM-head.list.${RAND}-MM MM-headcountlist.${RAND}-MM | sed '1,9d' > MM-indcoll.list${RAND}-MM

# Collect files
COLLIST="MM-indcoll.list${RAND}-MM"
ENa=$(cat $INDaLIST | wc -l)
ENw=$(cat $INDwLIST | wc -l)
EN=$(( $ENa + $ENw ))
EN10=$(( $EN + 10 ))
HNDVCF=$(echo "$VCF" | sed 's/\.recode\.vcf//')
if [ "$THINBY" -gt "0" ]
then
  THINK=$(( $THINBY / 1000 ))
  OUTPUT=${HNDVCF}.weir.fst.${BOOTSTRAPPS}boot.all.thin${THINK}.txt
  WORKDIR=${HNDVCF}.weir.fst.${BOOTSTRAPPS}boot.all.thin${THINK}.dir
else
  THINK=0
  OUTPUT=${HNDVCF}.weir.fst.${BOOTSTRAPPS}boot.all.txt
  WORKDIR=${HNDVCF}.weir.fst.${BOOTSTRAPPS}boot.all.dir
fi
mkdir $WORKDIR

# Generate a standard header (for all bootstrap replications) containing samples as numbers
# to which the randomly sampled individuals (with replacement) will be added
echo "Generating a generic vcf header to be used in all regernerated vcfs"
grep '##' $VCF > $WORKDIR/${VCF}.bootstrap.header
cat <(echo -e "#CHROM\nPOS\nID\nREF\nALT\nQUAL\nFILTER\nINFO\nFORMAT") \
<(for ((ii=01; ii<=$EN; ii++))
do
  echo "${ii}.bam"
done) | tr '\n' '\t' | sed -e '$a\' >> $WORKDIR/${VCF}.bootstrap.header

# Genetate thinned vcf file
cd $WORKDIR
if [ "$THINBY" -gt "0" ]
then
  echo "Thinning vcf file to 1 SNP per ${THINK}kb used in all $BOOTSTRAPPS bootstraps"
  source vcftools-0.1.13; vcftools --vcf ../${VCF} --thin $THINBY --recode --out ${HNDVCF}.thin${THINK}kb
  WORKINGVCF="${HNDVCF}.thin${THINK}kb"
else
  ln -s ../${VCF}
  WORKINGVCF=$HNDVCF
fi

ln -s ../$INDaLIST
ln -s ../$INDwLIST
ln -s ../$COLLIST

grep -v '#' ${WORKINGVCF}.recode.vcf > ${WORKINGVCF}.data

# Get reference and orientation columns from thinned vcf to paste to data columns
awk -v OFS='\t' '{print $1,$2,$3,$4,$5,$6,$7,$8,$9}' ${WORKINGVCF}.data > ${VCF}.bootstrap.reference

# Generate the file.lists for the vcftools fst comparison (first 25 (ag) and last 21 (wi))
grep '#CHROM' ${VCF}.bootstrap.header | tr '\t' '\n' | grep 'bam' > MM.temp.list.${RAND}.MM
sed -n "1,${ENa}p"  MM.temp.list.${RAND}.MM > MM.temp-a.list.${RAND}.MM
ENa1=$(( $ENa + 1 ))
sed -n "${ENa1},${EN}p"  MM.temp.list.${RAND}.MM > MM.temp-w.list.${RAND}.MM

# Generate each resample of agircultural and wild columns.
# Paste them in that order (a then w) and do Fst on first set through second set
echo "Begin resampling of each of $BOOTSTRAPPS thinned data files"
for (( BOOT=1; BOOT<=$BOOTSTRAPPS; BOOT++ ))
do
  submit-slurm.pl -j vcf-fst_thin${THINK}kb.${BOOT} -m 8192 -q ei-medium -t 0-02:00 -i "source vcftools-0.1.13

  # Generate two random lists of individuals for the fst (resample)
  shuf -rn $ENa $INDaLIST > indlist.a.thin${THINK}kb.${BOOT}
  shuf -rn $ENw $INDwLIST > indlist.w.thin${THINK}kb.${BOOT}
  # Pull out the representative column number of each indivdiual and store
  while read AGRI
  do
    grep "\$AGRI" $COLLIST | awk '{print \$2}'
  done < indlist.a.thin${THINK}kb.${BOOT} > indlist.a.thin${THINK}kb.${BOOT}.colum
  while read WILD
  do
    grep "\$WILD" $COLLIST | awk '{print \$2}'
  done < indlist.w.thin${THINK}kb.${BOOT} > indlist.w.thin${THINK}kb.${BOOT}.colum

  # For each individual (now saved as a column number) paste its column of vcf data together
  cat indlist.a.thin${THINK}kb.${BOOT}.colum indlist.w.thin${THINK}kb.${BOOT}.colum > indlist.thin${THINK}kb.${BOOT}.colum
  rm indlist.a.thin${THINK}kb.${BOOT}.colum indlist.w.thin${THINK}kb.${BOOT}.colum

  for (( INDCOLM=0001; INDCOLM<=$EN; INDCOLM++ ))
  do
    PASTEME=\$(sed -n "\${INDCOLM}p" indlist.thin${THINK}kb.${BOOT}.colum)
    awk -v c=\$PASTEME '{print \$c}' ${WORKINGVCF}.data > ${WORKINGVCF}.${BOOT}.data.temp.\${INDCOLM}-column
  done
  paste ${WORKINGVCF}.${BOOT}.data.temp.*-column > ${WORKINGVCF}.${BOOT}.paste
  rm ${WORKINGVCF}.${BOOT}.data.temp.*-column indlist.thin${THINK}kb.${BOOT}.colum

  # Paste files together and remove
  paste ${VCF}.bootstrap.reference ${WORKINGVCF}.${BOOT}.paste > refagriwildpaste.${BOOT}
  cat ${VCF}.bootstrap.header refagriwildpaste.${BOOT} > ${WORKINGVCF}.boot-${BOOT}-boot.vcf
  rm ${WORKINGVCF}.${BOOT}.paste refagriwildpaste.${BOOT}

  vcftools --vcf ${WORKINGVCF}.boot-${BOOT}-boot.vcf --weir-fst-pop MM.temp-a.list.${RAND}.MM --weir-fst-pop MM.temp-w.list.${RAND}.MM --out ${WORKINGVCF}.${BOOT}"
done

echo "Will sleep until all jobs have finished and then clean up and exit"
WAIT=10
WAITED=0
STOOP=$(squeue -u $USER | grep -c 'vcf-f')
while [ $STOOP -gt 0 ]
do
  sleep ${WAIT}m
  STOOP=$(squeue -u mcmullam | grep -c 'vcf-f')
  WAITED=$(( $WAITED + $WAIT ))
  echo "You have been waiting $WAITED minutes and there are $STOOP jobs remaining"
done

# Pull out the bootstrapped vcf data
echo -e "#Bootstrapped Fst using VCFtools --weir-fst-pop\n#mean Fst\tweighted Fst" > ../$OUTPUT
for (( BOOT=1; BOOT<=BOOTSTRAPPS; BOOT++ ))
do
  grep 'Fst estimate:' vcf-fst_thin${THINK}kb.${BOOT}.err.slurm | awk '{print $7}' | paste - -
done >> ../$OUTPUT

# Cleanup
cd ../
rm -r $WORKDIR MM-head.list.${RAND}-MM MM-headcountlist.${RAND}-MM MM-indcoll.list${RAND}-MM
