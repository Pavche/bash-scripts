#!/usr/bin/env bash

# Catch Ctrl+C
function trap_ctrlc ()
{
  echo "Ctrl+C caught..."
  echo "Reconnection process interrupted at ${COUNT}-th iterration."
  echo
  echo "The modem did not crashed."
  echo "SIGABRT not found in the journal."
  exit 2
}

trap "trap_ctrlc" 2
