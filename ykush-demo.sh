#!/usr/bin/bash

# Demostrate the abilities of Yepkit YKUSH XS.
# YKUSH XS is connected between the USB port of a host and a external USB device.
# This is a device for controling the power of a USB storage device, GSM modem,
# or another type of device connected to a USB port of a server/PC/laptop.
# It allows programmable remote control over the power of a USB device.

# In order to YKUSH commands to be executed properly, root or sudoer can run the script.
if [ $EUID -ne 0 ]; then
  echo "This script can be run by root only." >&2
fi

CONNECTION='test-gsm-connection'
GSM_MODEM_LIST=( '12d1:1465' '19d2:0117' '05c6:6000' '1199:68a2' '1199:9071')
# 12d1:1465 Huawei Technologies Co., Ltd. K3765 HSPA
# 19d2:0117 ZTE WCDMA Technologies MSM
# 05c6:6000 Qualcomm, Inc. Siemens SG75
# 1199:68a2 Sierra Wireless MC7710
# 1199:9071 Sierra Wireless MC7455


function clean_up() {
  nmcli connection delete "$CONNECTION"
  # Leave the YKUSH XS in enabled state.
  ykushcmd ykushxs -u
}

function wait_usb_dev() {
  # Wait for a USB device to appear in the list of lsusb.
  local IS_FOUND=0
  local DEVICE_ID=${1:?"Error. USB ID is missing."}
  local TIMEOUT=${2:-'30'}  # seconds
  for t in $(seq 1 $TIMEOUT); do
    if lsusb | grep -q -w "$DEVICE_ID"; then
      echo $(lsusb | grep -q -w "$DEVICE_ID")
      IS_FOUND=1
      break
    else
      sleep 1
    fi
  done
  if [ $IS_FOUND -eq 1 ]; then
    echo "Device ID $DEVICE_ID was detected."
    return 0
  else
    echo "Device ID $DEVICE_ID was NOT detected in $TIMEOUT sec." >&2
    return 1
  fi
}

function search_gsm_modem() {
  # Having a list on known GSM modems, find the modem connected to a USB port.
  # Print the modem detected.
  local TIMEOUT=${1:-'60'}
  local MODEM_FOUND=''
  # 12d1:1465 Huawei Technologies Co., Ltd. K3765 HSPA
  # 19d2:0117 ZTE WCDMA Technologies MSM
  # 05c6:6000 Qualcomm, Inc. Siemens SG75
  IS_FOUND=0
  for t in $(seq 1 $TIMEOUT); do
  # Search for known device ID of a GSM modem.
    for modem_id in "${GSM_MODEM_LIST[@]}"; do
      if lsusb | grep -q -w "$modem_id"; then
        IS_FOUND=1
        MODEM_FOUND=$(lsusb | grep -m1 -w "$modem_id")
      fi
    done  # GSM_MODEM_LIST
    if [ $IS_FOUND -eq 1 ]; then
      break
    else
      sleep 1
    fi
  done  # TIMEOUT

  if [ $IS_FOUND -eq 1 ]; then
    # Display the name of the modem by searching by device ID.
    printf "A GSM modem was detected:\n%s\n" "$MODEM_FOUND"
    return 0
  else
    printf "None of known GSM modems detected in %s\n sec." "$TIMEOUT" >&2
    return 1
  fi
}

function wait_gsm_dev() {
  # Wait for a device to appear in the list of NetworkManager
  # as a gsm type of device.
  local IS_FOUND=0
  local DEVICE_NAME=${1:?"Error. Missing device name"}
  local TIMEOUT=${2:-"60"}
  for t in $(seq 1 $TIMEOUT); do
    if nmcli dev | grep -q -w "$DEVICE_NAME"; then
      IS_FOUND=1
      break
    else
      sleep 1
    fi
  done

  if [ $IS_FOUND -eq 1 ]; then
    echo "The device $DEVICE_NAME was detected as GSM by NetworkManager."
    return 0
  else
    echo "The device $DEVICE_NAME was NOT detected as GSM by NetworkManager in $TIMEOUT sec." >&2
    return 1
  fi

}

function wait_gsm_connection() {
  local IS_FOUND=0
  local CONNECTION=${1:?"Error. Connection name is missing."}
  local TIMEOUT=${2:-"60"}
  for t in $(seq 1 $TIMEOUT); do
    # Wait for the device
    if nmcli con show --active | grep -q -w "$CONNECTION"; then
      IS_FOUND=1
      break
    else
      sleep 1
    fi
  done

  if [ $IS_FOUND -eq 1 ]; then
    echo "GSM connection $CONNECTION is active."
    return 0
  else
    echo "GSM connection $CONNECTION was NOT activated for $TIMEOUT sec." >&2
    return 1
  fi
}

