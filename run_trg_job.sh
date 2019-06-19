#!/bin/ksh
. $HOME/scriptvar
#set -x

#------------------------------------------------------------------------------
# Set script name for alerts
#------------------------------------------------------------------------------
export SCRIPT_NAME=$(basename $0)

#------------------------------------------------------------------------------
# Alert beeper when script exits
#------------------------------------------------------------------------------
. /home/espadmin/esp/scripts/import/alert_on_exit.sh


#------------------------------------------------------------------------------
# Main script
#------------------------------------------------------------------------------
OLDIFS=$IFS
IFS="
"
cd /home/espadmin/esp/data/espload/stage_imp
while true
do
for msgfile in `ls *.msg`
do
for jb in `cat /home/espadmin/esp/scripts/import/trg_job_lst.txt`
do
mc=`echo $msgfile | grep -c ${jb%% *}`
if [[ $mc -eq 1 ]]
then
IFS=$OLDIFS
${jb#* } $msgfile
OLDIFS=$IFS
IFS="
"
break
fi

done
done

sleep 300
done


