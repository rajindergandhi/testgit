#!/bin/ksh
. $HOME/scriptvar
#set -x

#---------------------------------------------------------------------------------------------------------
# Script Name           : TACCREV_dwh_exp.sh
# Purpose               : Generates Account Vol/Rev exports file for DWH
# Destination file      : /home/espadmin/esp/data/export/dwh/TACCRVMP<pln_typ>.<tmprd>.data.gz
# DWH Trigger Signature 
# file                  : /home/espadmin/esp/data/export/dwh/TACCRVMP<pln_typ>.<tmprd>.data.done
# Run Frequency         : Weekly - Sundays
# Interface agreement on LAN (UNC Path): \\Parnas1\sales applications\ESP\2008 ESP\8.1\DWH\IA ESP Revenue.doc
#---------------------------------------------------------------------------------------------------------
#        Example from April 2010 (Alignment context is 40)
# Parameters: 1 = ORAINST Oracle Instance   P559
#  2 = tm     Time Period (month)  201011
#  3 = cx     Alignment Context to use 40  (alignment cx to use for parm 2 time period)
#  4 = ver    SLS_PLN_VER_TYP_CD  C=Current, F=Future  (derived from parm 2 time period)
#  5 = cx_mth 1st Tm Prd of Alignment Cx 201004  (tm prd of parm 2; latest alignment month)
#  6 = pln_typ Plan Type Code   '01'=Yr-2  '02'=Yr-1  '03'=Plan  '04'=Actuals
#  7 = do_ftp Enable FTP (T or F)  'T'=True,do FTP   'F'=False,disable FTP
#---------------------------------------------------------------------------------------------------------

ORAINST=$1
tm=$2
cx=$3
ver=$4
cx_mth=$5
pln_typ=$6
do_ftp=$7

LOGFILE="/home/espadmin/esp/log/export/TACCREV.dwh_exp.$pln_typ.$tm.`date +%m%d%y_%H%M`.log"
DWHEXPORTS="/home/espadmin/esp/data/export/dwh"


echo "BEGIN on `date +%d/%m/%Y` at `date +%H:%M:%S` \n" >> $LOGFILE 2>&1

rm -f $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data.done $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data.gz

. /usr/local/bin/sid $ORAINST >> $LOGFILE 2>&1

echo "\n *** Getting $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data *** \n" >> $LOGFILE 2>&1

$ORACLE_HOME/bin/sqlplus -s $CONNECT_ESP << EOF  >> /dev/null
set heading off
set feedback off
set pagesize 0
set space 0
set newpage 0
set echo off
set termout off
set serveroutput off

var CurMonth number
begin
 select $cx_mth into :CurMonth from dual;
end;
/
print :CurMonth

set linesize 151
spool $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data
SELECT LPAD(a.ac_sys_nr,10)||
 '01' ||
 ---decode(sign(a.sls_pln_grr_tcy_a),-1,'-','+')||
 to_char(nvl(a.sls_pln_grr_tcy_a,0) , 's00000000000000.99999999')||
 ---decode(sign(a.sls_pln_nrv_tcy_a),-1,'-','+')||
 to_char(nvl(a.sls_pln_nrv_tcy_a,0), 's00000000000000.99999999')||
 ---decode(sign(a.sls_pln_vol_qy),-1,'-','+')||
 to_char(nvl(a.sls_pln_vol_qy,0) ,'s0000000000.999999')||
 a.tm_prd_nr||
 rpad(a.pdc_nr,3)||
 '03' ||
 a.mkg_pln_dtl_typ_cd||
 a.mkg_pln_typ_cd||
 ---decode(sign(a.sls_pln_grr_lcy_a),-1,'-','+')||
 to_char(nvl(a.sls_pln_grr_lcy_a,0),'s00000000000000.99999999')||
 ---decode(sign(a.sls_pln_nrv_lcy_a),-1,'-','+')||
 to_char(nvl(a.sls_pln_nrv_lcy_a,0),'s00000000000000.99999999')||
 RPAD(a.alt_ccy_cd,3)||
 :CurMonth||'X'
FROM aesp01.taccrev a where a.tm_prd_nr = $tm  and mkg_pln_typ_cd = '$pln_typ'; 
spool off;
exit
EOF

##mxa 09/2011 - FTP to mainframe moved out of this script (and moved to run on Saturdays)

##if [ "$pln_typ" = "03" ]; then
##
## echo "\n do_ftp = $do_ftp \n" >> $LOGFILE 2>&1
##
## if [ "$do_ftp" = "T" ]; then
##
##  ./ftp_to_spmf.sh  $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data  N427.ESTAT.SPMF.ESP.ACREV.DT$tm  $LOGFILE
## else
##  echo "FTP is turned off.  Skipping the Account level Plan VnR FTP to SMF... no TACCRVMP$pln_typ.$tm.data to N427.ESTAT.SPMF.ESP.ACREV.DT$tm ... script $0"
##  echo "FTP is turned off.  Skipping the Account level Plan VnR FTP to SMF... no TACCRVMP$pln_typ.$tm.data to N427.ESTAT.SPMF.ESP.ACREV.DT$tm" >> $LOGFILE 2>&1
## fi
##fi

echo "\n *** Zipping the data file *** \n" >> $LOGFILE 2>&1
gzip $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data
touch $DWHEXPORTS/TACCRVMP$pln_typ.$tm.data.done

echo "\n*** Check log file $LOGFILE ***\n" >> $LOGFILE 2>&1
date >> $LOGFILE 2>&1
exit 0
