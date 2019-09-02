#!/usr/bin/env bash

# Enable debugging of WPA supplicant
# for authentication in wireless networks.

# Edit config file: /etc/sysconfig/wpa_supplicant
# Replace:
# OTHER_ARGS="-P /var/run/wpa_supplicant.pid"
# with
# OTHER_ARGS="-P /var/run/wpa_supplicant.pid -dddK"
# Restart WPA suplicant's service.

sed -i '/OTHER_ARGS/d'  /etc/sysconfig/wpa_supplicant
echo 'OTHER_ARGS="-P /var/run/wpa_supplicant.pid -dddK"' >> /etc/sysconfig/wpa_supplicant
systemctl restart wpa_supplicant
