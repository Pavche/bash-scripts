#!/usr/bin/env bash

# Get information for troubleshooting in one diagnostic file.

function install_needed_software() {
    # Install tools for diagnostic and troubleshooting.
    # Linux USB utilities
    # Advanced Linux Sound Architecture (ALSA) utilities
    # PulseAudio sound server utilities
    # A nl80211 based wireless configuration tool
    local PKG_LIST=${1:-'usbutils alsa-utils pulseaudio-utils iw'}
    echo "Installing needed software packages..."
    sleep 2

    yum install -y $PKG_LIST

    echo "Installing needed software packages...Done"
    sleep 2
}

function collect_rpm_info () {
    # Get info about a list of specified RPM packages and then all installed RPM packages.
    # 1st argument is the full path to the log file where to collect info.
    local COMPONENT=${1:?"Error. Component's name not provided."}
    local DIAG_FILE=${2:-"/tmp/diagnostics.log"}

    echo "Collecting information about installed RPM packages..."
    case $COMPONENT in
        control-center)
        # What depent packages are installed on the system.-> Build a list of dependent package for control-center.
        # control-center is bound to GUI GNOME3. Build a list of dependent packages.
        # I need a list of RPM packages, not only required libraries (*.so files).
        # The application c-c does not run alone, it depends on the functioning of other applications + OS + ovladace.
        # Command: yum deplist gives this information, but it is better to apply filtering and sorting.
        # Rozdelit problem s control-center do nekolik skupin a kontrolovat kazdou zvlast.
        # Zacit s reportovanim negrafickych programu. NetworkManager, GLib. Potom GTK3, gnome-shell a graficky zaklad control-centeru.
        # Nemichat OS a ovladace s resenim problemu u grafickych aplikaci.
        # List dependent packages, grouped by provider, sorted, unique:
        echo -e "\n\nQuery for dependent packages for control-center" >> "$DIAG_FILE"
        DEP_LIST=$(yum deplist control-center | grep provider | awk -F': ' '{print $2}' | awk -F'.' '{print $1}' | sort | uniq)
        # Get the installed RPMs.
        rpm -q $DEP_LIST >> "$DIAG_FILE" 2>&1
        sleep 2

        echo -e "\n\nQuery for packages used for testing control-center" >> "$DIAG_FILE"
        # Based on RHEL 7.4/7.5/7.6.
        if uname -r | grep -q -w el7; then
            rpm -q bridge-utils control-center cups-pdf dnsmasq firefox gutenprint gutenprint-foomatic gnome-shell \
            gstreamer1-plugins-good kde-baseapps NetworkManager-libreswan ntp pexpect >> "$DIAG_FILE"
        fi
        # TODO: Run control-center in GTK3 debug mode to obtains logs and send them to dear developpers.
        ;;
        ModemManager)
        echo -e "\n\nQuery for dependent packages for ModemManager" >> "$DIAG_FILE"
        DEP_LIST=$(yum deplist ModemManager | grep provider | awk -F': ' '{print $2}' | awk -F'.' '{print $1}' | sort | uniq)
        # Get the installed RPMs.
        rpm -q $DEP_LIST >> "$DIAG_FILE" 2>&1
        sleep 2

        echo -e "\n\nQuery for packages used for testing ModemManager" >> "$DIAG_FILE"
        # Based on RHEL 7.4/7.5/7.6.
        echo "kernel-$(uname -r)" >> "$DIAG_FILE"
        if uname -r | grep -q -w el7; then
            rpm -q kernel ModemManager NetworkManager usb_modeswitch usb_modeswitch-data >> "$DIAG_FILE"
        fi
        # kernel is included because it contains drivers for mobile broadband modems.
        ;;
        gtk3)
        echo -e "\n\nQuery for dependent packages for GTK+ 3" >> "$DIAG_FILE"
        DEP_LIST=$(yum deplist gtk3 | grep provider | awk -F': ' '{print $2}' | awk -F'.' '{print $1}' | sort | uniq)
        # Get the installed RPMs.
        rpm -q $DEP_LIST >> "$DIAG_FILE" 2>&1
        sleep 2

        echo -e "\n\nQuery for packages used for testing GTK+ 3" >> "$DIAG_FILE"
        # Based on RHEL 7.4/7.5/7.6.
        if uname -r | grep -q -w el7; then
            rpm -q cups cups-pdf epel-release evolution gedit gnome-shell gnome-documents gtk3 gtk3-devel ImageMagick \
            libreoffice-langpack-en pexpect poppler-utils unoconv >> "$DIAG_FILE"
            echo -e "\nQuery Python modules used for testing GTK+ 3" >> "$DIAG_FILE"
            pip show PyPDF2 iniparse >> "$DIAG_FILE"
        fi
        ;;
        *)
        echo "Collecting info about all installed RPM packages..."
        sleep 2
        echo -e "\n\nList of all installed packages" >> "$DIAG_FILE"
        rpm -qa | sort >> "$DIAG_FILE"
        ;;
    esac

    echo -e "\n\nInformation about automation tools" >> "$DIAG_FILE"
    # NOTE: Get the list on installed packages from Beaker, in task /desktop/rhel7/install.
    # This are the contents of package default RPM packages for that task.
    # RPM contents are extracted on the testing machine in directory
    # /mnt/tests/desktop/rhel7/install
    rpm -q dogtail \
    python2-behave \
    python-enum34 \
    python-parse \
    python-parse_type \
    python-six >> "$DIAG_FILE"

    echo "Collecting information about installed RPM packages...Done"
    sleep 2
}

