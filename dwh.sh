#!/bin/ksh
. $HOME/scriptvar
. $HOME/esp/scripts/export/dwh/dwh_exports.maillist


PROCESS_NAME="2018 Annual ESTAT/ESP Data Purge"
DISABLE_IR="F" # T - True, F - False - Used to force exit the whole process

DO_FTP=$3  
# T-True or F -False 

###################################################################
# Purpose:  Run the DWH exports for current year
###################################################################
#     Example
# Parameter:  1 = Oracle Instance D559
#  2 = Year  2013
#  3 = Do_FTP  T (True)  F (False)
#
# nohup /home/espadmin/esp/scripts/export/dwh/dwh.sh A559 2013 T &
###################################################################
##------------------------------------------##
##          Modification History            ##          
##------------------------------------------##
## Description: New Requirement for DRIVE - ##
## Purpose:     Send Files to SMF         - ##
## Date:        April , 2017              - ##
## Author:      SFK0HRD                   - ##
##------------------------------------------##

# 1 parameter for development: Oracle instance (not required in production)

mypid=$$

yr_nr=$2

starttp=$yr_nr"01"
endtp=$yr_nr"12"


LOGFILE="/home/espadmin/esp/log/export/dwh_{$yr_nr}_`date +%m%d%y_%H%M`.log"
SCRIPTSDIR="/home/espadmin/esp/scripts/export/dwh"
BOX=$4

if [ "${BOX}" = "production" ]; then

 ORA_INST=P559
 EMAILLIST="$EmailList_Production"
else
 ORA_INST=$1
 EMAILLIST="$EmailList_Develpment"
fi

################################################################################
################################################################################
######
###### TO "DISABLE" THIS JOB, Set "DISABLE_IR" to "T" at the top of the script.
######

if [ "$DISABLE_IR" = "T" ]; then


echo "THIS JOB IS CURRENTLY DISABLED FOR THE $PROCESS_NAME PROCESS. You must UPDATE the script to enable this job. -  `date`" >> $LOGFILE 2>&1
mailx -s "$ORA_INST - THIS JOB IS CURRENTLY DISABLED FOR THE $PROCESS_NAME PROCESS - Script: $0"  $EMAILLIST  <$LOGFILE

exit 0

fi

######
###### TO "ENABLE" THIS JOB, Set "DISABLE_IR" to "F" at the top of the script.
################################################################################
################################################################################

if [ "$ORA_INST" = "" ]; then  echo "\nMissing parameter:  Oracle instance" >> $LOGFILE ; exit; fi

cd $SCRIPTSDIR

echo "DWH $yr_nr Exports begin on `date +%m/%d/%Y` at `date +%H:%M` \n" > $LOGFILE 2>&1

. /usr/local/bin/sid $ORA_INST >> /dev/null

run_typ=`./get_run_typ.sh $ORA_INST`
active_mth=`./get_max_cx_mth.sh $ORA_INST $yr_nr`

echo "Run Type for DWH is $run_typ" >> $LOGFILE 2>&1
echo "Year is $yr_nr"   >> $LOGFILE 2>&1
echo "Active month is $active_mth"  >> $LOGFILE 2>&1
echo "Oracle SID is $ORACLE_SID"  >> $LOGFILE 2>&1

case $run_typ in

0)

# THIS IS FOR NON-SNAPSHOT WEEK  
# REFRESH VnR FILES ALL PLAN TYPES and ALL VnR LEVELS
# REFRESH COMM EXPORTS
# SEND TRIGGER FILE TO DWH



EMAILLISTCOMMSPEC="$EmailList_ESTAT_COMMSPEC"

tm=`date +%I:%M%p`
dyl=`date +%A`
mt=`date +%b`
dy=`date +%d`
yr=`date +%Y`

echo "At  $tm, $dyl, $mt. $dy, $yr, the Oracle DB process of producing the  ESP (DWH) COMMSPEC (COMMON EXPORTS)  has started." | mailx -s "ESP (DWH) COMMSPEC (COMMON EXPORTS) Has Started" $EMAILLISTCOMMSPEC


