#!/usr/bin/env bash

yum -y groups install\
  "Server with GUI"\
  "Minimal Install"\
  "Basic Web Server"\
  "File and Print Server"\
  "Infrastructure Server"\
  "Compute Node"\
  "Virtualization Host"\
  "GNOME Desktop"\
  "KDE Plasma Workspaces"\
  "Development and Creative Workstation"\
  "Compatibility Libraries"\
  "Console Internet Tools"\
  "Development Tools"\
  "Graphical Administration Tools"\
  "Legacy UNIX Compatibility"\
  "Scientific Support"\
  "Security Tools"\
  "Smart Card Support"\
  "System Administration Tools"\
  "System Management"
