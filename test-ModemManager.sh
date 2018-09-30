#!/usr/bin/env bash

# Test ModemManager and usb_modeswitch on a remote system.
# The goal is to monitor the behavior of a mobile broadband modem
# attached to the system via a USB port.


# User defined functions.
function install_ModemManager () {
  echo 'Installing ModemManager, usb_modeswitch, usb_modeswitch-data...'
  sleep 2
  yum install -q -y ModemManager usb_modeswitch usb_modeswitch-data usbutils

  # Check installation.
  if rpm --quiet -q ModemManager usb_modeswitch usb_modeswitch-data; then
    # mmcli -G DEBUG
    echo "Install optional packages for NetworkManager."
    sleep 2
    yum install -y -q NetworkManager-wwan NetworkManager-ppp
    if rpm --quiet -q NetworkManager-wwan NetworkManager-ppp; then
      echo 'All needed packages were installed.'
      sleep 2
      systemctl enable ModemManager
      systemctl start ModemManager
      return 0
    else
      echo 'Error: The installation of NetworkManager-wwan NetworkManager-ppp failed.' >&2
      return 1
    fi
  else
    echo 'Error: The installation of ModemManager failed.' >&2
    return 1
  fi
}


function install_ModemManager_brew () {
  # How to install the latest version of ModemManager from Brew?
  # TODO: Update the function and make it flexible for different conditions.
  # Ask the user if the newest packages needed packages for the test should be installed.
  read -p 'Do you want to install the newest version of ModemManager?(Y/N): ' ANSWER
  case $ANSWER in
    [Yy]|[Yy][Ee][Ss])
      PREFIX='http://download.eng.bos.redhat.com/brewroot/packages'
      echo 'Installing ModemManager...'

      # TODO: Make more flexible the installation of packages from Brew server.

      yum install -q -y \
        $PREFIX/ModemManager/1.6.10/1.el7/x86_64/ModemManager-1.6.10-1.el7.x86_64.rpm \
        $PREFIX/ModemManager/1.6.10/1.el7/x86_64/ModemManager-glib-1.6.10-1.el7.x86_64.rpm \
        $PREFIX/usb_modeswitch/2.5.1/1.el7/x86_64/usb_modeswitch-2.5.1-1.el7.x86_64.rpm \
        $PREFIX/usb_modeswitch-data/20170806/1.el7/noarch/usb_modeswitch-data-20170806-1.el7.noarch.rpm
      if [ $? -eq 0 ]; then
        systemctl enable ModemManager
        mmcli -G DEBUG
        echo 'Done. Now, please, reboot the host.'
        exit 0
      else
        echo 'Error: The installation of ModemManager has failed' >&2
        exit 1
      fi
    ;;
    [Nn]|[Nn][On])
      echo 'Skipping newest packages...'
      sleep 2
    ;;
    *)
      echo 'Incorrect answer $ANSWER. Should Yes/No.' >&2
      sleep 2
      exit 1
    ;;
  esac
}


