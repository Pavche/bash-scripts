#!/usr/bin/env bash

# This script is for Red Hat compatible Linux that supports YUM package installer.
# It is going to install if not already installed:
# Environment groups are installed at the begining
# 1. Programming language support - C++ Perl PHP
# 2. Latest Java run-time environment for Internet browsers
# 3. Latest Java software development kits
# 4. Newest Linux kernel and kernel for developers
# 5. Flash player for internet browser
# 6. Mail client - Thunderbird
# 7. PDF viewer - Okular
# 8. Multimedia player - VLC
# 9. BitTorrent client - Transmission
# 10. Working with virtual machines using KVM
# 11. Text editors and viewers
# 12. Graphics editors/imaga manipulation programs
# 13. Linux installers with GUI
# 14. System config tools
# 15. Chat client used at workplace
# 16. Book convertor CHM -> PDF
# 17. OCR software
# 18. Terminal multiplexer
# 19. Screen sharing and remote control
# 20. Password manager
# 21. FTP client
# 22. CD/DVD recording software
# 23. Provide debug information
# 24. File and printer sharing
# 25. PulseAudio visual control
# 26. Software for video calls: Skype for Linux, Ekiga
# 27. Software for creating e-Books from AsciiDoc format
# 28. File archivers, file compression tools.
# 29. Creating GUI Applications Under Linux
# 30. Integrated Development Environment for Python - PyCharm



if [ $EUID -ne 0 ]; then
    echo "This script can be run as root only."
    exit 1
fi

echo "OS:" `uname -sr`
echo "Processor type:" `uname -p`

# Define a log file for the automated installation.
export log_file="$HOME/yum-install-$(hostname)-$(date+%Y%d%m).log"
rm -f "$log_file"
touch "$log_file" || echo "Cannot create log file for the automated installation"
[ $? -eq 0 ] || exit 1

# Packages groups first
for group in "GNOME Desktop" "Development and Creative Workstation" "KDE Plasma Workspaces"
do
    yum group install -y "$group"
    echo -n "Installing GNOME Desktop: ">>"$log_file"
    [ $? -eq 0 ] && echo "OK">>"$log_file" || echo "Failed">>"$log_file"
done

# EPEL7 repository
yum install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"


# 1. Programming language support - C/C++
yum groups install -y 'Development Tools'


# 2. Latest Java run-time environment and Internet browsers
# Firefox browser is installed by default.
firefox "http://java.com/en/download/manual.jsp" &
firefox "http://www.opera.com/" &


# 3. Java software development kits
firefox "http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html" &


# 4. Newest Linux kernel and kernel for developers
yum install -y kernel kernel-devel kernel-headers kernel-docs


# 5. Flash player
# Let us suppose that Mozilla is already included in the Linux distributions
firefox "https://get.adobe.com/flashplayer" &


# 6. Mail client - Thunderbird
yum install -y thunderbird


# 7. PDF viewer - Okular, Acrobat Reader 9.5.5
# Acrobat Reader is able the keep hightlighted text and notes inside a PDF file,
# but Okular cannot.
yum install -y okular

# 8. VLC player
# Install RPMfusion free and non-free repository for Fedora 24
yum install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-24.noarch.rpm"; RC=$?
if [ $RC -eq 0 ]; then
    if rpm --quiet -q epel-release; then
        # EPEL7 is a prerequisite for VLC installation.
        yum install -y vlc
    fi
fi

# 9. BitTorrent client - Transimission
# When installing on Fedora no prerequisites are required.
yum install -y transmission

# 10. Working with virtual machines using KVM
yum install -y kvm libvirt virt-manager virt-install virt-clone libguestfs-tools

# 11. Text editors, viewers, note writting, terminals
yum install -y kate vim gnote mc rsh konsole

# Some plugins for Kate editor. Such as: pysmell, PEP8, pyflakes, pyjslint, pyplete, simplejson.
pip install Kate-plugins


# 12. Graphics editor/image manipulation programs
yum install -y gimp inkscape


# 13. Linux installers with GUI
yum install -y yumex synaptic


# 14. Linux system config tools
yum install -y system-config-*


# 15. Chat client used at workplace with blinking icons for alert
yum install -y xchat gnome-shell-extension-top-icons.noarch gnome-shell-extension-common

# 16. Book convertor: CHM to PDF
yum install -y chm2pdf python-BeautifulSoup

# 17. OCR software
yum install -y tesseract-langpack-lat \
tesseract-langpack-ell \
tesseract-devel \
tesseract-langpack-equ \
tesseract-langpack-ces \
tesseract-langpack-rus \
tesseract-langpack-enm \
tesseract-langpack-bul \
tesseract \
tesseract-osd

