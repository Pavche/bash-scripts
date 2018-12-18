#!/usr/bin/env bash

# Install NVidia drivers on x86_64
# Tested on RHEL 8.0 Beta.
arch=$(uname -p)

if [ $EUID -ne 0 ]; then
  echo "Only root can run this script." >&2
  exit 1
fi

if [ $arch != "x86_64" ]; then
  echo "This installation is for $arch only." >&2
  exit 1
fi

# Check if nouveau driver is loaded on the system.

if lsmod | grep -q nouveau; then
  echo "Run the system without graphics (run-level 3)."
  systemctl set-default multi-user

  echo "Disable nouveau driver."
  echo "blacklist nouveau" > /etc/modprobe.d/blacklist.conf

  echo "Generate new initramfs."
  mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
  dracut -v /boot/initramfs-$(uname -r).img $(uname -r)

  read -p "Press Enter to reboot. Ctrl+C to exit." key
  reboot 
else
  # Download kernel packages needed for driver compilation.
  echo "Download packages needed for driver compilation."
  yum groups install -y "Development Tools"
  yum install -y kernel-devel kernel-headers elfutils-libelf-devel

  echo "Initial conditions are prepared. You can download and install manually NVidia's driver."
fi

# Check results
# lsmod | grep nvidia

# Return to default level
# systemctl set-default graphical
# reboot
