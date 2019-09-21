#!/usr/bin/env bash

DISTRO_NAME=${1:?"Error: distrition name is missing. Example: RHEL-8.0-Snapshot-1.0, RHEL-8.1.0-InternalSnapshot-2.1."}

# Choose localtion from Release Engineering
# Example
# RHEL-8.0-Snapshot-1.0
# RHEL-8.1.0-InternalSnapshot-2.1

virt-install \
--name rhel8.1 \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--os-variant rhel8.0 \
--location http://download-ipv4.eng.brq.redhat.com/rel-eng/$DISTRO_NAME/compose/BaseOS/x86_64/os/

# Create a kickstart from this?

# http://download-ipv4.eng.brq.redhat.com/rel-eng/$DISTRO_NAME/
# repo --name=repoid [--baseurl=<url>|--mirrorlist=url] [options]