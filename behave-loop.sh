#!/usr/bin/env bash

FEATURE_FILE=${1:-'features/network/wifi.feature'}
N=${1:-'5'}

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

for i in $(seq 1 1 $N); do
  echo "=== Repetition: $i ==="
  echo behave-3 -k $FEATURE_FILE | tee $LOG_FILE
  echo sleep 3
  
  echo mv $LOG_FILE ${LOG_FILE/.log/_$i.log}
  echo "Log from last run: ${LOG_FILE/.log/_$i.log}"
  
  echo "=== Repetition: $i - End ==="
  echo sleep 1
done

echo
echo "CHECK RESULTS"
for i in $(seq 2 1 $N); do
  echo "Comparing: ${LOG_FILE/.log/_1.log}  to  ${LOG_FILE/.log/_$i.log}"
  echo diff "${LOG_FILE/.log/_1.log}" "${LOG_FILE/.log/_$i.log}"
  echo "====="
done
