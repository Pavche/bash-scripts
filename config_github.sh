#!/usr/bin/env bash
# This scripts configures git repo for uploading/downloading
# bash and python scripts

git config user.name "Pavlin Georgiev"
git config user.name "pavlin@varna.net"
git config push.default simple
git config diff.tool vimdiff

# Verify your git configuration
git config --list

# Author: Pavlin Georgiev
# Created on: 23 Jan 2016
# Last update: 18 Dec 2018
