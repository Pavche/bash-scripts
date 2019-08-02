#!/usr/bin/env bash
#
# Prepare the Linux environment for software testing.
# Go to the directory where the automated tests are located.
# Make it possible to see graphics applications in the graphics environment
# of a remote machine via VNC.
# Check for wireless adaptes needed for some tests.
# The script should be run on the TESTING MACHINE as user "test".
# 1st command line parameter should be an existing software package in Linux.

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

function set_gnome_terminal_rhel8 () {
  # Modify fonts, colors. 'Run command as a login shell'=True, General.'Theme Variant='Light'
  # Disable menu accelerator F10.
  # This function works for a single terminal profile.
  # This funtion can be run in a GNOME session only.

  # Get the black terminal
  #  dconf dump / > dconf_dark_terminal
  #  gsettings list-recursively > gsettings_dark_terminal

  # Modify all colors to brigth + bigger letters + shell execution
  #  dconf dump / > dconf_light_terminal
  #  gsettings list-recursively > gsettings_light_terminal

  # COMPARE both terminals
  #  diff dconf_dark_terminal dconf_light_terminal
  # Copy and paste those differencies.
  #16c16,21
  #< use-theme-colors=true
  #16c16
  #---
  #> background-color='rgb(255,255,221)'
  #> login-shell=true
  #> use-theme-colors=false
  #> foreground-color='rgb(0,0,0)'
  #> use-system-font=false
  #> font='Monospace Bold 14'
  #19a25
  #> theme-variant='light'

  #  diff gsettings_dark_terminal gsettings_light_terminal
  # Copy and paste those differencies.
  #  168c168
  #  < org.gnome.Terminal.Legacy.Settings theme-variant 'dark'
  #  ---
  #  > org.gnome.Terminal.Legacy.Settings theme-variant 'light'

  # What is tne name of Terminal profile?
  # Inial state is:
  # [org/gnome/terminal/legacy]
  # 
  # After 1st configuraton, the profile looks like:
  # [org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]

  # How to find GNOME terminal profiles? How to match them?
  DEFAULT_PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | awk 'NR>1{print $1}' RS=\' FS=\')
  PROFILE=$(dconf dump / | grep -w gnome | grep -w terminal | grep -w "$DEFAULT_PROFILE_ID" | awk 'NR>1{print $1}' RS='[' FS=']')
  DCONF_DIR="/$PROFILE"
  
  # Extract the contents of terminal progile.
  dconf dump $DCONF_DIR/ > ~/dconf_dump.bak

  echo "Modify the gnome-terminal profile."
  dconf write $DCONF_DIR/use-theme-colors false
  dconf write $DCONF_DIR/background-color "'rgb(255,255,221)'"
  dconf write $DCONF_DIR/foreground-color "'rgb(0,0,0)'"
  dconf write $DCONF_DIR/use-system-font false
  dconf write $DCONF_DIR/font "'Monospace Bold 14'"
  dconf write $DCONF_DIR/theme-variant "'light'"
  dconf write $DCONF_DIR/menu-accelerator-enabled false
  dconf write $DCONF_DIR/login-shell true

  SCHEMA='org.gnome.Terminal.Legacy.Settings'
  gsettings set $SCHEMA theme-variant 'light'
  gsettings set $SCHEMA menu-accelerator-enabled false

  echo "The profile was modified."
}

function install_debugging_tools () {
  # Install ipdb and IPython.
  # For Python 2.7
  pip2 install --upgrade pip
  pip2 install ipdb==0.8 'ipython<6.0'

  # Python 3.6 and above
  pip3 install --upgrade pip
  pip3 install ipdb ipython
}