# 18. Terminal multiplexer
# Mutiple terminals on 1 screen. Tracking the status of network connections, devices, etc.
# Typing the same commands to multiple hosts via SSH.
yum install -y \
screen \
terminator
# 1st is text based managed via key shortcuts
# 2nd has GUI managed via menus and key shortcuts

# 19. Screen sharing and remote control
yum install -y tigervnc tigervnc-server

# 20. Password manager
yum install -y keepassx2

# 21. FTP client
yum install -y filezilla

# 22. CD/DVD recording software
yum install -y k3b

# 23. Provide debug information about some major applications in RHEL7
yum install -y ddd  #graphical front-end to gdb, included in the Fedora EPEL repository

# 24. File and printer sharing
# AutoFS - A tool for automatically mounting
# CIFS
# NFS - NFS utilities and supporting clients and daemons for the kernel NFS server
# Samba - Server and Client software to interoperate with Windows machines
yum install -y nfs-utils cifs-utils samba-client autofs

# 25. PulseAudio visual control
yum install -y pavucontrol

# 26. software for video calls: Skype for Linux, Ekiga
# Skype for Linux
# Try automatic download, if it fails then go to M$ web.
wget https://go.skype.com/skypeforlinux-64.rpm; RC=$?
if [ $RC -eq 0 ]; then
  echo "Skype has been successfully downloaded."
  yum install -y -q skypeforlinux-64.rpm
  [ $? -eq 0 ] && echo "Skype has been successfully installed." || echo "Failed to install Skype." >&2
  sleep 2
else
  echo "Skype could not be downloaded automatically." >&2
  echo "Proceed with manual download via Firefox browser."
  sleep 2
  firefox "https://www.skype.com/en/get-skype/" &
fi

# Ekiga - VoIP and video conferencing application for GNOME and Microsoft Windows.
# More information: https://en.wikipedia.org/wiki/Ekiga
yum install -y ekiga
[ $? -eq 0 ] && echo "Ekiga has been successfully installed." || echo "Failed to install Ekiga." >&2
sleep 2


# 27. Software for creating e-Books from AsciiDoc format
yum install -y rubygem-asciidoctor


# 28. File archivers, file compression tools.
yum install -y p7zip*


# 29. Creating GUI Applications Under Linux
yum install -y glade


# Additional packages for work productivity and effectivness.
yum install -y ipython
yum install -y ccze  # Robust log colorizer
yum install -y donf-editor  # Editor and viewer for GNOME settings
yum install -y *openvpn* # VPN tunnel to the corporate network
yum install -y terminus* # Special fonts for terminal when the GUI is not working
yum install -y gnome-shell-extension-top-icons
yum install -y expect  # Automatic typing tool for the terminal

# Tools for network administration
yum install -y telnet nmap-ncat


#----- 3RD PARTY PLUGINS FOR FIREFOX ----
echo "Install GNOME shell integration."
firefox https://addons.mozilla.org/firefox/downloads/file/854306/gnome_shell_integration-10-an+fx-linux.xpi?src=dp-btn-primary
isOK


echo "Install parser and highlighter for Beaker logs."
firefox https://addons.mozilla.org/firefox/downloads/latest/multiple-highlighter/addon-635540-latest.xpi?src=userprofile \
  && firefox https://addons.mozilla.org/firefox/downloads/file/190142/mason-0.3.7.9.18-fx.xpi?src=dp-btn-primary
isOK


echo "Install plugin for automatic refresh for Firefox browser."
PLUGIN_URL='https://addons.mozilla.org/firefox/downloads/file/378641/autorefresh-0.0.4-fx.xpi?src=dp-btn-primary'
firefox $PLUGIN_URL
if [ $? -eq 0 ]; then
  echo "OK"
  sleep 2
else
  echo "Failed to install plugin for automatic refresh for Firefox browser." >&2
  exit 1
fi


# 30. For Python developers
URL="https://download.jetbrains.com/python/pycharm-community-2019.1.3.tar.gz"
ARCH_NAME=$(basename $URL) 

pushd ~/Downloads/
wget -O $ARCH_NAME $URL \
&& tar xzvf $ARCH_NAME; RC=$?
popd
if [ $RC -eq 0 ]; then
  echo "PyCharm was downloaded in ~/Downloads"
else
  echo "Error: failed to download PyCharm." >&2
  echo "Download via web browser."
  firefox "https://www.jetbrains.com/pycharm/download/#section=linux"
fi

# Author: Pavlin Georgiev
# Last update: 6/17/2019