#!/bin/ksh
HOME="/root"
. $HOME/scriptvar

ORAINST=$1
SCRIPTNAME=$2
start_tm=$3
end_tm=$4
pln_typ=$5
do_ftp=$6

SCRIPTSDIR=/home/espadmin/esp/scripts/export/dwh

cd $SCRIPTSDIR

. /usr/local/bin/sid $ORAINST

for tm in `./get_tm_prd_nr.sh $ORAINST $start_tm $end_tm`
do

cx=`./get_cx.sh $ORAINST $tm`
ver=`./get_ver.sh $ORAINST $tm`
cx_mth=`./get_cx_mth.sh $ORAINST $cx`
./$SCRIPTNAME $ORAINST $tm $cx $ver $cx_mth $pln_typ $do_ftp

done