function collect_hardware_info() {
    # Gather information about the Linux system.
    # 1st argument is the full path to the log file where to collect info.
    local DIAG_FILE=${1:-'/tmp/diagnostics.log'}

    echo "Collecting hardware information..."
    echo -e "\n\nList PCI and PCI-e devices including vendor ID" >> "$DIAG_FILE"
    lspci -v -nn >> "$DIAG_FILE" 2>&1
    echo -e "\n\nList of USB devices" >> "$DIAG_FILE"
    lsusb >> "$DIAG_FILE" 2>&1
    echo "Collecting hardware information...Done"
    sleep 2
}

function collect_audio_controller_info() {
    # Get diagnostic data about available sound cards.
    # Get information from ALSA mixer and PulseAudio.
    # 1st argument is the full path to the log file where to collect info.
    local DIAG_FILE=${1:-'/tmp/diagnostics.log'}
    echo "Collecting information about audio controlers..."

    echo -e "\n\nShow what sound devices you can control." >> "$DIAG_FILE"
    echo '$ amixer controls' >> "$DIAG_FILE"
    amixer controls >> "$DIAG_FILE" 2>&1

    echo -e "\n\nShow the values of sound volume for the devices." >> "$DIAG_FILE"
    echo '$ amixer contents' >> "$DIAG_FILE"
    amixer contents >> "$DIAG_FILE" 2>&1

    echo -e "\n\nShow audio devices in PulseAudio." >> "$DIAG_FILE"
    echo '$ pactl list short sinks' >> "$DIAG_FILE"
    pactl list sinks >> "$DIAG_FILE" 2>&1

    echo -e "\n\nShow devices for sound input (microphone)." >> "$DIAG_FILE"
    echo '$ arecord --list-devices' >> "$DIAG_FILE"
    arecord --list-devices >> "$DIAG_FILE" 2>&1

    echo -e "\n\nShow devices for sound input (microphone) in PulseAudio." >> "$DIAG_FILE"
    echo '$ pactl list sources' >> "$DIAG_FILE"
    pactl list sources >> "$DIAG_FILE" 2>&1

    echo "Collecting information about audio controlers...Done"
    sleep 2
}

function collect_wifi_info() {
    # Get diagnostic data about available wireless adapters.
    # 1st argument is the full path to the log file where to collect info.
    local DIAG_FILE=${1:-'/tmp/diagnostics.log'}

    echo "Collecting info about Wi-Fi adapters..."

    echo -e "\n\nShow wireless adapters." >> "$DIAG_FILE"
    echo '$ iw list' >> "$DIAG_FILE"
    iw list >> "$DIAG_FILE" 2>&1

    echo "Collecting info about Wi-Fi adapters...Done"
    sleep 2
}

