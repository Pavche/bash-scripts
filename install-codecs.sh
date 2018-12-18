#!/usr/bin/env bash

# Install audio and video codecs for VLC player

# Prerequisites
CODEC_LIST=$HOME/vlc-codecs.txt
LOG_FILE=$HOME/codec_install.log
ERROR_LOG=$HOME/codec_error.log

[[ -f "$CODEC_LIST" ]] || exit 1
[[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"
[[ -f "$ERROR_LOG" ]] && rm -f "$ERROR_LOG"


# Install the codecs one by one
for codec in $(<"$CODEC_LIST"); do
    echo -n "Trying to install $codec ... " >> "$LOG_FILE"
    sudo yum install -y $codec > /dev/null 2>>"$ERROR_LOG"; RC=$?
    if [[ $RC -eq 0 ]]; then
        echo "OK" >> "$LOG_FILE"
    else
        echo "Failure" >> "$LOG_FILE"
    fi
done

# Results
clear
less "$LOG_FILE"

