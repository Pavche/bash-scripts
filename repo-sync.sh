#!/usr/bin/env bash

# Define stable,  easy to use, with instant access RHEL repository.
# Intended for software testing on VM or physical machines.

# Define variables taken from command-line arguments of this script.
REPOID=${1:-'rhel-7.5'}
CACHEDIR=${2:-'/tmp'}
DESTDIR=${3:-'/mnt/local-repo'}

# Prepare conditions. Create directories. Satisfy packages dependencies.
# REPOID should be an existing repository (already defined on the host).

# Validate parameters.
# TODO

[ -d "$DESTDIR" ] || mkdir -p "$DESTDIR"

# Synchronize repository.
reposync \
  --repoid=$REPOID \
  --cachedir "$CACHEDIR" \
  --download_path="$DESTDIR" \
  --delete \
  --plugins
RC=$?

# Return results.
if [ $RC -eq 0 ]; then
    echo "Completed with success."
else
    echo "Failed to synchronize repo \"$REPOID\"" >&2
    exit $RC
fi

sleep 2

echo "Build a local repository which contains the packages already downloaded."
sleep 3
createrepo -v "$DESTDIR/$REPOID"
RC=$?
if []; then
    echo "Completed with success."
else
    echo "Failed to create local repository from downloaded packages." >&2
    exit $RC
fi


# Define a local repository on the host.
# If you want to have non-working repo then insert leading spaces bellow.
(
cat << EOF
[$REPOID-local]
name=$REPOID - local
baseurl=file://$DESTDIR/$REPOID
enabled=1
gpgcheck=0
EOF
) > /etc/yum.repos.d/"$REPOID"-local.repo

yum clean all
rm -rf /var/cache/yum
yum makecache

clear
echo "The new local repository is ready to use."
sleep 2

# Check the result from repo definition.
yum repolist

echo "To disable the original remote repository \"$REPOID\":"
echo "yum-config-manager --disablerepo=$REPOID"

# TODO: Create VDISK available to multiple VM (KVM based).
# It will contain the repository with packages.

# Author: Pavlin Georgiev
# Created on: 5 May 2018
# Last updated on: 5 May 2018