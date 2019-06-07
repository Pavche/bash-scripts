#!/usr/bin/env bash
HOST=${1:?"Error: host name not provided."}

echo spice://$HOST:6602
firefox spice://$HOST:6602