function collect_logs () {
  # Gather logs from NetworkManager, ModemManager, and the system log.
  local DEST_DIR=${1:?"Error: Destination dir for collecting the logs is required."}
  local LOG_DIR=${2:-"$HOME/$(hostname --short)"}
  local LOG_COLLECTOR=${3:-"pgeorgie@delphinius.usersys.redhat.com:Downloads"}

  # Validate parameters.
  if [ ! -d "$DEST_DIR" ]; then
    printf "Directory %s does not exist.\n" "$DEST_DIR" >&2
    exit 1
  fi
  # Needed services are running.
  systemctl --quiet is-active NetworkManager
  if [ $? -ne 0 ]; then
    echo "NetworkManager is not runnig." >&2
  fi
  systemctl --quiet is-active ModemManager
  if [ $? -ne 0 ]; then
    echo "ModemManager is not running" >&2
  fi
  # Avoid directory duplication.
  if [ "$LOG_DIR" == "$DEST_DIR" ]; then
    printf "Log directory: %s\ncannot be the same as\ndestination directory: %s\n" "$LOG_DIR" "$DEST_DIR" >&2
    return 1
  fi
  [ -d "$LOG_DIR" ] || mkdir -p "$LOG_DIR"
  # Simplified log output for NetworkManager and ModemManager.
  journalctl -b 0 > "$LOG_DIR/journalctl_$(hostname --short).log"
  journalctl -b 0 -u NetworkManager -o cat > "$LOG_DIR/NetworkManager.log"
  journalctl -b 0 -u ModemManager -o cat > "$LOG_DIR/ModemManager.log"
  cp -f /var/log/messages "$LOG_DIR/system.log"
  lsusb > "$LOG_DIR/lsusb.log"
  usb-devices > "$LOG_DIR/usb-devices.log"
  mmcli -m 0 > "$LOG_DIR/mmcli.log"
  nmcli dev | grep -w gsm > "$LOG_DIR/nmcli-dev-gsm.log"
  rpm -q NetworkManager ModemManager usb_modeswitch usb_modeswitch-data > "$LOG_DIR/packages-info.txt"

  cd "$LOG_DIR"
  tar czf "$DEST_DIR/$(hostname --short).tar.gz" * \
  && scp "$DEST_DIR/$(hostname --short).tar.gz" "$LOG_COLLECTOR"
  return $?
  # The return code depends on creating and sending a TAR archive with the logs to admin's PC.
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


# Is any version on ModemManager installed? If no, install one and ask the user to reboot the remote host.
# Not via "reboot" command, thus, keeping the connection between the host and Beaker.
rpm --quiet -q ModemManager
if [ $? -ne 0 ]; then
  install_ModemManager || exit 1
fi

# Begin testing.
printf "Testing with:\n%s\n%s\n%s\n" $(rpm -q ModemManager) $(rpm -q usb_modeswitch) $(rpm -q usb_modeswitch-data)
sleep 3

# Increase the verbosity of ModemManager and NetworkManager Manager.
function set_verbosity() {
    ENABLED=${1:?'Missing verbosity. Should be "Yes/No", "True/False", "0/1"'}
    case $ENABLED in
        [Yy]|[Yy][Ee][Ss]|1|[Tt]rue)
        mmcli -G DEBUG
        sudo nmcli general logging level debug domains all
        echo "Verbosity is enabled in ModemManager and NetworkManager."
        sleep 2
        ;;
        [Nn]|[Nn][On]|0|[Ff]alse)
        mmcli -G INFO
        sudo nmcli general logging level info domains all
        echo "Verbosity is disabled in ModemManager and NetworkManager."
        sleep 2
        ;;
        *)
        echo "Invalid choise for verbosity"
        return 1
    esac
    # The verbosity is set. OK.
    return 0
}

# Create a new connection using GSM device. Choose the first device that support GSM from NetworkManager.
set -x
GSM_DEV=$(nmcli device | grep -w gsm --max-count=1 | awk '{print $1}')
set +x
if [ -z $GSM_DEV ]; then
  echo "Cannot identify the GSM device in NetworkManager." >&2
  # Where to collect the logs, from where to take data, where to send the logs.
  collect_logs "/tmp" "$HOME/$(hostname --short)" "pgeorgie@delphinius.usersys.redhat.com:/home/pgeorgie/Work/GSM/Connection_status/RHEL-7.5"
  # local LOG_COLLECTOR=''
  exit 1
fi

# Increase the verbosity of ModemManager and NetworkManager Manager.
set_verbosity true

nmcli connection add \
  con-name test-gsm-connection \
  type gsm \
  ifname $GSM_DEV \
  gsm.apn internet.t-mobile.cz

# The connection does automatilly up.

wait_dev_until_ready
if [ $? -eq 0 ]; then
  echo "The GSM connection has been successfully established."
  # Clean up.
  nmcli connection del test-gsm-connection
  set_verbosity false
  exit 0
else
  # Failed to establish connection. Send logs for analysis.
  collect_logs "/tmp" "$HOME/$(hostname --short)" "pgeorgie@delphinius.usersys.redhat.com:/home/pgeorgie/Work/GSM/Connection_status/RHEL-7.5"
  # Clean up.
  nmcli connection del test-gsm-connection
  set_verbosity false
  exit 1
fi

# Author: Pavlin Georgiev
# Created on: 29 Sep 2017
# Last update: 15 June 2018
