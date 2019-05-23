#!/usr/bin/env bash

# Install Jupyter Notebooks
cd $HOME

# Install prerequisites
if uname -r | grep -q "el7"; then
    # Install under RHEL7, CentOS7.
elif uname -r | grep -q "el8"; then
    # Install under RHEL8.
elif uname -r | grep -q -E "fc28|fc29|fc30"; then
    # Install under Fedora 28/29/30.
    sudo dnf groups install -y "Development Tools"
    sudo dnf install -y conda
    sudo dnf install -y git
    sudo dnf install -y python2-sphinx
fi

git clone https://github.com/jupyter/jupyter.git
git clone https://github.com/jupyter/notebook.git
git clone https://github.com/rajathkmp/Python-Lectures.git

pushd $HOME/jupyter/docs
# Create a conda environment
conda env create -f environment.yml
# Activate the environment
conda activate jupyter_docs
# Build the docs.
make clean  
make html
popd

# For more info see:
# https://github.com/jupyter/jupyter/blob/master/README.md

[test@F-30 docs]$ make html
Makefile:12: *** The 'sphinx-build' command was not found. Make sure you have Sphinx installed, then set the SPHINXBUILD environment variable to point to the full path of the 'sphinx-build' executable. Alternatively you can add the directory with the executable to your PATH. If you don't have Sphinx installed, grab it from http://sphinx-doc.org/.  Stop.
