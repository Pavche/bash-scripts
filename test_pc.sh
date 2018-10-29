#!/usr/bin/env bash

# Prepare a remote host for automated testing.
# Copy scripts which facilitate testing.

# Check the required command-line parameters.
TEST_PC=${1:?"Error. You must provide a valid hostname of a testing computer."}


function import_ssh_keys() {
  for u in root test; do
    ssh-copy-id -o StrictHostKeyChecking=no $u@$TEST_PC
    if [ $? -eq 0 ]; then
        echo "The SSH key was successfully imported for user $u."
    else
        echo "Failed to import SSH key for user $u"
    fi
  done
}


function clear_ssh_keys() {
    # Testing machines are reused multipletimes.
    # Having the same hostname, but different finger print after each OS installation, is causing security warnings.
    # Remove the cause of security warnings when connecting to a host.
    sed -i "/eng.bos.redhat.com/d" ~/.ssh/known_hosts
    sed -i "/test/d" ~/.ssh/known_hosts
    sed -i "/gsm-r[0-9]s[0-9]*.*/d" ~/.ssh/known_hosts
}


function copy_test_scripts() {
  # Copy the scripts for automated testing to root and user test
  # Use quotes after ssh user@host_name.
  # Avoid timeouts or add subcommand after ssh: < /dev/null
  for u in root test; do
    ssh -o StrictHostKeyChecking=no $u@$TEST_PC "mkdir bin" < /dev/null
    scp ~/Work/bash-prep/*testing*.sh \
    ~/Work/bash-prep/ask-linux.sh \
    ~/Work/bash-prep/get-CA*.sh \
    ~/Work/bash-prep/install-automation.sh \
    ~/Work/bash-prep/rotest.sh \
    ~/Work/bash-prep/cyclo_test.sh \
    ~/Work/bash-prep/rhel8-deps.sh \
    $u@$TEST_PC:bin
  done
}


function update-repo() {
  # Copy the latest repository definition of RHEL.
  local TEST_MACHINE=${1:?"Error. Missing hostname ot a testing machine."}
  local REPO_FILE=${2:?"Error. Missing repository file."}

  if [ -f "$REPO_FILE" ]; then
      scp "$REPO_FILE" root@$TEST_MACHINE:/etc/yum.repos.d; RC=$?
  else
      echo -n "The repo file: $REPO_FILE\ndoes not exist." >&2
      RC=1
  fi
  return $RC
}


# Testing machines are reused multipletimes.
# Having the same hostname, but different finger print after each OS installation, is causing security warnings.
# Remove the cause of security warnings when connecting to a host.
clear_ssh_keys

# Import the SSH key from notebook to test user on the testing machine
echo "Copy the SSH key to root and then to test user on the testing machine..."
import_ssh_keys
sleep 2
echo
echo "Copy scripts for automated tests to root and user test..."
copy_test_scripts
sleep 2
echo

while [[ $ANSWER != [YyNn] ]]; do
    read -p "Would you like to add repo file from RHEL latest (Y/N)? " ANSWER
    case $ANSWER in
        [Yy])
        read -p "Full path to repo: " REPO_FILE
        update-repo "$TEST_PC" "$REPO_FILE"
        [ $? -eq 0 ] && echo "Completed." || echo "Failed to update repository." >&2
        echo
        sleep 2
        ;;
        [Nn])
        echo "Skipping repository definition."
        echo
        sleep 2
        ;;
        *)
        echo "Incorrect answer $ANSWER. Should be Y/N."
        echo
        sleep 2
        ;;
    esac
done  # while

# Set the local host name resolution for the new testing machine
echo "Give a short name to the testing machine, something easy to remember."
echo "It will be used for local host name resolution."
read -p "Nick name:" NICKNAME

if [[ ! -z "$NICKNAME" ]]; then
    echo "Nick name \"$NICKNAME\" is set."
else
    # Nick name was not set,
    echo "The default nick name \"test_pc\" is set."
    NICKNAME="test_pc"
fi
echo
echo "Writing changes into /etc/hosts ..."
IP_ADDR=$(dig +short $TEST_PC)
grep -v -w "$NICKNAME" /etc/hosts > /tmp/hosts
echo -e "$IP_ADDR\t$NICKNAME" >> /tmp/hosts
# Use a password file if available, otherwise enter it from stdin.
if [ -f ~/passwd.txt ]; then
    sudo -S mv /tmp/hosts /etc/hosts < ~/passwd.txt
else
    sudo mv /tmp/hosts /etc/hosts
fi

if [[ $? -eq 0 ]]; then
    echo "Success"
else
    echo "Failure"
fi


# Remove a previous record from another testing machine
# to avoid security messages.
echo "Deleting the hostname or IP address from list of know hosts."
echo "Thus, avoiding security messages \"Man-in-the-middle attack\""
KNOWN_HOSTS=$HOME/.ssh/known_hosts
if [[ -e $KNOWN_HOSTS ]]; then
    mv $KNOWN_HOSTS /tmp
    grep -v "$IP_ADDR" /tmp/known_hosts | grep -v "$TEST_PC" | grep -v "test_pc" > $KNOWN_HOSTS
fi

# Prepare a place for storing screenshots on my notebook from remote testing machines.
if [ ! -d $HOME/Pictures/Screenshots ]; then
    mkdir -p $HOME/Pictures/Screenshots || echo "Cannot create directory $HOME/Pictures/Screenshots."
fi

# Author: Pavlin Georgiev
# Last update: 16 Oct 2018
