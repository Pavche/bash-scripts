#!/usr/bin/env bash

# Test a broadband modem and ModemManager.
# The goal is to monitor the behavior of the modem
# attached to the system via USB port, mini PCI-e, or M.2 interface.
# Tested under RHEL 8.0 Beta.

export LOG_DEST=${1:?"Error. Please, specify log destination. Local or remote: user@remote_host.com:test_dir/."}

export REQUIRED_PACKAGES='ModemManager
usb_modeswitch
usb_modeswitch-data
NetworkManager
NetworkManager-wwan
NetworkManager-ppp
usbutils'


# User defined functions.
function install_prerequisites () {
  echo 'Installing needed packages for testing ModemManager...'
  yum install -y $REQUIRED_PACKAGES
  # Do not put quotes arround the variable above, otherwise won't install.
  
  # Start required services.
  for S in ModemManager NetworkManager; do
    if ! systemctl -q is-active $S; then
      systemctl start $S
    fi
  done  
}


function check_prerequisites () {
  if rpm --quiet -q $REQUIRED_PACKAGES; then
    echo "OK. Required packages are installed."
  else
    echo "Error: Not all required packages are installed." >&2
    echo -e "\nPackage list:\n$REQUIRED_PACKAGES"
    return 1
  fi

  # Check if required services are running.
  for S in ModemManager NetworkManager; do
    if ! systemctl -q is-active $S; then
      echo "Error: $S is not active but required." >&2
      return 1
    fi
  done
  echo "OK. All required services are active."
}


function collect_logs () {
  local LOG_DEST_DIR=${1:?"Error: Destination dir for collecting logs is missing."}

  # Check for required directories. Exit if not found
  if [ ! -d "$LOG_DEST_DIR" ]; then
    echo "Directory \"$LOG_DEST_DIR\" does not exist but it is required." >&2
    return 1
  fi

  pushd "$LOG_DEST_DIR"
  
  # Get full journal from the last boot.
  journalctl -b 0 > "journal_$(hostname --short).log"
  
  # Get journal from certain services.
  for S in NetworkManager ModemManager; do
    journalctl -b 0 -u $S -o cat > "journal_$S.log"
  done

  # Get info about USB devices.
  lsusb > "lsusb.log"
  
  echo "Get info about the 1st connected modem."  >> "mmcli.log" 2>&1
  mmcli --modem 0 >> "mmcli.log" 2>&1
  
  echo "Get information about the 1st SIM card." >> "mmcli.log" 2>&1
  mmcli --sim 0  >> "mmcli.log" 2>&1

  # Get info about GSM network devices from NetworkManager.
  echo "GSM network devices in NetworkManager:" > "nmcli-dev-gsm.log"
  nmcli dev | grep -w gsm >> "nmcli-dev-gsm.log"

  # Expect SELinux denials during a test.
  echo "SELinux denials:" > "SELinux-denials.log"
  ausearch -m avc >> "SELinux-denials.log" 2>&1

  # Get the version of installed packages needed to test ModemManager.
  echo "Info about required packages:" > "packages-info.log"
  rpm -q kernel >> "packages-info.log"
  rpm -q $REQUIRED_PACKAGES >> "packages-info.log"
  # Do not put quotes arround the variable above, otherwise won't work.
  
  echo -e "\nList of packages in YUM form" >> "packages-info.log"
  yum list installed $REQUIRED_PACKAGES >> "packages-info.log"
  # Do not put quotes arround the variable above, otherwise won't work.
  popd
}


function send_logs () {
  local LOG_SRC_DIR=${1:?"Error: Source dir for collecting logs is missing."}
  local LOG_DEST=${2:?"Error: Destination dir for collecting logs is missing."}
  local ARCHIVE_FILE="$(hostname --short).tar.gz"

  # Check for required directories. Exit if not found
  for D in "$LOG_SRC_DIR"; do
    if [ ! -d "$D" ]; then
      echo "Directory \"$D\" does not exist but it is required." >&2
      return 1
    fi
  done

  pushd "$LOG_SRC_DIR"
  tar czf "$HOME/$ARCHIVE_FILE" *.log
  if [ $? -eq 0 ]; then
    echo "Logs from \"$LOG_SRC_DIR\" archived successfully."
    popd
  else
    echo "Failed to archive logs from dir: \"$LOG_SRC_DIR\"" >&2
    popd
    return 1
  fi

  # Send logs to remote destination.  
  scp "$HOME/$ARCHIVE_FILE" "$LOG_DEST"
  if [ $? -eq 0 ]; then
    echo "Logs sent successfully to \"$LOG_DEST\""
  else
    echo "Failed to send logs to \"$LOG_DEST\""
    return 1
  fi
}


function wait_dev_until_ready () {
  # Wait for a GSM modem to connect until timeout is reached.
  TIMEOUT=30  #sec
  t=$TIMEOUT
  while [ $t -gt 0 ]; do
    nmcli -f GENERAL.STATE dev show $GSM_DEV | grep -q -wi 'connected'
    if [ $? -eq 0 ]; then
      echo "GSM device is ready."
      break
    else
      sleep 1
      let t=t-1
    fi
  done

  if [ $t -eq 0 ]; then
    echo "Timeout reached. The GSM device is not ready." >&2
    return 1
  else
    return 0
  fi
}


#--- main ---
install_prerequisites


if check_prerequisites; then
  echo "OK. Test prerequisites are satisfied."
else
  echo "Error: Test prerequisites are not satisfied." >&2
  exit 1
fi


# Begin testing.
echo "Testing with packages:"
rpm -q $REQUIRED_PACKAGES
sleep 3


# Create a new connection using GSM device. Choose the first device that support GSM from NetworkManager.
set -x
GSM_DEV=$(nmcli device | grep -w gsm --max-count=1 | awk '{print $1}')
set +x

if [ -z $GSM_DEV ]; then
  echo "Error: Cannot identify any GSM device in NetworkManager." >&2
fi

# Increase the verbosity of ModemManager.
mmcli -G DEBUG

nmcli connection add \
  con-name test-gsm-connection \
  type gsm \
  ifname $GSM_DEV \
  gsm.apn internet

# The connection goes up automatically.

wait_dev_until_ready
if [ $? -eq 0 ]; then
  echo "OK. The GSM connection has been successfully established."
else
  echo "Error: Failed to establish connection." >&2
fi


collect_logs "$HOME"
send_logs "$HOME" "$LOG_DEST"

# Clean up.
# Remove logs.
rm -f $HOME/*.log

nmcli connection del test-gsm-connection

# Decrease verbosity of ModemManager.
mmcli -G INFO


# Author: Pavlin Georgiev
# Created on: 29 Sep 2017
# Last update: 11 Apr 2019
