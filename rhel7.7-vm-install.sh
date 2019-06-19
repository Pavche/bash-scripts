#!/usr/bin/env bash

# Install nightly build of specific version of RHEL 7.7.
virt-install \
--name RHEL-7.7-Workstation \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--location http://download.eng.brq.redhat.com/pub/rhel/rel-eng/RHEL-7.7-20190612.0/compose/Workstation/$(arch)/os/ \
--os-variant rhel7 \
--initrd-inject /home/pgeorgie/VM/kickstart/rhel7.7/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
