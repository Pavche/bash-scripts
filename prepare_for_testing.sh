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
TEST_DIR="/mnt/tests/$COMPONENT"
B_PROFILE="$HOME/.bash_profile"
B_RC="$HOME/.bashrc"

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
    # EPEL7 repo
    # the location of automated tests on the testing machine
    echo "Extend bash profile with new functionalities:"
    (
# Do not insert leading spaces in the code segment below
cat << EOF
# Export the path to tests so other scripts can use it.
export DRIVER_USB_NET="/lib/modules/$(uname -r)/kernel/drivers/net/usb"

# Component name in Linux for testing
export COMPONENT=$COMPONENT

export NOTEBOOK='pgeorgie@delphinius.usersys.redhat.com'

# Locations for sending logs, screenshots, and other files
export RAMP="\$NOTEBOOK:Downloads"

# Location of the source code of automated tests
export SRC_CODE="\$NOTEBOOK:Work/\$COMPONENT"

# EPEL7 Repository
export EPEL7='https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

# Location of automated tests
export TEST_DIR="/mnt/tests/\$COMPONENT"

# Debug logs
export DEBUG_LOG=\$HOME/"\$COMPONENT"_debug.log

export TERM=xterm-256color

cd "\$TEST_DIR"

EOF
    ) >> $B_PROFILE

cat "$B_PROFILE"
sleep 5

# Needed for root user only.
if [ $EUID -eq 0 ]; then
    (
    cat << EOF

# Enable big terminal fonts when GUI is unavailable. Makes it easier to work.
setfont /usr/lib/kbd/consolefonts/ter-u22b.psf.gz

# terminate session for user test.
# Stop GNOME display manager.
# pkill -u test
# sleep 3
# systemctl stop gdm

# Start testing of Linux GUI.
echo
echo "Enable automatic start of dogtail in 10 sec..."
echo "Press Ctrl+C to interrupt."
sleep 10
sudo -u test dogtail-run-headless-next bash
EOF
    ) >> $B_PROFILE
fi
}


function extend_bashrc () {
    # Add new commands for tacking the behavor of netork interfaces, connections, and routes.
    echo "Extend bash profile with new functionalities:"
    (
# Do not leave leading spaces in the code segment below
cat << EOF

function find_modem () {
    # Use ModemManager's CLI to find modems.
    # Look for known modem drivers loaded into the system.
    rpm --quiet -q ModemManager  &&  mmcli -L
    echo
    echo "Searching for modem drivers..."
    lsmod | grep -E "sierra|qmi|qc|wwan|cdc|dcd_ncm|visor|option|Gobi" | cut -d" " -f1 | tr '\n' ','
}

function x11vnc-loop () {
    # Start X11 session via VNC when GDM is running.
    while systemctl -q is-active gdm; do
        x11vnc
    done
}

alias terminate='sudo killall'
alias show-features='grep -R "^ *@" * | grep -i ".feature"'
alias sniff='/usr/bin/python /usr/bin/sniff'
alias behave-no-capture='behave-3 --no-capture --no-capture-stderr --no-logcapture'

# Track the state of network links, connections, and IPv4/IPv6 addresses
alias watchdev='watch -d nmcli dev status'
alias watchlink='watch -d ip -0 a s'
alias watchcon='watch -d nmcli connection'
alias watchcona='watch -d nmcli connection show --active'
alias watchip4='watch -d ip -4 a s'
alias watchip6='watch -d ip -6 a s'
alias watchr4='watch -d ip -4 route show'
alias watchr6='watch -d ip -6 route show'

# Check for modem drivers.
alias check-modem-drivers='lsmod | grep -E "sierra|qmi|qc|wwan|cdc|dcd_ncm|visor|option"'

# Track the events from ModemManager service.
alias watch-ModemManager='journalctl -u ModemManager -ef -o cat'

# Last screenshot and video record
alias last-screenshot='ls -Art ~/Pictures/*.png | tail -n 1'
alias last-video='ls -Art ~/Videos/*.webm | tail -n 1'
EOF
    ) >> $B_RC
    cat "$B_RC"
}


