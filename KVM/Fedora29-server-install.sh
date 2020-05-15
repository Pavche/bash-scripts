#!/usr/bin/env bash

virt-install \
--name Fedora-29-Server \
--memory 2048 \
--vcpus 2 \
--disk size=20 \
--network default \
--location http://ftp.fi.muni.cz/pub/linux/fedora/linux/releases/29/Server/x86_64/os/ \
--os-variant fedora29 \
--initrd-inject /home/pgeorgie/VM/kickstart/fedora29-server/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
