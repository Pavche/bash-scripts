#!/usr/bin/env bash
#
# Prepare the Linux environment for software testing.
# Go to the directory where the automated tests are located.
# Make it possible to see graphics applications in the graphics environment
# of a remote machine via VNC.
# Check for wireless adaptes needed for some tests.
# The script should be run on the TESTING MACHINE as user "test".
# 1st command line parameter should be an existing software package in Linux.

# TODO: Does the system have repository from where to take RPM packages?
# Without repo, this script is semi-functional.
# How to check? Try to 'yum list' a well know package that must exist but it's not installed by default.
# The result will show the availability or lack of repo.

# Validation of command-line arguments
COMPONENT=${1:?"Error. Component's name is missing."}

# Variable definition
TEST_DIR="/mnt/tests"
B_PROFILE="$HOME/.bash_profile"
B_RC="$HOME/.bashrc"

function isOK () {
  if [ $? -eq 0 ]; then
    echo "Completed."
  else
    echo "Failed."
  fi
}


function set_user_preferences () {
    # Define how some useful tools will work during software testing and Linux administraion.
    # VIM editor: Remove smart indentation which allows you to
    # easily copy & paste source code. Overwrite existing config.
    (
    cat << EOF
set nosmartindent
EOF
    ) >  ~/.vimrc
}


function set_debug_log () {
  # Create an empty debug log for given GUI component under test.
  local DEBUG_LOG=${1:?"Error, please provide full path to debug log."}
  local DEBUG_FILE=$(basename "$DEBUG_LOG")
  local DEBUG_DIR=$(dirname "$DEBUG_LOG")
  # Examle: "$HOME/$COMPONENT/debug.log"
  # Remove previous log.
  [ -d "$DEBUG_DIR" ] || mkdir -p "$DEBUG_DIR"
  [ -f "$DEBUG_LOG" ] || touch "$DEBUG_LOG"
  # Is the operation successful? Can a program write to that log?
  [ -w "$DEBUG_LOG" ] && return 0 || return 1
}


function extend_bash_profile () {
  # Define variables that describe:
  # software component under test
  # the FQDN of my notebook so that it can be accessed from any testing machine
  # the location on my notebook where to store various files from the testing machine
  # the location on my notebook where is the source code for automated tests
  # the location of automated tests on the testing machine
  echo "Extend bash profile with new functionalities:"
  # Do not insert leading spaces in the code segment below
  cat << EOF >> $B_PROFILE
# Component name in Linux for testing
export COMPONENT=$COMPONENT

export NOTEBOOK='user@server-example.com'

# Locations for sending logs, screenshots, and other files
export RAMP="\$NOTEBOOK:Downloads"

# Location of the source code of automated tests
export SRC_CODE="\$NOTEBOOK:Work/\$COMPONENT"

# Location of automated tests
export TEST_DIR="$TEST_DIR/\$COMPONENT"

# Debug logs
export DEBUG_LOG=\$HOME/"\$COMPONENT"_debug.log

export TERM=xterm-256color

cd "\$TEST_DIR"
EOF

  cat "$B_PROFILE"
  sleep 5

  # Needed for root user only.
  if [ $EUID -eq 0 ] && [ ! "$COMPONENT" == "ModemManager" ] && [ ! "$COMPONENT" == "gnome-initial-setup" ]; then
    cat << EOF >> $B_PROFILE
# Start testing of Linux GUI.
echo
echo "Enable automatic start of dogtail in 10 sec..."
echo "Press Ctrl+C to interrupt."
sleep 10
sudo -u test dogtail-run-headless-next bash
EOF
  fi
}


function extend_bashrc () {
    # Add new commands for tacking the behavor of netork interfaces, connections, and routes.
    echo "Extend bash profile with new functionalities:"
    # Do not leave leading spaces in the code segment below
    cat << EOF >> $B_RC

# For Python2
alias behave-no-capture='behave --no-capture --no-capture-stderr --no-logcapture'

# For Python3
# alias behave-no-capture='behave-3 --no-capture --no-capture-stderr --no-logcapture'

# Track the state of network links, connections, and IPv4/IPv6 addresses
alias watchdev='watch -d nmcli dev status'
alias watchlink='watch -d ip -0 a s'
alias watchcon='watch -d nmcli connection'
alias watchcona='watch -d nmcli connection show --active'
alias watchip4='watch -d ip -4 a s'
alias watchip6='watch -d ip -6 a s'
alias watchr4='watch -d ip -4 route show'
alias watchr6='watch -d ip -6 route show'

# Last screenshot and video record
alias last-screenshot='ls -Art ~/Pictures/*.png | tail -n 1'
alias last-video='ls -Art ~/Videos/*.webm | tail -n 1'
EOF
}


