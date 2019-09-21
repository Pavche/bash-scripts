#!/usr/bin/env bash

sudo virt-install \
--name rhel7 \
--memory 2048 \
--vcpus 2 \
--disk size=10 \
--network default \
--location /home/pgeorgie/VM/ISO/RHEL-7.6-20181010.0-Workstation-x86_64-dvd1.iso \
--os-variant rhel7 \
--initrd-inject /home/pgeorgie/VM/kickstart/rhel7/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
