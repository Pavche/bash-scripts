#!/usr/bin/env bash

# Install nightly build of specific version of RHEL 8.1.
virt-install \
--name RHEL-8.1-Latest \
--memory 2048 \
--vcpus 2 \
--disk pool=VM,size=20 \
--network default \
--location http://download.eng.rdu2.redhat.com/rel-eng/latest-RHEL-8.1/compose/BaseOS/x86_64/os/ \
--os-variant rhel8.0 \
--initrd-inject /home/pgeorgie/VM/kickstart/RHEL8/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
