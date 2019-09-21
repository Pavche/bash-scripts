#!/usr/bin/env bash

# Test log generation.
# Test *.log and *.html generation during and after automated tests.

# Prerequisites
[ -z $TEST ] && exit 1
[ -x runtest.sh ] || exit 1
 
# Delete logs
rm -f /tmp/*.{log,html}

# run the test from root
./runtest.sh $TEST

# Collect logs
tar czvf $HOME/${TEST}_logs.tar.gz /tmp/*.log /tmp/*.html; RC=$?

# Upload logs
[ $RC -eq 0 ] && scp $HOME/${TEST}_logs.tar.gz $RAMP/; RC=$?

# Delete TAR
[ $RC -eq 0 ] && rm -f $HOME/${TEST}_logs.tar.gz