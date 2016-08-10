#!/usr/bin/env bash

while getopts "c:" opt
do
  case $opt in
    c)
      COLUMN=$OPTARG
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

if [ -z ${COLUMN+x} ]
then
  echo -ne "\n\n########################################################### mean.sh ############################################################\n"
  echo -ne "#     A script that Provids the mean, Standard Devaiaiton and Standard Error of the Mean                                       #\n"
  echo -ne "#     Provide a table or column of numbers via the pipe and then use -c to tell mean.sh which column you want to read in       #\n"
  echo -ne "################################################################################################################################\n\n"
  exit 1
fi

awk -v c=$COLUMN '{sum+=$c; sumsq+=$c*$c} END {print "Mean =",sum/NR; print "StDv =",sqrt(sumsq/NR - (sum/NR)**2); print "SEM =", (sqrt(sumsq/NR - (sum/NR)**2))/sqrt(NR)}'