function set_user_preferences () {
    # Define how some useful tools will work during software testing and Linux administraion.
    # VIM editor: Remove smart indentation which allows you to
    # easily copy & paste source code. Overwrite existing config.
    cat >  ~/.vimrc << EOF
set nosmartindent
EOF
    
    # Set up light color for background before testing.
    gsettings set org.gnome.desktop.background picture-uri 'file:////usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
    gsettings set org.gnome.desktop.background primary-color '#fad166'
    gsettings set org.gnome.desktop.background picture-options 'wallpaper'
    gsettings set org.gnome.desktop.background secondary-color '#fad166'
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
  # Do not insert leading spaces in the code segment below
  cat >> $B_PROFILE << EOF 
export TERM=xterm

# Component name in Linux for testing
export COMPONENT=$COMPONENT

# Location of the source code of automated tests
export NOTEBOOK='pgeorgie@dolphin.usersys.redhat.com'
export SRC_CODE="\$NOTEBOOK:Work/\$COMPONENT"

# Locations for sending logs, screenshots, and other files
export RAMP="\$NOTEBOOK:Downloads"

export DEBUG_LOG=\$HOME/"\$COMPONENT"_debug.log

# Location of automated tests
export TEST_DIR="$TEST_DIR/\$COMPONENT"
cd \$TEST_DIR
EOF

  # Needed for root user only.
  if [ $EUID -eq 0 ] && \
  [ ! "$COMPONENT" == "ModemManager" ] && \
  [ ! "$COMPONENT" == "NetworkManager-ci" ] && \
  [ ! "$COMPONENT" == "gnome-initial-setup" ]; then
    cat >> $B_PROFILE << EOF
# Start testing of Linux GUI.
echo
echo "Enable automatic start of dogtail in 5 sec..."
echo "Press Ctrl+C to interrupt."
sleep 5
sudo -u test dogtail-run-headless-next bash
# sudo -u test dogtail-run-headless-next x11vnc
EOF
  fi
}

function extend_bashrc () {
    # Add new commands for tacking the behavor of netork interfaces, connections, and routes.
    # Do not leave leading spaces in the code segment below
    cat << EOF >> $B_RC

# Track the state of network links, connections, and IPv4/IPv6 addresses
alias watchdev='watch -d nmcli dev status'
alias watchlink='watch -d ip -0 a s'
alias watchcon='watch -d nmcli connection'
alias watchcona='watch -d nmcli connection show --active'

# Last video record
alias last-video='ls -Art ~/Videos/*.webm | tail -n 1'

# See network profiles
alias lsnetcfg='ls -1 /etc/sysconfig/network-scripts/*'

# Show 1st graphics card.
alias show_vga='lspci -nn -s \$(lspci | grep -m1 VGA | cut -f1 -d" ") | cut -d: -f3-'
alias show_graphics='lspci -nn -s \$(lspci | grep -m1 VGA | cut -f1 -d" ") | cut -d: -f3-'

# Manage broadband modems on a USB port or a USB hub.
function usb_hub_disable_all() {
  for i in {0..7}; do
    ./acroname.py --port $i --disable
  done
}

function usb_hub_enable() {
  usb_hub_disable_all
  sleep 2
  ./acroname.py --port $1 --enable
}

function lsusbv() {
  # Example
  # lsusb -v -d 1199:a001 | head -n20
  local USB_ID=${1:?"Error: USB ID is missing."}
  lsusb -v -d $USB_ID | head -n 20
  return $?
}
EOF
}

function install_tools() {
  local TOOL_LIST='vim-enhanced mc dconf-editor'

  echo "Install tools:"
  i=1
  for tool in $TOOL_LIST; do
    echo "$i. $tool"
    i=$((i+1))
  done
  sleep 2
  yum install -y -q $TOOL_LIST
  isOK
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
    git clone "$URL" || return $?

    # Update project's submodules.
    if [ $PROJECT == $COMPONENT ]; then
        pushd "$COMPONENT"
        git submodule update --init --recursive || return $?

        if [ "$COMPONENT" == "control-center" ]; then
          pushd control-center-networking/common_steps
          git pull origin rhel-8-py3
          popd

          pushd control-center-networking/NetworkManager-ci
          git pull origin master || return $?
          popd
        fi
    fi
    popd  # /mnt/tests
}

function set_kernel_params () {
    echo 'Disable consistent network device naming and BIOS names.'
    grubby --update-kernel=ALL --args="biosdevname=0 net.ifnames=0"
    echo 'Takes effect after reboot.'
}

