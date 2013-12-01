#!/bin/sh
# N8 2013

#How long do you want it to run? seconds
TIME=7

#Number of threads
THREADS=5

#If testing from the CLI
#Get the splunk environment variables such as the DB directory
#Set this to the directory splunk is installed
#SPLUNK_HOME=/opt/splunk
#. $SPLUNK_HOME/bin/setSplunkEnv

$SPLUNK_HOME/bin/splunk cmd python ./bin/iops.py -n $THREADS -t $TIME ./lookups/iops_test_files.csv
