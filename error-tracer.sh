#!/usr/bin/env bash

# Detect errors in the journal comming from the kernel.
# I use it for tracing events when authenticating to Wi-Fi networks.

N=${1:?"Error: number of iterrations not defined."}

if [ -z "$TEST" ]; then
  echo "Env variable TEST not defined." > &2
  exit 1
fi


for i in $(seq 1 $N); do
  echo
  echo "Start monitoring events."
  journalctl -f -o cat -k > /tmp/journal_kernel.log &

  echo
  echo "Start test: $TEST"
  behave-3 -k -t $TEST; RC=$?

  if [ $RC -eq 0 ]; then
    echo "Test $TEST succeeded."
  else
    echo "Test $TEST failed." >&2
  fi

  echo
  echo "Stop monitoring events."
  sudo kill -s 2 $(pidof journalctl)

  sleep 2

  echo
  FILENAME='journal_kernel.log'
  echo "Events logged in: /tmp/${FILENAME%.log}_$i.log"
  sudo mv /tmp/journal_kernel.log /tmp/journal_kernel_$i.log
done

# Author: Pavlin Georgiev
# Created on: 26 June 2019
# Last update: 26 June 2019
