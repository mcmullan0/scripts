#!/usr/bin/env bash

HEADER=0
while getopts "c:b:s:oBh" opt
do
  case $opt in
    c)
      COLUMN=$OPTARG
      ;;
    B)
      RUNBOOT=1
      ;;
    b)
      BOOT=$OPTARG
      ;;
    s)
      SAMP=$OPTARG
      ;;
    o)
      OUTPUT=1
      ;;
    h)
      HEADER=1
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

if [ -z ${COLUMN+x} ] && [ ${HEADER} -eq 0 ]
then
  echo -ne "\n\n########################################################### mean.sh ############################################################\n"
  echo -ne "#     A script that Provids the sum, count, mean, median, min, max, Standard Devaiaiton and Standard Error of the Mean        #\n"
  echo -ne "#     Provide a table or column of numbers via the pipe and then use -c to tell mean.sh which column you want to read in.       #\n"
  echo -ne "#     Print a header using -h                                                                                                      #\n"
  echo -ne "#     Bootstrap input column with -B to run the bootstrap                                                                      #\n"
  echo -ne "#                                 -b <default 1000 bootraps>                                                                   #\n"
  echo -ne "#                                 -s <sample size default = whole column>                                                      #\n"
  echo -ne "#                                 -o output column of all means (to pipe to return own CI -default 95%)                        #\n"
  echo -ne "# Print a header using -h                                                                                                      #\n"
  echo -ne "################################################################################################################################\n\n"
  exit 1
elif [ -z ${COLUMN+x} ] && [ ${HEADER} -eq 1 ]
then
  echo -e "sum\tCount\tMean\tMedian\tMin\tMax\tStdv\tsem"
  exit 1
elif [ ${HEADER} -eq 1 ]
then
  echo -e "sum\tCount\tMean\tMedian\tMin\tMax\tStdv\tsem" 
fi

RAND=$((1 + RANDOM % 999999999))

# Old script that doesn't deal well with non numerical values as ut counts the line but can't sum the string.
#tee MM.mean-data.$RAND.MM | awk -v c=$COLUMN '{sum+=$c; sumsq+=$c*$c} END {print "Mean =",sum/NR; print "StDv =",sqrt(sumsq/NR - (sum/NR)**2); print "SEM =", (sqrt(sumsq/NR - (sum/NR)**2))/sqrt(NR)}'

# New script downlaoded from https://unix.stackexchange.com/questions/13731/is-there-a-way-to-get-the-min-max-median-and-average-of-a-list-of-numbers-in

cat > MM.mean-data.$RAND.MM
awk -v c=$COLUMN '{print $c}' MM.mean-data.$RAND.MM | sort -n | awk '
  BEGIN {
    c = 0;
    sum = 0;
  }
  $1 ~ /^[0-9]*(\.[0-9]*)?$/ {
    a[c++] = $1;
    sum += $1;
    sumsq += $1*$1
  }
  END {
    ave = sum / c;
    if( (c % 2) == 1 ) {
      median = a[ int(c/2) ];
    } else {
      median = ( a[c/2] + a[c/2-1] ) / 2;
    }
    stdv = sqrt( sumsq / c - ( sum / c)**2 )
    sem = (sqrt( sumsq / c - ( sum / c )**2)) / sqrt(c)
    OFS="\t";
    print sum, c, ave, median, a[0], a[c-1], stdv, sem;
  }
'

# Bootstrap
# Repicates
if [ -z ${BOOT+x} ]
then
  BOOT=1000
fi
# Samples
if [ -z ${SAMP+x} ]
then
  SAMP=$(cat MM.mean-data.$RAND.MM | wc -l)
fi
# Print output?
if [ -z ${OUTPUT+x} ]
then
  OUTPUT=0
fi


if [ -z ${RUNBOOT+x} ]
then
  RUNBOOTpointless=0 # I set this just to set somthing as the if statment asks of RUNBOOT is empty and so I needed to do something in this case
else
  for (( iterator=0; iterator<$BOOT; iterator++ ))
  do
    awk -v c=$COLUMN '{print $c}' MM.mean-data.$RAND.MM | shuf -rn $SAMP | awk '{sum+=$1; sumsq+=$1*$1} END {print sum/NR}'
  done > MM.boot-data.$RAND.MM
  
  if [ $OUTPUT -eq 1 ]
  then
    echo "bootstrap out put in MM.boot-data.$RAND.MM"
    twopointfive=$(echo "($BOOT*0.025)+0.1" | bc -l | xargs printf '%.0f\n')
    median=$(echo "($BOOT*0.5)+0.1" | bc -l | xargs printf '%.0f\n')
    nintysevenpointfive=$(echo "($BOOT*0.975)+0.1" | bc -l | xargs printf '%.0f\n')
    five=$(echo "($BOOT*0.05)+0.1" | bc -l | xargs printf '%.0f\n')
    nintyfive=$(echo "($BOOT*0.95)+0.1" | bc -l | xargs printf '%.0f\n')
    sort -n MM.boot-data.$RAND.MM | sed -n -e "${twopointfive}p" -e "${five}p" -e "${median}p" -e "${nintyfive}p" -e "${nintysevenpointfive}p" > MM.range.$RAND.MM
    echo "Bootstrap $BOOT repllicates of $SAMP samples"
    paste <(echo -e "$twopointfive\n$five\n$median\n$nintyfive\n$nintysevenpointfive") MM.range.$RAND.MM
  else
    twopointfive=$(echo "($BOOT*0.025)+0.1" | bc -l | xargs printf '%.0f\n')
    median=$(echo "($BOOT*0.5)+0.1" | bc -l | xargs printf '%.0f\n')
    nintysevenpointfive=$(echo "($BOOT*0.975)+0.1" | bc -l | xargs printf '%.0f\n')
    five=$(echo "($BOOT*0.05)+0.1" | bc -l | xargs printf '%.0f\n')
    nintyfive=$(echo "($BOOT*0.95)+0.1" | bc -l | xargs printf '%.0f\n')
    sort -n MM.boot-data.$RAND.MM | sed -n -e "${twopointfive}p" -e "${five}p" -e "${median}p" -e "${nintyfive}p" -e "${nintysevenpointfive}p" > MM.range.$RAND.MM
    echo "Bootstrap $BOOT repllicates of $SAMP samples"
    paste <(echo -e "$twopointfive\n$five\n$median\n$nintyfive\n$nintysevenpointfive") MM.range.$RAND.MM
    rm MM.boot-data.$RAND.MM
  fi
  rm MM.range.$RAND.MM
fi
rm MM.mean-data.$RAND.MM

