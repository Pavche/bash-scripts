#!/usr/bin/env bash

# Execute multiple test scenarios
# from a feature file
# via python3-behave
# when logged to a GNOME session.

# Script arguments
FEATURE_FILE=${1:-'features/network/wifi.feature'}
N=${2:-'5'}

# Validate arguments
if [ ! -f "$FEATURE_FILE" ]; then
  echo "File \"$FEATURE_FILE\" does not exist." >&2
  exit 1
fi

# Check if N is a positive integer.
if echo $N | grep -q -w -E "[1-9][0-9]*"; then
  echo "OK. $N is a positive integer".
else
  echo "Invalid argument: N=$N. Should be a positive integer." >&2
  exit 1
fi

LOG_FILE=${FEATURE_FILE%feature}log

echo "Testing file:"
echo $FEATURE_FILE
echo
echo "Repetitions: $N"
echo

# how to run the test?
# behave-3 -k $FEATURE_FILE

# How to catch the output?
# tee $LOG_FILE

# How to repeat the test?
# for i in {1..N}; do
#   behave-3 -k $FEATURE_FILE tee $LOG_FILE
# done

# How to rename LOG_FILE after test?
# echo ${LOG_FILE/.log/_$i.log}

# How to be verbose?
# echo $i
# echo $LOG_FILE


# How to compare results?
# Get the 1st and compare with the rest.
# diff ${LOG_FILE/.log/_1.log} ${LOG_FILE/.log/_$i.log}
function testing_loop() {
  for i in $(seq 1 1 $N); do
    echo "=== Repetition: $i ==="
    echo "Logging events to file: $LOG_FILE"
    
    behave-3 -k "$FEATURE_FILE" > "$LOG_FILE" 2>&1
    sleep 3
    
    mv $LOG_FILE ${LOG_FILE/.log/_$i.log}
    echo "Log from last run: ${LOG_FILE/.log/_$i.log}"
    
    echo "=== Repetition: $i - End ==="
    sleep 1
  done
}

function check_results() {
  echo
  echo "CHECK FINAL RESULTS"
  echo "Get the last 20 lines of each log."

  tail -n 20 "${LOG_FILE/.log/_1.log}" > "${LOG_FILE/.log/_1.tmp}"

  if [ $N -ge 2 ]; then
    for i in $(seq 2 1 $N); do
      echo "Comparing: ${LOG_FILE/.log/_1.log}  to  ${LOG_FILE/.log/_$i.log}"
      
      tail -n 20 "${LOG_FILE/.log/_$i.log}" > "${LOG_FILE/.log/_$i.tmp}"
      
      diff "${LOG_FILE/.log/_1.tmp}" "${LOG_FILE/.log/_$i.tmp}"
      echo "====="
    done
  else
    echo "Nothing to compare."
    echo "See results from a single scenario cycle."
    tail "${LOG_FILE/.log/_1.tmp}"
  fi
}

# ===== MAIN =====
testing_loop
check_results

# How to run on background?
# Use application "screen".

# Author: Pavlin Georgiev
# Created on: 23 June 2019
# Last update: 24 June 2019