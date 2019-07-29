#!/usr/bin/env bash

# Install nightly build of specific version of RHEL 7.7.
virt-install \
--name RHEL-7.7-Workstation-Latest \
--memory 2048 \
--vcpus 2 \
--disk pool=VM,size=20 \
--network default \
--location http://10.10.160.20/rel-eng/latest-RHEL-7.7/compose/Workstation/x86_64/os/ \
--os-variant rhel7 \
--initrd-inject /home/pgeorgie/VM/kickstart/RHEL7/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
