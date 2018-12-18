#!/usr/bin/env bash

# ----- SYSTEM SETUP -----#
# Enable remote control
#   via SSH
#   via VNC
ssh-keygen -t rsa -b 4096
# We assume that user Magarita has already been created during initial installation.
sudo -u margarita ssh-keygen -t rsa -b 4096
systemctl enable sshd
systemctl start sshd
yum makecache
yum install -y tigervnc-server

# Admin tools
yum install -y vim mc


# ----- USER APPLICATION SETUP -----#

# To optimize application installation, yum installer can be left behind.
# One YUM process can install at a time.
# Web browser can download from various pages simultaneously.

# Internet browsing
#   Browser, flash player
#   Java run-time environment
#   Plugin for Bulgarian language, spellchecker.
# Firefox browser comes by default with RHEL / Fedora. Skip installation.
firefox "http://java.com/en/download/manual.jsp" &
firefox "https://get.adobe.com/flashplayer" &


# Videoconferencing, audio, video
#   Communication software
#   Audio drives, ALSA mixer setup, Pulse Audio setup
#   Web camera drivers and setup
firefox "https://www.skype.com/bg/download-skype/skype-for-computer/" &
yum install -y pavucontrol

# Word processing, open documents, spreadsheets.
#  Spellchecker for Bulgarian language. - not available (8 Oct 2017)
yum install -y libreoffice


# Mail client
#   Bulgarian spell checker, BG interface.
yum install -y thunderbird


# PDF viewer
yum install -y evince okular


# Photo viewer
yum install -y eog gwenview


# Graphics editor/image manipulation programs
yum install -y inkscape


# CD/DVD recording software
yum install -y k3b


# Video player and codecs
# TODO: choose a video player. VLC is not available in Fedora 25 repo.
# TODO: find audio and video codecs


# Additional graphics environments
# The one already installed is GNOME 3.
echo "Installing graphics environments"
for e in "KDE Plasma Workspaces" "XFCE"; do
  echo "$e"
  yum groupinstall -y -q "$e"
  [ $? -eq 0 ] && echo "Success" || echo "Failure"
done



# Everything should be visible on the desktop.


echo "End of automated script."
read -p "Press Enter..." key

# ----- INSTALLATION CHECK -----
clear 
# Display short system identification.
hostnamectl
read key
echo

# Check if the network connections are enabled.
echo "Network connections"
ip -4 a s | grep BROADCAST -A1
read key
echo

echo "Install uesr applications that have been previously downloaded via browser"
# We assume that all downloaded apps are RPM packages, located in directory $HOME/Downloads.
echo "Java run-time evironment..."
for pkg in ~/Downloads/jre-*-linux*.rpm; do
   yum install -y -q $pkg
   # The full path to the installation package is already containted in var $pkg.
  [ $? -eq 0 ] && echo "Success" || echo "Failure"
done

echo "Flash player..."
for pkg in ~/Downloads/flash-player*.x86_64.rpm; do 
   yum install -y -q $pkg
   # The full path to the installation package is already containted in var $pkg.
   [ $? -eq 0 ] && echo "Success" || echo "Failure"
done

echo "Skype for Linux..."
yum install -y -q ~/Downloads/skypeforlinux-64.rpm
[ $? -eq 0 ] && echo "Success" || echo "Failure"


# Author: Pavlin Georgiev
# Created on: 8 Oct 2017


