#!/bin/ksh
. $HOME/scriptvar
#set -x

EMAILLIST="$EmailList_ESP"


# This script will start the background process 'run_trg_job.sh' to load files specified in 'trg_job_lst.txt' whenever they become available


SCRIPTS_DIR="/home/espadmin/esp/scripts/import"
LOGFILE="/home/espadmin/esp/log/import/run_trg_job.sh-`date +%Y%m%d`.log"

cd $SCRIPTS_DIR

if [ "$BOX" = "production" ]; then

 LOCATION="Production"
else
 LOCATION="Development" 
fi


#  because run_trg_job.sh runs in an infinite loop until server is rebooted, check to make certain the job is not already running

ps -ef | grep -i "run_trg_job\.sh" | grep -iv "grep" > /dev/null

if [ $? = 0 ]; then

 mailbody="\nThe background job 'run_trg_job.sh' is already running \n\nSCRIPT: $0 \nSCRIPT: $SCRIPTS_DIR/run_trg_job.sh \nLOGFILE: $LOGFILE" 

else
 nohup ./run_trg_job.sh   >> $LOGFILE 2>&1 &

 mailbody="\nThe background job 'run_trg_job.sh' has been started \n\nSCRIPT: $0 \nSCRIPT: $SCRIPTS_DIR/run_trg_job.sh \nLOGFILE: $LOGFILE"  
fi


echo "$mailbody" | mail -s "$LOCATION - Start Background Import Trigger Process" $EMAILLIST

exit 0

