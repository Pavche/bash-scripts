#!/usr/bin/env bash

HOST=${1:?"Error: hostname not provided."}
PORT=${2:?"Error: port not provided."}

# Script is based on:
# Testing Secured Connections 
# https://access.redhat.com/articles/1504313

echo "Testing TLS settings"
echo
echo "Test for SSLv3 being disabled"
echo "SSL 3.0 is very weak and considered insecure. Your servers should not negotiate this protocol. You should not see a valid connection, with key exchange, when you perform this test."
sleep 3
openssl s_client -connect $HOST:$PORT -ssl3

echo
echo "Test for TLSv1.2 being enabled"
echo "TLS 1.2 is the strongest TLS protocol available and is considered secure. Your servers should negotiate this protocol. You should see a valid connection, with key exchange, when you perform this test."
sleep 3
openssl s_client -connect $HOST:$PORT -tls1_2

