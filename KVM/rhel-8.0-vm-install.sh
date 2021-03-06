#!/usr/bin/env bash

# Install nightly build of specific version of RHEL 8.1.
sudo virt-install \
--name RHEL-8.1 \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--location http://download.eng.rdu2.redhat.com/rel-eng/latest-RHEL-8.1/compose/BaseOS/x86_64/os/ \
--os-variant rhel7 \
--initrd-inject /home/pgeorgie/VM/kickstart/rhel8.1/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
