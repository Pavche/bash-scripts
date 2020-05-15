#!/usr/bin/env bash

SERVER_LIST="eduroam.egi.eu
mailman.egi.eu
www.egi.eu
wiki.egi.eu
aldor.ics.muni.cz
documents.egi.eu
www.metacentrum.cz
rt.egi.eu
indico.egi.eu
portal.egi.eu
mailman.cerit-sc.cz
rt4.egi.eu
wiki.metacentrum.cz
deb8.egi.eu
www.opensciencecommons.org
sso.egi.eu
documents.metacentrum.cz
confluence.egi.eu"

echo "Check IPv6 addresses"
echo



for S in $SERVER_LIST2
do
  echo "Hostname: $S"
  dig -t AAAA +short $S
  echo
  ssh root@$S "ip -6 a s"
  read key
  clear
done
