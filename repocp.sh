#!/usr/bin/env bash

# Transfer a local repo to a remote machine.

REPO_FILE=${1:?'Error. Please, specify a repository file.'}
REMOTE_HOST=${2?:'Error. Please, provide a remote hostname'}

# Validate parameters.
if [ -f "$REPO_FILE" ]; then
  echo "Copy repo file \"$REPO_FILE\" to root@$REMOTE_HOST:/etc/yum.repos.d/"
  scp "$REPO_FILE" root@$REMOTE_HOST:/etc/yum.repos.d/
  if [ $? -eq 0 ]; then
    echo "Copied successfully. OK."
  else
    echo "Cannot copy the file. Failure." >&2
    exit 1
  fi
else
  echo "The file \"$REPO_FILE\" does not exist or read permission is denied." >&2
  exit 1
fi

