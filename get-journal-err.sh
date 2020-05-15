#!/usr/bin/env bash

# Get errors from the system journal
# from servers listed in file servers.in

for server in $(<~/servers.in)
do
  echo "Get errors from server: $server"
  sleep 2
  ssh root@$server "journalctl -p err"
  read key
  clear
done
