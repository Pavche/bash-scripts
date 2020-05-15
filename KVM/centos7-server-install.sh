#!/usr/bin/env bash

virt-install \
--name CentOS-7-Server \
--memory 2048 \
--vcpus 2 \
--disk size=10 \
--network default \
--location http://ftp.fi.muni.cz/pub/linux/centos/7.6.1810/os/x86_64/ \
--os-variant centos7.0 \
--initrd-inject /home/pgeorgie/VM/kickstart/centos7-server/kickstart.cfg \
--extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8"
