#!/usr/bin/env bash

virt-install \
--name Fedora-30-Workstation \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--location http://download-ipv4.eng.brq.redhat.com/pub/fedora/linux/releases/latest-30/Workstation/x86_64/os/ \
--os-variant fedora29 \
--initrd-inject /home/pgeorgie/VM/kickstart/fedora30-workstation/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
