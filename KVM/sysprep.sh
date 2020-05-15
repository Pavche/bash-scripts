#!/usr/bin/env bash

# Initialize and give new identity of a cloned VM
# by removing or chaging:
#   bash history
#   firewall rules
#   filesystem UUIDs
#   log files from the guest
#   LVM2 PV and VG UUIDs
#   HOSTNAME and DHCP_HOSTNAME in network interface configuration
#   SSH host keys in the guest
#   yum UUID
#   temporary files


# 0. Prerequirements.
if [ $EUID -ne 0 ]; then
  echo "This script can be run by root only." >&2
  exit 1
fi

# virt-manager is installed
rpm -q virt-manager

# 1. Install required software packages for the tool.
yum install -y libguestfs-tools

# 2. Select options
DOMNAME=""
echo "Choose a virtual machine from the list:"
sudo virsh list --all
while [[ -z "$DOMNAME" ]]; do
  read -p 'VM name: ' DOMNAME
done


OPTIONS="--operations "
OPTIONS_ORIGINAL=$OPTIONS

while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove the bash history in the guest?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS'bash-history'
    ;;
    [Nn])
    echo "Skipping bash history."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove the firewall rules?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',firewall-rules'
    ;;
    [Nn])
    echo "Skipping firewall rules."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Change filesystem UUIDs?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',fs-uuids'
    ;;
    [Nn])
    echo "Skipping filesystem UUIDs."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove any log files from the guest?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',logfiles'
    ;;
    [Nn])
    echo "Skipping log files."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Change LVM2 PV and VG UUIDs?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',lvm-uuids'
    ;;
    [Nn])
    echo "Skipping LVM2 PV and VG UUIDs."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove HOSTNAME and DHCP_HOSTNAME in network interface configuration?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',net-hostname'
    ;;
    [Nn])
    echo "Skipping hostname and DHCP hostname."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove the SSH host keys in the guest?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',ssh-hostkeys'
    ;;
    [Nn])
    echo "Skipping SSH host keys."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove \".ssh\" directories in the guest?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',ssh-userdir'
    ;;
    [Nn])
    echo "Skipping \".ssh\" directories."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove temporary files?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',tmp-files'
    ;;
    [Nn])
    echo "Skipping temporary files."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


while [[ $ANSWER != [YyNn] ]]; do
  read -p "Remove the yum UUID?(Y/N): " ANSWER
  case $ANSWER in
    [Yy])
    OPTIONS=$OPTIONS',yum-uuid'
    ;;
    [Nn])
    echo "Skipping yum UUID."
    sleep 1
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 1
    ;;
  esac
done
unset ANSWER


echo "Selection has been completed."
sleep 3

# Verify parameters
if [[ $OPTIONS_ORIGINAL == $OPTIONS ]]; then
  echo "Something went wrong. No options were specified for sysprep." >&2
  exit 1
fi

# 3. Run the tool with selected options
echo "Execute sysprep on $DOMNAME"
sleep 2
virt-sysprep $OPTIONS -d "$DOMNAME"
