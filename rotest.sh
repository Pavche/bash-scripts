#!/usr/bin/env bash

# Repeat the same automated test N-times. Each test name is marked with uniq tag.
# Results are stored in log files, separate logs for different tests.

# Prerequisites
TEST_TAG=${1:?"Error. Specify the test tag for an automated test."}
# No. of repetitions
N=5

export TEST=control-center_Test_"$TEST_TAG"
LOG_FILE=results_$(uname -p)_$(hostname --short)_"$TEST_TAG".log
CPU_ARCH=$(uname -p)
rm -f "$LOG_FILE"

# Repeat the same result until the bug comes out.
for i in $(seq 1 1 $N); do
  echo "=========================================================="
  echo "Start test \"$TEST_TAG\". Repetition No: $i"
  echo "=========================================================="
  ./runtest.sh "$TEST_TAG"
  if [ $? -eq 0 ]; then
    echo "i: $i - success" >> "$LOG_FILE"
  else
    echo ": $i - failure" >> "$LOG_FILE"
    echo "GAME OVER"
    echo "Test \"$TEST_TAG\" failed at repetition No: $i"
    echo "Now get the system journal and send it to dear developpers."
    exit 1
  fi
  sleep 5  # Rest from the test :)
done

# Author: Pavlin Georgiev
# Created on: 11 Dec 2017
# Last updated on: 11 Dec 2017
