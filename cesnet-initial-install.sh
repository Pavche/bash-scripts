#!/usr/bin/env bash

# Works under Fedora 31

function isOK () {
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "Failed"
    return 1
  fi
}

echo "Install text editors"
dnf install -y vim kate
isOK || exit 1

echo "Install GNOME tweaks"
dnf install -y gnome-tweaks
isOK || exit 1

echo "Install e-mail client: Thunderbird"
dnf install -y thunderbird
isOK || exit 1

echo 'Install Kerberos5 client'
dnf install -y *krb5*
isOK || exit 1

echo "Install and configure chat IRC client: hexchat"
dnf install -y hexchat
isOK || exit 1

echo "Install JAVA"
dnf install -y java-1.8.0-openjdk*
isOK || exit 1

echo "Install LibreOffice"
dnf install -y libreoffice*
isOK || exit 1

echo "Install screen multiplexer"
sleep 2
dnf install -y terminator
isOK || exit 1

echo "Install file comparison tool: Meld"
sleep 2
dnf install -y meld
isOK || exit 1

# echo "Configure OpenVPN for remote connection to CESNET"
# echo "Set correct file permissions for personal certificates."
# CERT='/etc/openvpn/vpn_cert_Pavlin_Georgiev_PC.p12'
# chown root:root "$CERT"
# chmod 600 "$CERT"

echo "Install chat client keybase"
sleep 2
dnf install -y https://prerelease.keybase.io/keybase_amd64.rpm
isOK || exit 1

echo "Download collaboration tool: Slack"
sleep 2
firefox "https://slack.com/downloads/linux"

echo "Install Python modules for LDAP authentication"; read key
echo "Used for developping and modifying functions in Indico."
sleep 5
dnf install -y ansible*

echo "Download Apache Directory Studio"
wget -O /tmp/ADS.tar.gz \
  https://downloads.apache.org/directory/studio/2.0.0.v20200411-M15/ApacheDirectoryStudio-2.0.0.v20200411-M15-linux.gtk.x86_64.tar.gz
if isOK; then
  echo 'Installing ADS'
  tar xvf /tmp/ADS.tar.gz --directory=$HOME
  isOK || exit 1
else  
  echo "Try to download manually"
  sleep 2
  firefox "https://directory.apache.org/studio/download/download-linux.html"
fi

echo "Monitor calibration"
echo "Calibrate color, brightness, contrast and gamma correction"
sleep 5
firefox "http://www.lagom.nl/lcd-test/contrast.php"

echo "Install Adobe Flash player"
sleep 2
firefox "https://get.adobe.com/flashplayer"

echo "KeePassX2"
dnf install -y keepass
echo "Set up e-mail client"
echo "Set up personal certificate in internet browser"
echo "Set up personal certificate in e-mail client"
echo "Set up signature of e-mails"
echo "Configure SSH keys"
echo "Set up konsole to use: font DejaVu Sans Mono 14 pt"
echo "Configure password manager for password autocomplete"
isOK || exit 1

echo "Install multimedia player: VLC"
URL='https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-31.noarch.rpm'
dnf install -y $URL
isOK || exit 1

dnf install -y vlc
isOK || exit 1

echo "Install codecs"


echo "Install backup software"
dnf install -y deja-dup duplicity
isOK || exit 1


echo -e '\nAdditional packages for work productivity and effectivness.\n'
sleep 2
dnf install -y ccze  # Robust log colorizer
dnf install -y donf-editor  # Editor and viewer for GNOME settings
dnf install -y terminus* # Special fonts for terminal when the GUI is not working
dnf install -y expect  # Automatic typing tool for the terminal
dnf install -y mc konsole

echo -e '\nTools for network administration\n'
sleep 2
dnf install -y nmap-ncat


echo -e "\nSet up e-mail client:\n  A) account\n  B) signature\n  c) personal certificate"

echo "Set up personal certificate in internet browser"

function copy_ssh_keys() {
    echo "Configure SSH keys"
    SRC_DIR=${1:?"Error: source directory not provided."}
    DST_DIR=${2:-"$HOME/.ssh"}
    
    key_file='id_ed25519'
    key_pub_file='id_ed25519.pub'
    
    echo -e "\nCopy private key: $SRC_DIR/$key_file\nto: $DST_DIR"
    scp -pr "$SRC_DIR/$key_file" "$DST_DIR"
    [ $? -eq 0 ] && echo 'OK' || (echo 'Failed'; return 1)
    
    echo -e "\nCopy public key: $SRC_DIR/$key_pub_file\nto: $DST_DIR"
    echo scp -pr "$SRC_DIR/$key_pub_file" "$DST_DIR"
    [ $? -eq 0 ] && echo 'OK' || (echo 'Failed'; return 1)
}

copy_ssh_keys
isOK || exit 1

echo "Set up konsole to use: font DejaVu Sans Mono 14 pt"
echo "Configure password manager for password autocomplete"

function configure_ansible() {
    echo "Set up ANSIBLE automation + key"
    [ -d "$HOME/egi-ansible" ] || mkdir $HOME/egi-ansible
    touch $HOME/egi-ansible/.password; RC=$?
    if [ $RC -eq 0 ]; then
        echo "File .password created for Ansible"
    else
        echo "Error: cannot create $HOME/egi-ansible/.password" >&2
        return 1
    fi
    
    local PASS=""
    read -p "Enter password for EGI ansible: " PASS
    if [ -z "$PASS" ]; then
        echo "Error: empty password not allowed." >&2
        return 1
    fi
    echo "$PASS" > $HOME/egi-ansible/.password
    unset PASS
    
    chmod 600 $HOME/egi-ansible/.password
    
    echo "Password written to:"
    ls -l $HOME/egi-ansible/.password
}

function clone_EGI_repo() {
    echo "Cloning EGI repo for Ansible"
    [ -d "$HOME/Work/EGI" ] || mkdir -p $HOME/Work/EGI
    cd $HOME/Work/EGI
    git clone https://github.com/CESNET/egi-ansible.git || return 1
}

configure_ansible
clone_EGI_repo
