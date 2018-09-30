#!/usr/bin/env bash

# Run an automated test using Python2 and Behave.
TEST=${1:?"Error.The variable 'TEST' is not specified."}

function check_prerequisites () {
  # External variables that must be defined in advance.
  if [ -z "$COMPONENT" ]; then
    echo "External variable \$COMPONENT is not defined." >&2
    exit 1
  fi

  if [ -z "$NOTEBOOK" ]; then
    echo "External variable \$NOTEBOOK is not defined." >&2
    exit 1
  fi
}

clear

check_prerequisites

while true; do
  # Synchronize the source code between laptop and testing machine.
  rsync -av "$NOTEBOOK:Work/$COMPONENT/*" .

  echo "Running automated test: $TEST"
  sleep 2
  behave -kt "$TEST"
  echo "Test $TEST completed."
  read key
  clear
  read -p "NEXT TEST: " ANSWER
  [ -z "$ANSWER" ] || TEST=$ANSWER
done
