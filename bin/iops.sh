#!/bin/sh
# N8 2013

#Set this to the directory splunk is installed
#SPLUNK_HOME=/opt/splunk

#How long do you want it to run? seconds
TIME=7

#Number of threads
THREADS=5

#Get the splunk environment variables such as the DB directory
#Only necessary when testing from the CLI 
#. $SPLUNK_HOME/bin/setSplunkEnv

#Pick the disk location you want to test by specifying the index
#INDEX=defaultdb
INDEX=_internaldb

if [[ $EUID -ne 0 ]]; then
	#Since the user is not root, we cannot test the filesystem directly (reduces cache hits)
  #Instead let's find some large files to test
	HOME=`find $SPLUNK_DB/$INDEX/db/db_* -name journal.gz -type f -size +10000k | head -1`
	COLD=`find $SPLUNK_DB/$INDEX/colddb/ -name journal.gz -type f -size +10000k | head -1`
  RAW=false 

else
	HOME=`df $SPLUNK_DB/$INDEX/db | awk 'NR==2'| awk '{ print $1 }'`
  COLD=`df $SPLUNK_DB/$INDEX/colddb/ | awk 'NR==2'| awk '{ print $1 }'`
  RAW_WARM=true
  RAW_COLD=true
  if [[ $HOME == $COLD ]]; then
     COLD=""
     RAW_COLD=false
  fi  
fi 

for FILE in "$HOME" "$COLD"
do
    if [[ $FILE == *cold* ]] || [[ $RAW_COLD == true ]]; then
        STORAGE_TYPE=cold
    elif [[ $FILE == "" ]]; then
         if [[ $RAW_COLD == false ]]; then
             echo "No cold storage to test"
             exit 1
         else
             echo "No large enough file to test."
             exit 1
         fi
    else
        STORAGE_TYPE=warm
    fi

    if [[ $RAW == false ]]; then
           if ! type vmtouch > /dev/null; then
              echo "Please install vmtouch and add it to your path. I will continue but your results could wrong due to cache hits. See the README."
           else
               #Remove the file from cache
               vmtouch -eq $FILE
           fi
    fi

    FILE_SIZE_KB=`ls -alk $FILE | awk '{ print $5 }'`
    $SPLUNK_HOME/bin/splunk cmd python iops.py -n $THREADS -t $TIME $FILE -st $STORAGE_TYPE -fs $FILE_SIZE_KB
      
done