function install_automation_tools() {
  local TOOL_LIST='vim-enhanced mc dconf-editor sysstat dnf-utils tigervnc-server'
  local PYTHON_MODULES='ipython ipdb'

  # sysstat : Collection of performance monitoring tools
  echo "Install automation tools:"
  i=1
  for tool in $TOOL_LIST; do
    echo "$i. $tool"
    i=$((i+1))
  done
  sleep 2
  yum install -y -q $TOOL_LIST
  isOK
  sleep 2
  
  echo "Update pip for Python2"
  sleep 2
  pip2 install --upgrade pip
  sleep 2

  printf "Install Python2 modules: %s\n" "$PYTHON_MODULES"
  sleep 2
  pip3 install $PYTHON_MODULES
  isOK
  sleep 2

  echo "Update pip for Python3"
  sleep 2
  pip3 install --upgrade pip
  sleep 2

  printf "Install Python3 modules: %s\n" "$PYTHON_MODULES"
  sleep 2
  pip3 install $PYTHON_MODULES
  isOK
  sleep 2

  echo "Install bug reporing tool..."
  sleep 2
  yum install -y -q libreport-rhel-bugzilla
  echo "Completed."
  sleep 2
}


function download_project() {
    local PROJECT=${1:?"Error. Provide project name."}
    local URL=${2:?"Error. Provide URL of a Git repository."}
    # Clone a project from Git repo into the current directory.
    if ! rpm --quiet -q git; then
        echo 'Cannot clone any Git repo. Install prerequisite "git".' >&2
        return 1
    fi

    pushd "$TEST_DIR"  # /mnt/tests
    git clone "$URL"; RC=$?
    [ $RC -eq 0 ] || return $RC
    
    if [ $PROJECT == $COMPONENT ]; then
        pushd "$COMPONENT"
        git submodule update --init --recursive; RC=$?
        if [ $RC -ne 0 ]; then
            echo 'Failed to initialize submodules.' >&2
            popd  # $COMPONENT
            popd  # /mnt/tests
            return $RC
        fi
        popd
    fi
    popd  # /mnt/tests
}


# Is the script is run as root?
if [ $EUID -eq 0 ]; then
    # Generate a SSH key and copy it to my notebook
    # in order to copy files without asking for password,
    # only if it is not already generated.
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
      ssh-keygen -t RSA -b 2048
      if [ $? -ne 0 ]; then
          echo "Could not generate a SSH key for the root."
          exit 2
      else
          echo "Copy the SSH key of user test to provide passwordless file transfer."
          ssh-copy-id -o StrictHostKeyChecking=no user@server-example.com
      fi
    fi

    groupadd --gid 10001 testers
    usermod -aG testers test

    # Go to the directory where the tests are located.
    if [[ -d "$TEST_DIR" ]]; then
        # Assign file ownership to user test
        chown -R test:testers "$TEST_DIR"
    else
        echo "The directory $TEST_DIR does not exist."
        exit 4
    fi

    extend_bash_profile
    extend_bashrc
    install_automation_tools
    sleep 2
    
    # Prepare specific conditions for remote connection via VNC under RHEL 8.0
    # on a physical host.
    if ! (dmidecode -s system-manufacturer | grep -q 'Red Hat'); then
      echo 'Use DUMMY video driver for Xorg.'
      cp -fp /mnt/tests/desktop/rhel8/install/xorg.conf /etc/X11
      echo 'Remove already existing LibVNC conf file which is suitable for VM.'
      rm -f /etc/X11/xorg.conf.d/10-realhwlibvnc.conf
      echo 'Copy Xorg conf file which contains dummy video driver.'
      cp -fp /mnt/tests/desktop/rhel8/install/10-dummylibvnc.conf /etc/X11/xorg.conf.d
    fi
    
    set_user_preferences
fi  # when logged as root


# Is the sript run as normal user, for example "test"?
if [ $EUID -eq 1000 ]; then
    # Generate a SSH key and copy it to my notebook
    # in order to copy files without asking for password,
    # only if it is not already generated.
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        ssh-keygen -t rsa; RC=$?
        if [ $RC -ne 0 ]; then
            echo "Could not generate a SSH key for user test."
            exit 8
        else
            echo "Copy the SSH key of user test to provide passwordless file transfer."
            ssh-copy-id -o StrictHostKeyChecking=no user@server-example.com
        fi

    fi

    # Log file is needed only for the user "test" under which automated test are run.
    set_debug_log "$HOME/$COMPONENT/debug.log"

    extend_bash_profile

    extend_bashrc

    # Modify GNOME settings outside of GUI.
    # Enable accessibility technology A11Y in GNOME3.
    dbus-launch gsettings set org.gnome.desktop.interface toolkit-accessibility true
    # Disable power saving
    dbus-launch gsettings set org.gnome.desktop.session idle-delay 0

    set_user_preferences
fi  # when logged as normal user

# Author: Pavlin Georgiev
# Created on: 7/13/2016
# Last update: 1/18/2019
