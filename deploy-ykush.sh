#!/usr/bin/env bash

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

function satisfy_prerequisites() {
    # 1. Install dependencies
    # Find the release.
    if uname -r | grep -w -q fc28; then
        # Fedora 28
        dnf groups install -y "C Development Tools and Libraries"
    elif uname -r | grep -w -q -E "(el7|el8)"; then
        # RHEL 7
        # RHEL 8
        yum groups install -y "Development Tools"
    fi
    echo "Install development tools for compiling source code...completed"
    sleep 5

    yum install -y libusb libusb-devel libusbx libusbx-devel systemd-devel
    # Package "libusb-devel" is missing in RHEL 8.0 Alpha 1

    # Install EPEL7 under RHEL 7/8
    if uname -r | grep -w -q -E "(el7|el8)"; then
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi

    yum install -y hidapi hidapi-devel
    echo "Install libraries for applications to access USB devices...completed"
}


function compile_source() {
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
}

function check_result() {
    # 3. check if ykushcmd is available.
    if command -v ykushcmd; then
        echo "Utility \"yskushcmd\" has been successfully deployed."
        exit 0
    else
        echo "Failed to deploy utility \"yskushcmd\"." >&2
        exit 1
    fi
}


satisfy_prerequisites
sleep 5
compile_source
sleep 5
check_result

# Purpose: programmable remote control of the power of a USB device.
# Note: All command should e run as root. Otherwise results are incorrect.
# Tested under:
#   RHEL 7.4 x86_64 Workstation
#   Fedora 25 x86_64 Workstation
#   Fedora 28 x86_64 Workstation
# NOT working under:
#   RHEL 8 Alpha 1.0; reason: missing dependencies: libusb-devel. 
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
# Test
# Last update: 28 May 2018
