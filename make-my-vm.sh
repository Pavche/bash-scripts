#!/usr/bin/env bash

# Make my VM


# Check if root priviledges are available
if [ $EUID -ne 0 ]; then
    echo "Error. Root priviledges are required to run this script" >&2
    exit 1
fi

# Disable firewall
systemctl stop firewalld
systemctl disable firewalld


# Disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "RHEL distribution"
unset ANSWER
read -p "RHEL7 or RHEL8? " ANSWER
case $ANSWER in
    RHEL7|rhel7)
    echo "Define repo for RHEL7"
    ;;
    RHEL8|rhel8)
    read -p "Enter distro: " DISTRO
    echo "Define repo for RHEL8"
cat << EOF > /etc/yum.repos.d/$DISTRO.repo
[$DISTRO-baseos]
name=$DISTRO \$basearch BaseOS
baseurl=http://download.devel.redhat.com/rel-eng/$DISTRO/compose/BaseOS/$(uname -p)/os/
enabled=1
gpgcheck=0

[$DISTRO-appstream]
name=$DISTRO \$basearch AppStream
baseurl=http://download.devel.redhat.com/rel-eng/$DISTRO/compose/AppStream/$(uname -p)/os/
enabled=1
gpgcheck=0
EOF
    echo "New repo defined: /etc/yum.repos.d/$DISTRO.repo"
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be RHEL7/RHEL8."
    sleep 1
    ;;
esac


# Install automation
source install-automation.sh RHEL8
RC=$? 
if [ $RC -eq 0 ]; then
    echo "Automation tools for RHEL8 installed successfully."
else
    echo "Failed to install automation tools for RHEL8." >&2
    exit 1
fi

# Install REHL 8 dependecies
source rhel8-deps.sh
RC=$? 
if [ $RC -eq 0 ]; then
    echo "Dependencies for testing gnome-control-center under RHEL8 were installed successfully."
else
    echo "Failed to install dependecies for testing gnome-control-center under RHEL8." >&2
    exit 1
fi


echo "Disable consistent netwrok device naming."
echo "It requies rebooting."
sleep 3
# Rename ens3, ens7, ens9 to eth0, eth1, ... ethN.
grubby --update-kernel=ALL --args=net.ifnames=0


while [[ $ANSWER != [YyNn] ]]; do
    echo -n "Reboot the host? (Y/N)"
    read -N 1 ANSWER
    echo
    case $ANSWER in
        [Yy])
        reboot
        ;;
        [Nn])
        echo "Skipping..."
        ;;
        *)
        echo "Incorrect answer $ANSWER. Should be Y/N."
        sleep 1
        ;;
    esac
done
unset ANSWER

# Author: Pavlin Georgiev
# Created on: 17 Oct 2018
# Last update: 17 Oct 2018


