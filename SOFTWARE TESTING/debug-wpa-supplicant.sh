#!/usr/bin/env bash

# Enable debugging of WPA supplicant
# for authentication in wireless networks.

# Edit config file: /etc/sysconfig/wpa_supplicant
# Replace:
# OTHER_ARGS="-P /var/run/wpa_supplicant.pid"
# with
# OTHER_ARGS="-P /var/run/wpa_supplicant.pid -dddK"
# Restart WPA suplicant's service.

# Check prerequisites
if ! rpm --quiet -q wpa_supplicant; then
  echo "WPA supplicant is not installed" >&2
  sleep 3
  exit 1
fi

if ! [ -f /etc/sysconfig/wpa_supplicant ]; then
  echo "The configuration file of WPA supplicant missing or not recognized" >&2
  sleep 3 
  exit 2
fi

if ! [ -w /etc/sysconfig/wpa_supplicant ]; then
  echo "The configuration file of WPA supplicant cannot be edited." >&2
  sleep 3 
  exit 3
fi

sed -i '/OTHER_ARGS/d'  /etc/sysconfig/wpa_supplicant
echo 'OTHER_ARGS="-P /var/run/wpa_supplicant.pid -dddK"' >> /etc/sysconfig/wpa_supplicant
systemctl restart wpa_supplicant
