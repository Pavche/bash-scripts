# Analyse the latest released RHEL8
# Analyse distro RHEL-8.0.0
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.0.0/BaseOS/x86_64/iso/RHEL-8.0.0-20190404.2-x86_64-dvd1.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/RHEL-8/8.0.0/BaseOS/x86_64/os/"
echo -e "\nChecking ISO file: $ISO"
osinfo-detect -f plain -t media $ISO
echo "Checking install tree: $INSTALL_TREE"
osinfo-detect -f plain -t tree $INSTALL_TREE


# Analyse the latest released RHEL7
# Analyse distro RHEL-7.7
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.7/Workstation/x86_64/iso/RHEL-7.7-20190723.1-Workstation-x86_64-dvd1.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/RHEL-7/7.7/Workstation/x86_64/os/"
echo -e "\nChecking ISO file: $ISO"
osinfo-detect -f plain -t media $ISO
echo "Checking install tree: $INSTALL_TREE"
osinfo-detect -f plain -t tree $INSTALL_TREE


# Analyse the latest released Fedora.
# Analyse distro Fedora 30 Workstation
# ISO file
ISO="http://download-ipv4.eng.brq.redhat.com/released/fedora/F-30/GOLD/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-30-1.2.iso"
# installation tree on a server
INSTALL_TREE="http://download-ipv4.eng.brq.redhat.com/released/fedora/F-30/GOLD/Workstation/x86_64/os/"
echo -e "\nChecking ISO file: $ISO"
osinfo-detect -f plain -t media $ISO
echo "Checking install tree: $INSTALL_TREE"
osinfo-detect -f plain -t tree $INSTALL_TREE
