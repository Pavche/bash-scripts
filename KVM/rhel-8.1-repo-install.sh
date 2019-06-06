#!/usr/bin/env bash

# Create a KVM based VM on your laptops / PC.
# Define server for downloading the OS.
# Specify distro name.
# Generate a kickstart file from a temple.
# Add repositories to the kickstart.
# Install RHEL8 on VM.


# DISTRO_NAME=${1:?"Error: distrition name is missing. Example: RHEL-8.0-Snapshot-1.0, RHEL-8.1.0-InternalSnapshot-2.1."}
SERVER='download-ipv4.eng.brq.redhat.com'
DISTRO_NAME='RHEL-8.1.0-InternalSnapshot-2.1'

# Choose localtion from Release Engineering
# Example
# RHEL-8.0-Snapshot-1.0
# RHEL-8.1.0-InternalSnapshot-2.1

function generate_kickstart () {
  # Get a template for kickstart.
  # Modify it by adding repositories.
  # This function  works for release engineering.
  [ -z "$DISTRO_NAME" ] && return 1
  [ -z "$SERVER" ] && return 1
  local WORK_DIR='/home/pgeorgie/VM/kickstart-templates'
  
  [ -d "$WORK_DIR" ] || return 1
  pushd "$WORK_DIR"
  # Make adjustments. Replace distrition name. Define repositories.
  # Replace markers in the files with values.
  cat ks-rhel8.1-workstation-gnome.cfg | \
  sed "s/SERVER/$SERVER/g" | \
  sed "s/DISTRO_NAME/$DISTRO_NAME/g" > /tmp/ks.cfg
  popd
}

if generate_kickstart "$DISTRO_NAME"; then
  echo "Kickstart generated successfully."
else
  echo "Error when generating kickstart file." >&2
  exit 1
fi

virt-install \
--name "$DISTRO_NAME" \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--os-variant rhel8.0 \
--location http://$SERVER/rel-eng/$DISTRO_NAME/compose/BaseOS/x86_64/os/ \
--initrd-inject /tmp/ks.cfg \
--extra-args="ks=file:/ks.cfg console=tty0 console=ttyS0,115200n8"

# repo --name=repoid [--baseurl=<url>|--mirrorlist=url] [options]

# Author: Pavlin Georgiev
# Last modification: 6 June 2019