function collect_logs() {
    # Collect info from the following logs:
    # * journalctl
    # * NetworkManager
    # * wireless devices

    local DESTINATION_DIR=${1:-'/tmp'}

    pushd "$DESTINATION_DIR"
    echo "Collecting info from logs..."
    # Read the kernel buffer from last boot.
    journalctl > journalctl_$(hostname --short).log

    # Get info about events in the system log generated by NetworkManager.
    journalctl -xu NetworkManager -o cat > NetworkManager_$(hostname --short).log

    # Make NetworkManager more verbose for tracking changes.
    # Restart NetworkManager, wait 5 secs, and get the log that event.
    # Return the previous verbosity of NM.
    nmcli general logging level debug domains all
    journalctl -fu NetworkManager -o cat > NetworkManager_restart_$(hostname --short).log &
    systemctl restart NetworkManager
    # Wait for messages from NetworkManager to be recorded in the journal.
    sleep 5
    kill $(pidof journalctl)  # Stop logging NetworkManager.
    sleep 3
    nmcli general logging level info domains all

    # Obtain information about wireless adapters: hardware and communication capabilities.
    # TODO: Fix this section.
    WIFI_DEV_ID=$(lspci | grep 'Network controller' | cut -f1 -d" ")
    # Is there a Wi-Fi adapter?
    if [[ ! -z "$WIFI_DEV_ID" ]]
    then
        # There is a Wi-Fi adapter.
        lspci -v -s "$WIFI_DEV_ID" > lspci_wifi.txt
        iw list > wifi_capabilities.txt

        # Track the event of reinstalling the Wi-Fi driver.
        journalctl -f > journalctl_reinstall_wifi_driver.log &
        echo "Reinstall the driver for the Wi-Fi adapter..."
        modprobe --remove iwlwifi
        if [ $? -eq 0 ]
        then
            sleep 5
            modprobe iwlwifi
            sleep 5
        else
            echo "Failed to reinstall Wi-Fi driver." >&2
        fi
        echo "Reinstall the driver for the Wi-Fi adapter...Done"
        kill $(pidof journalctl)  # Stop logging driver reinstallation.
        sleep 3
    fi
    echo "Collecting info from logs...Done"
    sleep 2

    # Return to initial directory.
    popd
}

function send_logs() {
    # Send all gathered logs to the collector
    local DIAG_DIR=${1:?"Error. Diagnostic directory not specified."}
    local DESTINATION=${2:?"Error. Destination for log files not specified."}

    pushd "$DIAG_DIR"
    echo "Creating TAR archive..."
    TAR_ARCH="diag_$(hostname --short).tar.gz"
    tar czf "$TAR_ARCH" *.log *.txt
    echo "Creating TAR archive...Done"
    sleep 2

    echo -e "Copy diag file: "$DIAG_DIR/$TAR_ARCH"\nto host: $DESTINATION...\n"
    scp "$TAR_ARCH" "$DESTINATION"; RC=$?
    [ $RC -eq 0 ] && echo "Success." || echo "Failed."
    echo -e "Copy diag file: "$DIAG_DIR/$TAR_ARCH"\nto host: $DESTINATION...Done\n"
    popd
}


# Set needed variables.
HOST_NAME=$(hostname --short)
CPU_ARCH=$(uname -p)
DIAG_DIR='/tmp'
DIAG_FILE="$DIAG_DIR/diag_$CPU_ARCH_$HOST_NAME.txt"
DESTINATION='pgeorgie@dolphin.usersys.redhat.com:Downloads'

# Remove any previous diagnostic file.
[[ -f "$DIAG_FILE" ]] && sudo rm -f "$DIAG_FILE"

clear

install_needed_software
hostnamectl status >> "$DIAG_FILE"
# What is the software package we need information about?
# Example: control-center, gtk3, ModemManager, NetworkManager, network-manager-applet.
# Is it already defined as an external variable?
if [ -z "$COMPONENT" ]; then
    read -p "What is the tested software package?: " COMPONENT
    if [ -z "$COMPONENT" ]; then
        echo "Package name cannot be empty." >&2
        exit 1
    else
        export COMPONENT
    fi
fi
collect_rpm_info "$COMPONENT" "$DIAG_FILE"
collect_hardware_info "$DIAG_FILE"
collect_audio_controller_info "$DIAG_FILE"
collect_wifi_info "$DIAG_FILE"
collect_logs "$DIAG_DIR"
send_logs "$DIAG_DIR" "$DESTINATION"
# TODO: Create a separate diagnostic file containing info about:
# * CPU information
# * PC platform/BIOS information
# * hardware devices, including vendor ID
# * kernel
# * loaded drivers
# * sound devices, ALSA and PulseAudio
# * Wi-Fi adapters, Wi-Fi capabilities and modes

# Transfer the diagnostic file to my notebook.

# Author: Pavlin Georgiev
# Created on: 9 Feb 2017
# Last modification: 25 Jun 2018
# I love this script!
