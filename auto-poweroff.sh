#!/bin/sh
#
# Automatic poweroff based on rx/tx packet count
#
# Copyright (c) 2014 Maximilian Antoni <mail@maxantoni.de>

# @license MIT
#
# Install:
#   ln -s /root/auto-poweroff.sh /usr/syno/etc/rc.d/S99auto-poweroff.sh
#

# Log file location
LOGFILE=/var/log/auto-poweroff.log
# Number of silent minutes before automatic poweroff
MINUTES=90
# Number of packages to tolerate per minute
TOLERATE=100

# Set to 1 to see RX/TX diffs every minute in the log file.
# Note that this will prevent disk spin-down.
DEBUG=0

log() {
 echo `date '+%Y-%m-%d %H:%M:%S'` $1 >> $LOGFILE
}

rx() {
  cat /sys/class/net/eth0/statistics/rx_packets 
}

tx() {
  cat /sys/class/net/eth0/statistics/tx_packets 
}

monitor() {
  if [[ "$1" == "--minutes" || "$1" == "-m" ]]; then
    MINUTES=$2
  fi
  SILENT_MINUTES=0
  LAST_RX=`rx`
  LAST_TX=`tx`

  log "Initial RX: $LAST_RX, TX: $LAST_TX"
  log "Waiting for $MINUTES minutes of silence"

  while true; do
    sleep 60

    RX=`rx`
    TX=`tx`
    RX_DIFF=$(( $RX - $LAST_RX ))
    TX_DIFF=$(( $TX - $LAST_TX ))

    if [[ $RX_DIFF -le $TOLERATE && $TX_DIFF -le $TOLERATE ]]; then
      SILENT_MINUTES=$(( $SILENT_MINUTES + 1 ))
    else
      SILENT_MINUTES=0
    fi
    if [[ $DEBUG -eq 1 ]]; then
      log "RX: $RX_DIFF, TX: $TX_DIFF, Silent for $SILENT_MINUTES minutes"
    fi
    if [[ $SILENT_MINUTES -ge $MINUTES ]]; then
      log "Poweroff"
      poweroff
      exit 0
    fi

    LAST_RX=$RX
    LAST_TX=$TX
  done
}

pid() {
  ps | grep "auto-poweroff.sh monitor" | grep -v grep | awk "{ print \$1 }"
}

start() {
  PID=`pid`
  if [[ "$PID" == "" ]]; then
    log "Starting"
    $0 monitor $1 $2 &
    log "Started $!"
  else
    echo "Already running"
    exit 1
  fi
}

stop() {
  PID=`pid`
  if [[ "$PID" != "" ]]; then
    log "Stopping $PID"
    kill $PID
    log "Stopped"
  fi
}

case "$1" in
monitor)
  monitor $2 $3
  ;;
start)
  start $2 $3
  ;;
stop)
  stop
  ;;
status)
  if [[ "`pid`" == "" ]]; then
    echo "Not running"
    exit 1
  fi
  echo "Running"
  ;;
restart)
  stop
  start $2 $3
  ;;
*)
  echo "Usage: $0 [start|stop|restart|status]"
  echo ""
  echo "  --minutes, -m   Overrides the number of minutes"
  echo ""
  ;;
esac
