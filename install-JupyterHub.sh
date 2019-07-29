#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
    echo "Root priviledges are needed to run this script." >&2
    exit 1
fi

function install_tools () {
    # Install Advanced IP routing and network device
    # configuration tools.
    yum install -y net-tools iproute
    yum install -y git wget
}

function install_jupyter() {
    python3 -m pip install --upgrade pip \
    && python3 -m pip install jupyterhub \
    && python3 -m pip install notebook \
    && npm install -g configurable-http-proxy
}


# Install JupyterHub
if uname -r | grep -q "el7"; then
    # Install under RHEL7, CentOS7.
    # Define EPEL7 repo need for Python3.
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum install -y python36 python36-pip \
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

# Tools for network management.
install_tools


# On which network ports does JupyterHub work?
# TCP 8001, TCP 8081
# On which network ports does JupyterNotebook work?

# But if I start jupyter notebook with jupyter notebook --ip 127.0.0.1 it works. In the same way, if I start the docker image with docker run -it --rm -p 8888:8888 my_docker_image jupyter notebook --ip 127.0.0.1 it works also.