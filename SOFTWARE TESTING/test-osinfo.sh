#!/usr/bin/env bash

function osdetect() {
  local ISO=${1:?"Error: ISO file is missing."}
  local INSTALL_TREE=${2:?"Error: Installation tree is missing."}
  echo -e "\nChecking ISO file: $ISO"
  osinfo-detect -f plain -t media $ISO
  echo "Checking install tree: $INSTALL_TREE"
  osinfo-detect -f plain -t tree $INSTALL_TREE
}

# Analyse the latest released RHEL7
# Analyse distro RHEL-7.7
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.7/Workstation/x86_64/iso/RHEL-7.7-20190723.1-Workstation-x86_64-dvd1.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.7/Workstation/x86_64/os/"
osdetect $ISO $INSTALL_TREE


# Analyse the latest released Fedora.
# Analyse distro Fedora 30 Workstation
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/fedora/F-30/GOLD/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-30-1.2.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/fedora/F-30/GOLD/Workstation/x86_64/os/"
osdetect $ISO $INSTALL_TREE


# Analyse previous releases.
# Analyse distro RHEL 7.6
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.6/Workstation/x86_64/iso/RHEL-7.6-20181010.0-Workstation-x86_64-dvd1.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.6/Workstation/x86_64/os/"
osdetect $ISO $INSTALL_TREE


# Analyse distro CentOS7
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/CentOS/7/isos/x86_64/CentOS-7-x86_64-DVD-1503-01.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/CentOS/7/os/x86_64/"
osdetect $ISO $INSTALL_TREE


# Analyse distro RHEL 6.9
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/RHEL-6/6.9/Workstation/i386/iso/RHEL-6.9-20170309.0-Workstation-i386-dvd1.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/RHEL-6/6.9/Workstation/i386/os/"
osdetect $ISO $INSTALL_TREE