function install_automation_tools() {
  local TOOL_LIST='vim mc usbutils sysstat gnome-system-monitor yum-utils konsole kexec-tools'
  local TOOL_LIST2='wireless-tools dconf-editor tigervnc-server shutter screen x11vnc'
  local PYTHON_MODULES='ipython ipdb'
  local EPEL7_REPO='https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
  # sysstat : Collection of performance monitoring tools
  printf "Install tools: %s\n" "$TOOL_LIST"
  yum install --enablerepo=epel -y -q $TOOL_LIST
  if rpm --quiet -q $TOOL_LIST; then
    echo "Completed."
  else
    echo "Failed."
  fi
  sleep 2
      
  printf "Install Python3 modules: %s\n" "$PYTHON_MODULES"
  if pip3 install "$PYTHON_MODULES"; then
    echo "Completed."
  else
    echo "Failed."
  fi
  sleep 2
  
  echo "Install bug reporing tool..."
  yum install -y -q libreport-rhel-bugzilla
  echo "Completed."
  sleep 2

  echo
  unset ANSWER
  while [[ $ANSWER != [YyNn] ]]; do
    read -p "Do you want to install programming tools? (Y/N): " ANSWER
    case $ANSWER in
    [Yy])
    # Obtain autoconf, automake, gcc, git, m4, perl, and others.
    echo "Install development tools..."
    install_devel_tools
    if rpm --quiet -q autoconf automake gcc git perl; then
      echo "Completed."
      sleep 2
    else
      echo "Failed."
    fi
    ;;
    [Nn])
    echo "Skip development tools."
    sleep 2
    ;;
    *)
    echo "Incorrect answer $ANSWER. Should be Y/N."
    sleep 2
    ;;
    esac
  done


  echo
  if rpm --quiet -q epel-release; then
    echo "EPEL7 repo is already defined. OK."
    sleep 2
  else
    echo "Define EPEL7 repo"
    sleep 2
    yum install -y $EPEL7_REPO
    echo "Completed."
    sleep 2
  fi

  if rpm --quiet -q epel-release; then
    # If EPEL7 is defined then install desired packages.
    echo
    printf "Install various tools used during automated tests:\n%s\n" "$TOOL_LIST2"
    yum install --enablerepo=epel -y -q $TOOL_LIST2
    if rpm --quiet -q $TOOL_LIST2; then
      echo "Completed."
    else
      echo "Failed."
    fi
    sleep 2

    echo "Install console fonts for text mode outside of GUI."
    # Fonts are located in /usr/lib/kbd/consolefonts/
    # Sample usage:
    # setfont /usr/lib/kbd/consolefonts/ter-u22b.psf.gz
    yum install -q -y  --enablerepo=epel terminus-fonts-console terminus-fonts
    if rpm --quiet -q terminus-fonts-console terminus-fonts; then
      echo "Completed."
    else
      echo "Failed."
    fi
    sleep 2
  fi
}


function install_devel_tools() {
    local GROUP[0]="Development and Creative Workstation"
    GROUP[1]="Development Tools"
    local RC[0]=0  # no problems
    RC[1]=0

    # Install all groups from the array.
    for i in $(seq 0 $((${#GROUP[@]} - 1))); do
        # If the group is not installed then install it.
        if ! yum groups list installed | grep -q -w "${GROUP[$i]}"; then
            yum groups install -y "${GROUP[$i]}"; RC[$i]=$?
        fi
    done

    # Final result
    if [ ${RC[0]} -eq 0 -a ${RC[1]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}


function create_shortcuts() {
  # Make shortcut to test scenarios on the desktop of the current user in GNOME 3.
  [ -d "$TEST_DIR" ] && ln -s $TEST_DIR/features ~/Desktop/features

  # Make shortcuts to most frequently used applications.
  for app in \
    "org.gnome.Terminal.desktop" \
    "gnome-tweak-tool.desktop" \
    "sniff.desktop"; do
    # Soft links are not a solution.
    # ln -s "/usr/share/applications/$app" "$HOME/Desktop/$app"
    # Copying the files works fine.
    cp "/usr/share/applications/$app" "$HOME/Desktop/$app"
    sleep 1
  done

  for cmd in \
    "dconf-editor"; do
    ln -s "$(which $cmd)" "$HOME/Desktop/$cmd"
    sleep 1
  done
}


function download_project() {
    local PROJECT=${1:?"Error. Provide project name."}
    local URL=${2:?"Error. Provide URL of a Git repository."}
    # Clone a project from Git repo into the current directory.
    if ! rpm --quiet -q git; then
        echo 'Cannot clone any Git repo. Install prerequisite "git".' >&2
        return 1
    fi

    pushd /mnt/tests
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
          ssh-copy-id -o StrictHostKeyChecking=no pgeorgie@delphinius.usersys.redhat.com
      fi
    fi

    # Prepare directories for automated tests.
    # Useful for local VM, not comming from Beaker.
    mkdir -p /mnt/tests/{control-center,network-manager-applet,NetworkManager-ci,ModemManager,GobiDrivers,libqmi}

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

    # In order to use Brew server you needed CA certificates.
    source ~/bin/get-CA-cert.sh

    if uname -r | grep -q el7; then
        # Install packages from EPEL7 repository.
        install_automation_tools
    fi
    sleep 2
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
            ssh-copy-id -o StrictHostKeyChecking=no pgeorgie@delphinius.usersys.redhat.com
        fi

    fi

    # Log file is needed only for the user "test" under which automated test are run.
    set_debug_log "$HOME/$COMPONENT/debug.log"

    extend_bash_profile

    extend_bashrc

    # Make shortcut to test scenarios on the desktop of the current user in GNOME 3.
    # Make shortcuts to most frequently used applications.
    create_shortcuts

    # Modify GNOME settings outside of GUI.
    # Enable accessibility technology A11Y in GNOME3.
    dbus-launch gsettings set org.gnome.desktop.interface toolkit-accessibility true
    # Disable power saving
    dbus-launch gsettings set org.gnome.desktop.session idle-delay 0

    set_user_preferences
    download_project $COMPONENT https://gitlab.cee.redhat.com/desktopqe/$COMPONENT.git
fi  # when logged as normal user

# Author: Pavlin Georgiev
# Created on: 7/13/2016
# Last update: 10/26/2018
