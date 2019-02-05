#!/usr/bin/env bash

# Available Environment Groups:
#    Fedora Custom Operating System
#    Minimal Install
#    Fedora Server Edition
#    Fedora Workstation
#    Fedora Cloud Server
#    KDE Plasma Workspaces
#    Xfce Desktop
#    LXDE Desktop
#    LXQt Desktop
#    Cinnamon Desktop
#    MATE Desktop
#    Sugar Desktop Environment
#    Development and Creative Workstation
#    Web Server
#    Infrastructure Server
#    Basic Desktop
# Available Groups:
#    3D Printing
#    Administration Tools
#    Ansible node
#    Audio Production
#    Authoring and Publishing
#    Books and Guides
#    C Development Tools and Libraries
#    Cloud Infrastructure
#    Cloud Management Tools
#    Compiz
#    Container Management
#    D Development Tools and Libraries
#    Design Suite
#    Development Tools
#    Domain Membership
#    Fedora Eclipse
#    Editors
#    Educational Software
#    Electronic Lab
#    Engineering and Scientific
#    FreeIPA Server
#    Games and Entertainment
#    Headless Management
#    LibreOffice
#    MATE Applications
#    Medical Applications
#    Milkymist
#    Network Servers
#    Office/Productivity
#    Python Classroom
#    Python Science
#    Robotics
#    RPM Development Tools
#    Security Lab
#    Sound and Video
#    System Tools
#    Text-based Internet
#    Window Managers



echo "yum groups install -y \\
\"Fedora Workstation\" \\
\"Development and Creative Workstation\""
sleep 2

yum groups install -y \
"Fedora Workstation" \
"Development and Creative Workstation"

echo "yum groups install -y \\
\"Development Tools\" \\
\"Security Tools\" \\
\"Administration Tools\" \\
\"System Management\" \\
\"System Administration Tools\" \\
\"C Development Tools and Libraries\" \\
\"Books and Guides\" \\
\"Development Tools\" \\
\"Editors\" \\
\"System Tools\""
sleep 2

yum groups install -y \
"Development Tools" \
"Security Tools" \
"Administration Tools" \
"System Management" \
"System Administration Tools" \
"C Development Tools and Libraries" \
"Books and Guides" \
"Development Tools" \
"Editors" \
"System Tools"

yum groups list installed | less

# Last update: 2/5/2019
