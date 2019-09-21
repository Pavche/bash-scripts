#!/usr/bin/env bash

for grp in \
"Minimal Install" \
"Server with GUI" \
"GNOME Desktop" \
"Development and Creative Workstation" \
"Development Tools" \
"General Purpose Desktop" \
"Security Tools" \
"System Administration Tools" \
"System Management"
do
  yum groups install -y "$grp"
  [ $? -eq 0 ] || read key
done
