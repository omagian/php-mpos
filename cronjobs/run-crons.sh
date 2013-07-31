#!/bin/bash


#########################
#                       #
# Configuration Options #
#                       #
#########################
# PHP Detections, if this fails hard code it
PHP_BIN=$( which php )

# List of cruns to execute
CRONS="findblock.php proportional_payout.php pplns_payout.php pps_payout.php blockupdate.php manual_payout.php auto_payout.php tickerupdate.php notifications.php statistics.php archive_cleanup.php"

# Output additional runtime information
VERBOSE="0"

# Prefix to add to PIDFILE name, so it will be unique in a multipool server.
# Can be left empty or set Eg. PIDPREFIX="LTC" / PIDPREFIX="DMD"
PIDPREFIX=""

################################################################
#                                                              #
# You probably don't need to change anything beyond this point #
#                                                              #
################################################################

# My own name
ME=$( basename $0 )

# Path to PID file, needs to be writable by user running this
PIDFILE="/tmp/$PIDPREFIX$ME.pid"

# Overwrite some settings via command line arguments
while getopts "hvp:" opt; do
  case "$opt" in
    h|\?)
      echo "Usage: $0 [-v] [-p PHP_BINARY]";
      exit 0
      ;;
    v) VERBOSE=1 ;;
    p) PHP_BIN=$OPTARG ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
    ;;
  esac
done

# Find scripts path
if [[ -L $0 ]]; then
  CRONHOME=$( dirname $( readlink $0 ) )
else 
  CRONHOME=$( dirname $0 )
fi

# Change working director to CRONHOME
if ! cd $CRONHOME 2>/dev/null; then
  echo "Unable to change to working directory \$CRONHOME: $CRONHOME"
  exit 1
fi

# Confiuration checks
if [[ -z $PHP_BIN || ! -x $PHP_BIN ]]; then
  echo "Unable to locate you php binary."
  exit 1
fi

if [[ ! -e 'shared.inc.php' ]]; then
  echo "Not in cronjobs folder, please ensure \$CRONHOME is set!"
  exit 1
fi

# Our PID of this shell
PID=$$

if [[ -e $PIDFILE ]]; then
  echo "Cron seems to be running already"
  RUNPID=$( cat $PIDFILE )
  if ps fax | grep -q "^\<$RUNPID\>"; then
    echo "Process found in process table, aborting"
    exit 1
  else
    echo "Process $RUNPID not found. Plese remove $PIDFILE if process is indeed dead."
    exit 1
  fi
fi

# Write our PID file
echo $PID > $PIDFILE

for cron in $CRONS; do
  [[ $VERBOSE == 1 ]] && echo "Running $cron, check logfile for details"
  $PHP_BIN $cron
done

# Remove pidfile
rm -f $PIDFILE
