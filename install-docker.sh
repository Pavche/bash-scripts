#!/usr/bin/env bash

# Install Docker for managing containers.

[ -f /etc/redhat-release ] && cat /etc/redhat-release

if $(uname -r) | grep -w -q 'el7'; then
    if cat /etc/redhat-release | grep -w -q 'CentOS'; then
        # Install Docker Community Edition under CentOS7.
        sudo yum -y remove docker docker-common docker-selinux docker-engine
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum -y install docker-ce
    else
        # install Red Hat docker.
        sudo yum -y install docker
    fi    
elif $(uname -r) | grep -w -q 'el8'; then
    sudo yum -y install docker
    # TODO: HOW TO RUN THE SERVICE UNDER RHEL8?
elif $(uname -r) | grep -w -q 'fc30'; then
    echo Fedora 30
    sudo dnf -y install docker
else
    echo "Unsupported distribution." >&2
    exit 1
fi

sudo systemctl enable docker.service
sudo systemctl start docker.service

# How to find out info about Docker network bridge and IP addresses?
# Default network bridge named as docker0 and is assigned with an IP address. 
ip a show docker0

# Get system-wide information about Docker
sudo docker info


# Created on: 23 May 2019
# Last modificated on: 24 May 2019