function define_repo_rhel8 () {
  # Define reopository for RHEL 8.0 BaseOS and AppStream
  # 3 variants - released, rel-eng, nightly
  local REPO_TYPE=${1:?"Error: repo type is missing. Possible values: released, rel-eng, nightly."}
  local DISTRO_NAME=${2:?"Error: ditro name is missing. Examples: 8.0.0, RHEL-8.0-Snapshot-1.0, RHEL-8.1.0-20190606.n.0"}
  
  if [ "$REPO_TYPE" == "released" ]; then
    # Examples
    #     http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.0-Beta/BaseOS/x86_64/os/
    #     http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.0.0/BaseOS/x86_64/os/
    #     http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.1.0-InternalSnapshot-2.1/BaseOS/x86_64/os/
    # They work with names, not with distribution numbers.
    SERVER='download-ipv4.eng.brq.redhat.com'
    URL1="http://$SERVER/released/RHEL-8/$DISTRO_NAME/BaseOS/x86_64/os/"
    
    # Define AppStream repo
    # Examples
    #     http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.0-Beta/AppStream/x86_64/os/
    URL2="http://$SERVER/released/RHEL-8/$DISTRO_NAME/AppStream/x86_64/os/"
  elif [ "$REPO_TYPE" == "rel-eng" ]; then
    # Examples
    #     http://download-ipv4.eng.brq.redhat.com/rel-eng/RHEL-8.0-Alpha-1.0/compose/BaseOS/x86_64/os/
    #     http://download-ipv4.eng.brq.redhat.com/rel-eng/RHEL-8.0-Beta-1.7/compose/BaseOS/x86_64/os/
    #     http://download-ipv4.eng.brq.redhat.com/rel-eng/RHEL-8.0-Snapshot-1.0/compose/BaseOS/x86_64/os/
    #     http://download.eng.rdu2.redhat.com/rel-eng/latest-RHEL-8.1/compose/BaseOS/x86_64/os/
    SERVER='download-ipv4.eng.brq.redhat.com'
    URL1="http://$SERVER/rel-eng/$DISTRO_NAME/compose/BaseOS/x86_64/os/"
    # Define AppStream repo
    # Example
    #     http://download-ipv4.eng.brq.redhat.com/rel-eng/RHEL-8.0-Beta-1.7/compose/AppStream/x86_64/os/
    #     http://download.eng.rdu2.redhat.com/rel-eng/latest-RHEL-8.1/compose/AppStream/x86_64/os/

    URL2="http://$SERVER/rel-eng/$DISTRO_NAME/compose/AppStream/x86_64/os/"
  elif [ "$REPO_TYPE" == "nightly" ]; then
    # Examples
    #     http://download-ipv4.eng.brq.redhat.com/nightly/RHEL-8.0.0-20190605.n.0/compose/BaseOS/x86_64/os/
    #     http://download-ipv4.eng.brq.redhat.com/nightly/RHEL-8.1.0-20190606.n.0/compose/BaseOS/x86_64/os/
    SERVER='download-ipv4.eng.brq.redhat.com'
    URL1="http://$SERVER/nightly/$DISTRO_NAME/compose/BaseOS/x86_64/os/"
    # Define AppStream repo
    # Example
    #     http://download-ipv4.eng.brq.redhat.com/nightly/RHEL-8.1.0-20190606.n.0/compose/AppStream/x86_64/os/
    URL2="http://$SERVER/nightly/$DISTRO_NAME/compose/AppStream/x86_64/os/"
  else
    echo "Unsupported distribution \"$DISTRO_NAME\"." >&2
    return 1
  fi
  
  cat > /etc/yum.repos.d/$DISTRO_NAME.repo << EOF
[${DISTRO_NAME}-baseos]
name=${DISTRO_NAME} \$basearch BaseOS
baseurl=$URL1
enabled=1
gpgcheck=0

[${DISTRO_NAME}-appstream]
name=${DISTRO_NAME} \$basearch AppStream
baseurl=$URL2
enabled=1
gpgcheck=0
EOF

  # Final check.
  if [ -f "/etc/yum.repos.d/$DISTRO_NAME.repo" ]; then
    echo "Repo was defined: /etc/yum.repos.d/$DISTRO_NAME.repo"
  else
    echo "Failed to define repo /etc/yum.repos.d/$DISTRO_NAME.repo" >&2
    return 1
  fi

  yum makecache
  if ! yum repolist | grep "$DISTRO_NAME" | grep -q baseos; then
    echo "Error: failed to define repo: ${DISTRO_NAME}-baseos" >&2
    return 1
  fi
  if ! yum repolist | grep "$DISTRO_NAME" | grep -q appstream; then
    echo "Error: failed to define repo: ${DISTRO_NAME}-appstream" >&2
    return 1
  fi
  
  echo "OK. Repository was defined successfully."
}