./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "01" $DO_FTP &
./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "02" $DO_FTP &
./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "03" $DO_FTP &
./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "04" $DO_FTP &
./dwh_exp.sh $ORA_INST TSVCREV_dwh_exp.sh $starttp $endtp "NA" $DO_FTP &
./dwh_exp.sh $ORA_INST TNODREV_dwh_exp.sh $starttp $endtp &
./dwh_exp.sh $ORA_INST TCUSREV_dwh_exp.sh $starttp $endtp &
./dwh_exp.sh $ORA_INST TSVWKD_dwh_exp.sh  $starttp $endtp &
./dwh_exp.sh $ORA_INST ESP_EST_COMM_EXPORTS.sh $starttp $active_mth 
./childprocesswait.sh $mypid
./dwh_trigger.sh $ORA_INST $yr_nr $active_mth $DO_FTP
##------------------------------------------##
## Description: New Requirement for DRIVE - ##
## Purpose:     Send Files to SMF         - ##
## Date:        April , 2017              - ##
## Author:      SFK0HRD                   - ##
##------------------------------------------##
retcd=$?
if [[ $retcd -ne 0 ]]
then
   echo "DWH TRIGGER did not return code 0. Monthly VNR feed will not be sent to SMF (DRIVE). \n" >> $LOGFILE 2>&1
else
   echo "DWH TRIGGER OK. Monthly VNR feed will be sent to SMF (DRIVE). \n" >> $LOGFILE 2>&1
   /home/espadmin/esp/scripts/export/dwh/ESP_SMF_Monthly_VNR.sh $yr_nr $active_mth T $ORA_INST T &

EMAILLISTCOMMSPEC="$EmailList_ESTAT_COMMSPEC"

tm=`date +%I:%M%p`
dyl=`date +%A`
mt=`date +%b`
dy=`date +%d`
yr=`date +%Y`

echo "At  $tm, $dyl, $mt. $dy, $yr, the Oracle DB process of producing the  ESP (DWH) COMMSPEC (COMMON EXPORTS)  has COMPLETED." | mailx -s "ESP (DWH) COMMSPEC (COMMON EXPORTS) Has COMPLETED" $EMAILLISTCOMMSPEC



fi

;;

1)

# THIS IS FOR SNAPSHOT WEEK (PARTIAL SNAPSHOT)
# REFRESH HISTORY + PLAN ACCT REV ONLY    pln_typ's 01, 02, 03
# REFRESH COMM EXPORTS
# TRIGGER FILE NOT SENT


EMAILLISTCOMMSPEC="$EmailList_ESTAT_COMMSPEC"

tm=`date +%I:%M%p`
dyl=`date +%A`
mt=`date +%b`
dy=`date +%d`
yr=`date +%Y`

echo "At  $tm, $dyl, $mt. $dy, $yr, the Oracle DB process of producing the  ESP (DWH) COMMSPEC (COMMON EXPORTS)  has started." | mailx -s "ESP (DWH) COMMSPEC (COMMON EXPORTS) Has Started" $EMAILLISTCOMMSPEC




./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "01" $DO_FTP &
./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "02" $DO_FTP &
./dwh_exp.sh $ORA_INST TACCREV_dwh_exp.sh $starttp $endtp "03" $DO_FTP &
./dwh_exp.sh $ORA_INST ESP_EST_COMM_EXPORTS.sh $starttp $active_mth
    

EMAILLISTCOMMSPEC="$EmailList_ESTAT_COMMSPEC"

tm=`date +%I:%M%p`
dyl=`date +%A`
mt=`date +%b`
dy=`date +%d`
yr=`date +%Y`

echo "At  $tm, $dyl, $mt. $dy, $yr, the Oracle DB process of producing the  ESP (DWH) COMMSPEC (COMMON EXPORTS)  has COMPLETED." | mailx -s "ESP (DWH) COMMSPEC (COMMON EXPORTS) Has COMPLETED" $EMAILLISTCOMMSPEC


;;

2)

# THIS IS FOR SNAPSHOT WEEK (PARTIAL SNAPSHOT)
# REFRESH CURRENT ACTUALS FILES ONLY    pln_typ 04
# REFRESH COMM EXPORTS FOR CURRENT MONTH ONLY
# SEND TRIGGER FILE TO DWH

# Run Type 2 is run manually after the INTL Snapshot completes
# See /home/espadmin/esp/scripts/export/dwh/intl_dwh.sh

;;

3)

# THIS IS FOR SNAPSHOT WEEK (FULL SNAPSHOT)
# DON'T RUN ANYTHING 
# WAIT FOR US SMALL PKG ACTUALS TO IMPORT
# THEN RUN FULL DWH EXPORT
# SEE /home/espadmin/esp/scripts/import/imp_us_actual_exp_dwh.sh



echo "Run Type $run_typ - DWH $yr_nr job will be started after US Small Pkg import completes \n" >> $LOGFILE 2>&1


esac

echo "\n DWH $yr_nr Job END on `date +%m/%d/%Y` at `date +%H:%M` \n" >> $LOGFILE 2>&1

mailx -s "$ORA_INST - ESP DWH $yr_nr exports job completed"  $EMAILLIST < $LOGFILE 2>&1

exit 0
