#!/bin/bash
# Run Oracle Reports via rwrun command line
# Usage: runReport.sh <report_name> <userid> <desformat> <output_file>

REPORT=$1
USERID=$2
DESFORMAT=${3:-pdf}
OUTPUT=$4

export ORACLE_HOME=/u01/app/oracle/product/fmw14.1.2.0
export REPORTS_PATH=/u01/app/oracle/reports_source
export TNS_ADMIN=$ORACLE_HOME/network/admin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/reports/lib
export DISPLAY=:99

# Start Xvfb if not running
pgrep Xvfb > /dev/null || Xvfb :99 -screen 0 1024x768x24 &
sleep 2

# Run report using rwrun
$ORACLE_HOME/reports/bin/rwrun \
    report=$REPORT \
    userid=$USERID \
    desformat=$DESFORMAT \
    destype=file \
    desname=$OUTPUT \
    batch=yes

exit $?