function get_ppp_interface() {
  # I suppose that a GSM modem will offer me PPP interface.
  # I assume that a single GSM modem is connected to the system.
  local IS_FOUND=0
  local TIMEOUT=${1:-"30"}
  for t in $(seq 1 $TIMEOUT); do
    # Wait for the device

    if ip link | grep -q -m1 -w ppp[0-9]*; then
      # Get the name of the serial communivation device of the modem.
      PPP_INTERFACE=$(ip link | grep -m1 -w ppp[0-9]* | awk -F: '{gsub(" |\t",""); print $2}')
      IS_FOUND=1
      break
    else
      sleep 1
    fi
  done

  if [ $IS_FOUND -eq 1 ]; then
    echo "PPP interface "$PPP_INTERFACE" was found."
    return 0
  else
    echo "PPP interface was NOT found." >&2
    return 1
  fi
}

clean_up

if [ $EUID -ne 0 ]; then
  echo "This script can be run by root only." >&2
fi

clear
echo "Connect the device Yepkit YKUSH XS to a USB port"
DEVICE_ID='04d8:f0cd'
wait_usb_dev "$DEVICE_ID"
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi
sleep 3

echo "Display device information"
ykushcmd ykushxs -l
sleep 5
echo "Display port status"
ykushcmd ykushxs -g
sleep 5

echo
echo "Connect a GSM modem to a USB port of the system."
search_gsm_modem
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi

# Various GSM modems receive different ttyUSB.
DEVICE_NAME='ttyUSB[0-9]*'
# Wait for a device to appear in the list of NetworkManager as a gsm type of device.
wait_gsm_dev "$DEVICE_NAME" 60
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi
sleep 3

echo "Get the status of GSM modems before disconnecting the power via USB port"
nmcli -f DEVICE,TYPE,STATE dev | grep -w gsm
sleep 5

ykushcmd ykushxs -d
echo "The power via USB was disconnected."
sleep 5
echo
echo "Status of GSM modems after disconnecting the power:"
nmcli -f DEVICE,TYPE,STATE dev | grep -w gsm
echo
sleep 5

echo "Turn on the power of the USB port..."
ykushcmd ykushxs -u

# Wait for a GSM modem to become available.
search_gsm_modem
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi

wait_gsm_dev "$DEVICE_NAME" 60  # seconds
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi
sleep 3

echo "Creating a new GSM connection with NetworkManager..."
# We suppose that a GSM modem is available as ttyUSB in NetworkManager.
# Several modems can be connected to USB ports of a system.
# Only one modem can be chosen at a time.
GSM_DEV='ttyUSB[0-9]*'
SELECTED_DEV=$(nmcli -f DEVICE,TYPE --terse dev | grep -w gsm | grep -m1 -w "$GSM_DEV" | awk -F: '{print $1}')
GSM_APN='internet.t-mobile.cz'
PIN='6045'
nmcli connection add \
  con-name test-gsm-connection \
  type gsm \
  ifname  $SELECTED_DEV\
  gsm.apn "$GSM_APN" \
  gsm.pin $PIN
sleep 5
echo
echo "Status of GSM modems after restoring the power via USB port:"
nmcli -f DEVICE,TYPE,STATE dev | grep -w gsm
sleep 5
echo
echo "Wait for the GSM connection to become active..."
wait_gsm_connection "test-gsm-connection" 60
if [ $? -ne 0 ]; then
  clean_up
  exit 1
fi
sleep 3
# TODO: Test network connection via the new modem interface.
# Keep in mind, not all modems provide PPP interface by default.
# echo
# echo "Test the GSM connection via ping to a remote server"
# PPP_INTERFACE=""
# get_ppp_interface
# # The variable PPP_INTERFACE is set on success from the function above.
# if [ $? -ne 0 ]; then
#   clean_up
#   exit 1
# fi
# sleep 5
# ping -I $PPP_INTERFACE -c 10 email.seznam.cz
# sleep 3

echo
echo "Now, disconnect the GSM modem."
echo "Leave YKUSH XS connected."
read key

clean_up

echo "You can disconnect YKUSH XS."

# Author: Pavlin Georgiev
# Created on: 11 Nov 2017
# Last update: 28 May 2018
