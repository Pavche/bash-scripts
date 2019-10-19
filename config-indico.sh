#!/usr/bin/env bash

# Configure indico server.
# MUST be logged as user indico.

# Install Indico.
virtualenv ~/.venv
source ~/.venv/bin/activate
pip install -U pip setuptools
pip install indico

# 6. Configure Indico
indico setup wizard

if [ $? -eq 0 ]; then
  echo "Indico has been installed."
  sleep 3
else
  echo "Failed to install Indico." >&2
  sleep 3
  exit 1
fi

# Set the directory structure and permissions.
mkdir ~/log/apache
chmod go-rwx ~/* ~/.[^.]*
chmod 710 ~/ ~/archive ~/cache ~/log ~/tmp
chmod 750 ~/web ~/.venv
chmod g+w ~/log/apache
echo -e "\nSTATIC_FILE_METHOD = 'xsendfile'" >> ~/etc/indico.conf

# 7. Create database schema
indico db prepare && exit 0 || exit 1

