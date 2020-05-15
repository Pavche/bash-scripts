#!/usr/bin/env bash

# Install nightly build of specific version of RHEL 7.5 Server.
virt-install \
--name RHEL-7.5-Server \
--memory 2048 \
--vcpus 2 \
--disk pool=VM,size=20 \
--network default \
--location http://download-ipv4.eng.brq.redhat.com/released/rhel-7/RHEL-7/7.5/Server/x86_64/os/ \
--os-variant rhel7