# Is the script is run as root?
if [ $EUID -eq 0 ]; then
    # Generate a SSH key and copy it to my notebook
    # in order to copy files without asking for password,
    # only if it is not already generated.
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
      # Generate a RSA key.
      ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''; RC=$?
      if [ $? -ne 0 ]; then
          echo "Could not generate a SSH key for root."
          exit 2
      else
          echo "SSH key was generated."
          sleep 2
      fi
    fi
    # Copy the SSH key of user test to provide passwordless file transfer.
    ssh-copy-id -o StrictHostKeyChecking=no pgeorgie@dolphin.usersys.redhat.com

    groupadd --gid 10001 testers
    usermod -aG testers test

    # Go to the directory where the tests are located.
    if [[ -d "$TEST_DIR" ]]; then
        # Assign file ownership to user test
        chown -R test:testers "$TEST_DIR"
    else
        echo "The directory $TEST_DIR does not exist."
        echo "It will be created now."
        mkdir -p "$TEST_DIR"
    fi
    
    echo
    # In order to use Brew server you needed CA certificates.
    if source ~/bin/get-CA-cert.sh; then
        echo "OK. Security certificates were imported."
    else
        echo "Error: failed to import security certificates." >&2
        exit 1
    fi
    sleep 2
    
    if uname -r | grep -w -q el8; then
      echo "Define repository latest-RHEL-8.1"
      define_repo_rhel8 rel-eng latest-RHEL-8.1
      sleep 2
    fi  
    echo
    install_tools
    sleep 2
    install_debugging_tools
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

    # Grant user test permission to read/write.
    sudo chown -R test:test "$TEST_DIR"
    echo
    set_user_preferences
    extend_bash_profile
    echo "bash profile was extended with new variables."
    extend_bashrc
    echo "bash rc was extended with new aliases and functions."
    set_kernel_params
fi  # when logged as root


# Is the sript run as normal user, for example "test"?
if [ $EUID -ge 1000 ]; then
    # Generate a SSH key and copy it to my notebook
    # in order to copy files without asking for password,
    # only if it is not already generated.
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        # Generate a RSA key.
        ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''; RC=$?
        if [ $RC -ne 0 ]; then
            echo "Could not generate a SSH key for user $(whoami)."
            exit 8
        else
          echo "SSH key was generated."
          sleep 2
          # Copy the SSH key of user test to provide passwordless file transfer.
          ssh-copy-id -o StrictHostKeyChecking=no pgeorgie@dolphin.usersys.redhat.com
        fi

    fi

    # Log file is needed only for the user "test" under which automated test are run.
    set_debug_log "$HOME/$COMPONENT/debug.log"

    # Modify GNOME settings inside of GUI. When logged to a GNOME session.
    # Enable accessibility technology A11Y in GNOME3.
    gsettings set org.gnome.desktop.interface toolkit-accessibility true
    # Disable power saving
    gsettings set org.gnome.desktop.session idle-delay 0
    
    download_project $COMPONENT https://gitlab.cee.redhat.com/desktopqe/$COMPONENT.git; RC=$?
    if [ $RC -eq 0 ]; then
      echo "OK. Git project \"$COMPONENT\" was cloned successfully."
    else
      echo "Error: failed to clone git project \"$COMPONENT\"." >&2
      # Do not stop here. Continue with initial preparation.
      sleep 3
    fi
    
    echo
    set_user_preferences
    if uname -r | grep -w el7; then
      set_gnome_terminal_rhel7
    elif uname -r | grep -w el8; then
      set_gnome_terminal_rhel8
    else
      set_gnome_terminal_rhel7
    fi
    extend_bash_profile
    echo "bash profile was extended with new variables."
    extend_bashrc
    echo "bash rc was extended with new aliases and functions."

fi  # when logged as normal user

# Author: Pavlin Georgiev
# Created on: 7/13/2016
# Last update: 8/2/2019

