#!/usr/bin/env bash

# A script that first counts the number of columns in a vcf and gets number of individuals (assumes ind start at $10)
# It then produces a file that lists all positions where all indivdiuals are ref/ref calls (0/0), 0|0 or 0|) = MM.pos-refref.MM
# It then runs max-missing to retain only those sites with at least 1 call for an individual
#
# I later added a feature to remove all the ref/ref fixed differences (1/1), 1|1 or 1| across all individuals) to count the number of polymorphisms within a population
#
# Provide -i infile and state whether it is -h, -d OR -p for haploid, dipolid (unphased 0/1) OR diploid (phased 0|1)

RAND=$((1 + RANDOM % 999999))

while getopts "i:hdpF" opt
do
  case $opt in
    i)
      INFILE=$OPTARG
      echo -en "\n\nWe are working with:\n" >&2
      ls $INFILE
      ;;
    h)
      GENTYP='0'
      ELSE1='1'
      ELSE2='\.'
      DIPLOID=0
      echo -en "You say this is haploid data ($GENTYP)\n"
      ;;
    d)
      GENTYP='0\/0'
      ELSE1='0\/1'
      ELSE2='1\/1'
      ELSE3='\.\/\.'
      DIPLOID=1
      echo -en "You say this is unphased diploid data ($GENTYP)\n"
      ;;
    p)
      GENTYP='0|0'
      ELSE1='0|1'
      ELSE2='1|0'
      ELSE3='1|1'
      ELSE4='\.|\.'
      ELSE5='0|\.'
      ELSE6='\.|0'
      ELSE7='1|\.'
      ELSE8='\.|1'
      DIPLOID=1
      echo -en "You say this is phased diploid data ($GENTYP)\n"
      ;;
    F)
      FIXED=1
      echo -en "You also want to remove sites of Fixed differences\n"
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

if [ -z ${INFILE+x} ]
then
  echo -ne "\n\n########################################################### vcf-ref-ref.sh ############################################################\n"
  echo -ne "# A script that first counts the number of columns in a vcf (=No. ind) (assumes ind start at column 10)                                       #\n"
  echo -ne "# It then produces a file that lists all positions where all indivdiuals are ref/ref calls (0/0), 0|0 or 0|) = MM.pos-refref_${RAND}.MM #\n"
  echo -ne "# It then runs max-missing to retain only those sites with at least 1 call for an individual (=[1/No. ind] / 2 (if diploid)           #\n"
  echo -ne "# Provide -i infile and state whether it is -h, -d OR -p for haploid, dipolid (unphased 0/1) OR diploid (phased 0|1)                  #\n"
  echo -ne "#\tThe outfile name is generated automatically from the infile name (remove '.vcf')                                              #\n"
  echo -ne "#                                                                                                                                     #\n"
  echo -ne "# If you want to also remove sites of fixed differences (1/1), 1|1 or 1| across all individuals) then use -F                          #\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi

TOTALNO=$(grep -v '#' $INFILE | head -n 1 | awk '{print NF}')
INDNO=$(($TOTALNO - 9))
INDNO2=$(($INDNO*2))			# This is the required to hit if you want to remove all fixed differences

# Calculate the proportion of a locus present at a single individual
echo -e "\nThere are $INDNO individuals in your vcf\n"
if [ "$DIPLOID" == '1' ]
then
  MAXMIS=$(awk -v a=$INDNO 'BEGIN { print (1 / a) / 2 }')
else
  MAXMIS=$(awk -v a=$INDNO 'BEGIN { print (1 / a) }')
fi

echo "max-missing = $MAXMIS"

> MM.temp-nomis-1_${RAND}.MM
> MM.temp-nomis-2_${RAND}.MM
> MM.temp-nomis-3_${RAND}.MM
for IND in $(seq 10 $TOTALNO)
do
  grep -v '#' $INFILE | awk -v COLUMN=$IND '{print $COLUMN}' | cut -d ':' -f 1 > MM.temp-nomis-1_${RAND}.MM
  paste MM.temp-nomis-2_${RAND}.MM MM.temp-nomis-1_${RAND}.MM > MM.temp-nomis-3_${RAND}.MM
  cp MM.temp-nomis-3_${RAND}.MM MM.temp-nomis-2_${RAND}.MM
