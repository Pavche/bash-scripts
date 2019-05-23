#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
    echo "Root priviledges are needed to run this script." >&2
    exit 1
fi

function install_jupyter() {
    python3 -m pip install --upgrade pip \
    && python3 -m pip install jupyterhub \
    && python3 -m pip install notebook \
    && npm install -g configurable-http-proxy
}

# Install JupyterHub
if uname -r | grep -q "el7"; then
    # Install under RHEL7, CentOS7.
    yum install -y python36 python36-pip \
    && yum -y install npm nodejs \
    && install_jupyter
elif uname -r | grep -q "el8"; then
    # Install under RHEL8.
    yum -y install npm nodejs \
    && install_jupyter
elif uname -r | grep -q -E "fc28|fc29|fc30"; then
    # Install under Fedora 28/29/30.
    dnf install -y npm nodejs \
    && install_jupyter
fi

# Check results
if which jupyterhub; then
    echo "OK"
else
    echo "Failed to install JupyterHub." >&2
    exit 1
fi
