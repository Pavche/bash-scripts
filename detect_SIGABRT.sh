#!/usr/bin/env bash

# Catch Ctrl+C
function trap_ctrlc ()
{
  echo "Ctrl+C caught..."
  echo "Reconnection process interrupted at ${COUNT}-th iterration."
  echo
  echo "The modem did not crash."
  echo "SIGABRT not found in the journal."
  exit 2
}

function limit_journal_size () {
  # Valid for volatile journal, not persistent one.
  #RuntimeMaxUse=
  #RuntimeMaxUse=1M
  #RuntimeMaxUse=10M
  [ -z "$1" ] && return 1
  sed -i -e "s/#SystemMaxUse=/SystemMaxUse=$1/" /etc/systemd/journald.conf
  systemctl restart systemd-journald
}

COUNT=0
trap "trap_ctrlc" 2

limit_journal_size 1M

while ! journalctl | grep -q -w SIGABRT; do
  mmcli --modem 0 --simple-connect=apn=,ip-type=ipv4 &
  mmcli --modem 0 --simple-disconnect &
  COUNT=$((COUNT+1))
  sleep 1
done

echo "The modem broke on ${COUNT}-th iterration."

