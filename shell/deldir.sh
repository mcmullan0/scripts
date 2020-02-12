#!/usr/bin/env bash

# Quickly removes directories containing large numbers of files
# Accepts multiple -d <directories>

RAND=$((1 + RANDOM % 999999))

while getopts "d:" opt
do
  case $opt in
    d)
      MULTIDIR+=("$OPTARG")
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

# If nothing print help
if [ ${#MULTIDIR[@]} -eq 0 ]
then
  echo -ne "\n\n########################################################### deldir.sh ############################################################\n"
  echo -ne "# Quickly removes directories containing large numbers of files\n"
  echo -ne "# Use -d for each directory\n"
  echo -ne "# Works by dividing files per directory into 10,000 and deleting each set as a seperate job\n"
  echo -ne "#######################################################################################################################################\n\n"
  exit 1
fi

echo -en "You have provided ${#MULTIDIR[@]} directories for deletion\n"
for DIRJOBS in ${MULTIDIR[@]}
do
  echo "generating $DIRJOBS file list and splitting jobs:"
  ls ${DIRJOBS}/ > MM.del.${DIRJOBS}.${RAND}.list
  split -a 3 -dl 3000 MM.del.${DIRJOBS}.${RAND}.list MM.del.${DIRJOBS}.${RAND}.list.
  ls MM.del.${DIRJOBS}.${RAND}.list.*
done

for DIRJOBS in ${MULTIDIR[@]}
do
  for SPLITFILE in MM.del.${DIRJOBS}.${RAND}.list.*
  do
    submit-slurm.pl -j del-${SPLITFILE} -i "while read DELETEME
    do
      rm ${DIRJOBS}/\${DELETEME}
    done < ${SPLITFILE}"
  done
done

CONTINUE=$(squeue -u "$USER" | grep -c 'MM-del')
WAITTIME=1
TIMEWAIT=0
echo -e "\nThere are $CONTINUE jobs running (deleting)."
while [[ "$CONTINUE" -gt "0" ]]
do
  sleep ${WAITTIME}m
  TIMEWAIT=$(( $TIMEWAIT + $WAITTIME ))
  CONTINUE=$(squeue -u "$USER" | grep -c 'MM-del')
  echo -e "${TIMEWAIT} minutes\tThere are $CONTINUE jobs running (deleting)."
done

for DIRJOBS in ${MULTIDIR[@]}
do
  rm -r ${DIRJOBS}/
done
rm MM.del.*.${RAND}.lis* del-MM.del.*.${RAND}.list.*.slurm

echo -e "\n\n\nAll directories deleted\n\n"
