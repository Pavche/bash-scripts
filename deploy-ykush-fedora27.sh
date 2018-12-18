#!/usr/bin/env bash
# TODO: TEST UNDER FEDORA 27.

# When a device is connected to a USB port for a long period
# it may become unstable or fall into a non-working state.
# For example: a storage device, a GSM modem, a device for measuring temperature or pressure.
# One good solution is Yepkit YKUSH XS.
# See: https://www.yepkit.com/product/300115/YKUSHXS

# Device identification
# USB ID 04d8:f0cd Microchip Technology, Inc.
# Product: YKUSH XS
# Manufacturer: Yepkit Lda.
# idVendor=04d8, idProduct=f0cd

# The script was created
if [ $EUID -ne 0 ]; then
  echo "This script can be run by root only." >&2
  exit 1
fi

# 1. Install dependencies
dnf groupinstall -y "Development Tools"
echo "Install development tools for compiling source code...completed"
sleep 5

dnf install -y libusb libusb-devel libusbx libusbx-devel systemd-devel
dnf install -y hidapi hidapi-devel
echo "Install libraries for applications to access USB devices...completed"
sleep 5

# 2. Get the source, compile, and install the driver
[ -d ~/Install ] || mkdir ~/Install
cd ~/Install
[ -d ykush ] && rm -fr ykush
git clone https://github.com/Yepkit/ykush.git
sleep 5

cd ykush
./build.sh
./install.sh
echo "Install the driver for device Yepkit YKUSH XS...completed"
sleep 5

# Purpose: programmable remote control of the power of a USB device.
# Note: All command should e run as root. Otherwise results are incorrect.
# Tested under Fedora 25 x86_64 Workstation.
#
# Usage
# List available YKUSH XS devices:
# ykushcmd ykushxs -l
#
# Get the status of the downstream port:
# ykushcmd ykushxs -g
#
# Disconnect the downstream port:
# ykushcmd ykushxs -d
#
# Connect the downstream port:
# ykushcmd ykushxs -u
#
# Last update: 11.11.2017