done

rm MM.temp-nomis-2_${RAND}.MM MM.temp-nomis-1_${RAND}.MM

# Replace genotypes for numbers
# if haploid
if [ "$GENTYP" == '0' ]
then 
  sed "s/$GENTYP/0/g" MM.temp-nomis-3_${RAND}.MM > MM.temp-replace_${RAND}.MM
  sed "s/$ELSE1/2/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE2/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
fi
# if diploid
if [ "$GENTYP" == '0\/0' ]
then
  sed "s/$GENTYP/0/g" MM.temp-nomis-3_${RAND}.MM > MM.temp-replace_${RAND}.MM
  sed "s/$ELSE1/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE2/2/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE3/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
fi
# if phased diploid
if [ "$GENTYP" == '0|0' ]
then
  sed "s/$GENTYP/0/g" MM.temp-nomis-3_${RAND}.MM > MM.temp-replace_${RAND}.MM
  sed "s/$ELSE1/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE2/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE3/2/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE4/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE5/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE6/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE7/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
  sed "s/$ELSE8/1/g" MM.temp-replace_${RAND}.MM > MM.temp-replace2_${RAND}.MM; mv MM.temp-replace2_${RAND}.MM MM.temp-replace_${RAND}.MM
fi

# get all the chrom bp positions from the vcf
# sum each row to identify rows of a given number and paste into MM.pos-replace-sum_${RAND}.MM
grep -v '#' $INFILE | awk -v OFS='\t' '{print $1,$2}' > MM.temp-pos_${RAND}.MM
awk '{sum=0; for (i=1; i<=NF; i++) { sum+= $i } print sum}' MM.temp-replace_${RAND}.MM >> MM.temp-sum_${RAND}.MM
paste MM.temp-pos_${RAND}.MM MM.temp-replace_${RAND}.MM MM.temp-sum_${RAND}.MM > MM.pos-replace-sum_${RAND}.MM; rm MM.temp-pos_${RAND}.MM MM.temp-replace_${RAND}.MM MM.temp-sum_${RAND}.MM

# if -F then grap both the zero rows and the ind*2 rows ($INDNO2) else just the zero rows
if [ "$FIXED" == 1 ]
then
  awk -v f=$INDNO2 '$NF==0 || $NF==f' MM.pos-replace-sum_${RAND}.MM | awk -v OFS='\t' '{print $1,$2}' > MM.pos-refref_${RAND}.MM
else
  awk '$NF==0' MM.pos-replace-sum_${RAND}.MM | awk -v OFS='\t' '{print $1,$2}' > MM.pos-refref_${RAND}.MM
fi

# Run vcftools
RECODEVCF=$(echo $INFILE | grep -c "\.recode\.vcf$")
if [ "$RECODEVCF" -eq "1" ]
then
  OUTFILE=$(echo $INFILE | sed 's/.recode.vcf//')
else
  OUTFILE=$(echo $INFILE | sed 's/.vcf//')
fi

source vcftools-0.1.13
if [ "$FIXED" == 1 ]
then
  vcftools --vcf $INFILE --exclude-positions MM.pos-refref_${RAND}.MM --recode --out ${OUTFILE}.no-refref.no-altalt
  vcftools --vcf ${OUTFILE}.no-refref.no-altalt.recode.vcf --max-missing $MAXMIS --recode --out ${OUTFILE}.no-refref.no-altalt.no-missing
  rm MM.temp-nomis-3_${RAND}.MM MM.pos-replace-sum_${RAND}.MM MM.pos-refref_${RAND}.MM ${OUTFILE}.no-refref.no-altalt.recode.vcf
else
  vcftools --vcf $INFILE --exclude-positions MM.pos-refref_${RAND}.MM --recode --out ${OUTFILE}.no-refref 
  vcftools --vcf ${OUTFILE}.no-refref.recode.vcf --max-missing $MAXMIS --recode --out ${OUTFILE}.no-refref.no-missing
  rm MM.temp-nomis-3_${RAND}.MM MM.pos-replace-sum_${RAND}.MM MM.pos-refref_${RAND}.MM ${OUTFILE}.no-refref.recode.vcf
fi
