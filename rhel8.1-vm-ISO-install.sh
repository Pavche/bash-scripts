#!/usr/bin/env bash

# Download an ISO file to a dir
URL="http://download.eng.rdu2.redhat.com/rel-eng/latest-RHEL-8.1/compose/BaseOS/x86_64/"
REPO_URL=$URL"os/"
REPO2_URL=${URL/BaseOS/AppStream}"os/"

# Local installation sources
ISO_DIR="/home/pgeorgie/VM/ISO"

function get_iso_image() {
  local ISO_URL=${1:?"Error: URL to ISO file is missing."}
  local REGEX="RHEL-[0-9]\.[0-9]\..+dvd.+\.iso"
  
  # How to read the name of a ISO file witch changes each time?
  ISO_FILE=$(curl $ISO_URL | grep -o -E '".+"' | grep -o -E "$REGEX" | uniq)
  # Check for validity
  if [ -z "$ISO_FILE" ]; then
    echo "ISO file cannot be determined." >&2
    return 1
  fi
  # How to read available RHEL8 ISO images?
  # Sources
  # 1) Nightly
  # 2) Rel-eng
  # 3) Released
  # Example
  # ISO_URL='http://download.devel.redhat.com/released/RHEL-8/8.0.0/BaseOS/x86_64/iso/'
  
  # Check if the file is already downloaded.
  if [ -f "$ISO_DIR/$ISO_FILE" ]; then
    echo -e "ISO file already downloaded:\n$ISO_DIR/$ISO_FILE\nSkip download.\n"
  else
    wget -O "$ISO_DIR/$ISO_FILE" "$ISO_URL/$ISO_FILE"
    [ $? -eq 0 ] || return 1
  fi
  export ISO_FILE
}


# === MAIN ===
echo "ISO: $ISO_URL"
echo
echo "BaseOS Repo: $REPO_URL"
echo "AppStream Repo: $REPO2_URL"
echo
echo "ISO_DIR: $ISO_DIR"

get_iso_image $URL"iso/" || exit 1

# I expect that variable ISO_FILE is exported in advance.

# Extract date from the name of ISO file to use
# in the name in the newly created VM.
# Example
# RHEL-8.1.0-20190701.0-x86_64-dvd1.iso
# to become RHEL-8.1.0-20190701.0.
REGEX="RHEL-[0-9]\.[0-9]\..+-[0-9]{8}(\.[0-9])?(\.n\.[0-9])?"

# Regex captures names:
# 1) Released: RHEL-8.0.0-20190404.2-x86_64-dvd1.iso 
# 2) Rel-eng:  RHEL-8.1.0-20190701.0-x86_64-dvd1.iso
# 3) Nightly:  RHEL-8.1.0-20190702.n.0-x86_64-dvd1.iso

VM_NAME=$(echo $ISO_FILE | grep -o -E "$REGEX")
echo
echo "Creating VM named: $VM_NAME"

# Start install + kickstart
virt-install \
--name "$VM_NAME" \
--os-variant rhel8.0 \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--cdrom $ISO_DIR/$ISO_FILE \
--initrd-inject /home/pgeorgie/VM/kickstart/rhel8.1/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
