#!/usr/bin/env bash

# Repeat 1 and same test 100 times.
# Stop on failure.
# Collect messages from the system journal.
N=100
JOURNAL_FILE="journal_$(hostname --short).log"
JOURNAL_NM_FILE="journal_$(hostname --short)_NetworkManager.log"
JOURNAL_WPA_FILE="journal_$(hostname --short)_wpa-supplicant.log"
CONNECTION="qe-wep-enterprise"


function get_certificates () {
    [ -d /tmp/certs ] || mkdir /tmp/certs
    wget -O /tmp/certs/eaptest_ca_cert.pem \
      http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem
    wget -O /tmp/certs/client.pem \
      http://wlan-lab.eng.bos.redhat.com/certs/client.pem
}


function check_prerequisites () {
  if ! [ -r /tmp/certs/eaptest_ca_cert.pem -a -r /tmp/certs/client.pem ]; then
    get_certificates
  fi

  if ! [ -r /tmp/certs/eaptest_ca_cert.pem -a -r /tmp/certs/client.pem ]; then
    echo "Problem downloading certificates." >&2
    return 1
  fi
}


function create_wpa1_tls () {
  # Create a new Wi-Fi connection
  # by using 802.1x and WPA authentication
  # and EAP=TLS and security certificates.
  local CON_NAME=${1:?"Error: connection name is missing."}

  nmcli con add \
  con-name $CON_NAME \
  ifname wlan0 \
  autoconnect off \
  type wifi \
  ssid qe-wpa1-enterprise \
  802-11-wireless-security.key-mgmt wpa-eap\
  802-1x.eap tls \
  802-1x.identity "Bill Smith" \
  802-1x.ca-cert "file:///tmp/certs/eaptest_ca_cert.pem" \
  802-1x.client-cert "file:///tmp/certs/client.pem" \
  802-1x.private-key "file:///tmp/certs/client.pem" \
  802-1x.private-key-password "12345testing"
}


function create_wpa2_tls () {
  # Create a new Wi-Fi connection
  # by using 802.1x and WPA authentication
  # and EAP=TLS and security certificates.
  local CON_NAME=${1:?"Error: connection name is missing."}

  nmcli con add \
  con-name $CON_NAME \
  ifname wlan0 \
  autoconnect off \
  type wifi \
  ssid qe-wpa2-enterprise \
  802-11-wireless-security.key-mgmt wpa-eap\
  802-1x.eap tls \
  802-1x.identity "Bill Smith" \
  802-1x.ca-cert "file:///tmp/certs/eaptest_ca_cert.pem" \
  802-1x.client-cert "file:///tmp/certs/client.pem" \
  802-1x.private-key "file:///tmp/certs/client.pem" \
  802-1x.private-key-password "12345testing"
}


function create_wep_tls () {
  # Create a new Wi-Fi connection
  # by using 802.1x and WEP authentication
  # and EAP=TLS and security certificates.
  local CON_NAME=${1:?"Error: connection name is missing."}

  nmcli con add \
  con-name $CON_NAME \
  ifname wlan0 \
  autoconnect off \
  type wifi \
  ssid qe-wep-enterprise \
  802-11-wireless-security.key-mgmt ieee8021x \
  802-1x.eap tls \
  802-1x.identity "Bill Smith" \
  802-1x.ca-cert "file:///tmp/certs/eaptest_ca_cert.pem" \
  802-1x.client-cert "file:///tmp/certs/client.pem" \
  802-1x.private-key "file:///tmp/certs/client.pem" \
  802-1x.private-key-password "12345testing"
}


function does_exist() {
  # Check if a connection exists
  # by using nmcli.
  local CON_NAME=${1:?"Error: connection name is missing."}

  if nmcli --terse -f NAME,TYPE con show | grep -woq 802-11-wireless; then
    echo "Connection \"$CON_NAME\" checked. OK."
    return 0
  else
    echo "Connection \"$CON_NAME\" missing." >&2
    return 1
  fi
}


function is_active() {
  # Check if a connection is active
  # by using nmcli.
  local CON_NAME=${1:?"Error: connection name is missing."}

  if nmcli --terse -f NAME,TYPE con show --active | grep -woq 802-11-wireless; then
    echo "Connection \"$CON_NAME\" activated. OK."
    return 0
  else
    echo "Error: Connection \"$CON_NAME\" not active." >&2
    return 1
  fi
}


function get_journal_cursor () {
  journalctl --show-cursor | tail -n1 | cut  -d":" -f2-
}


function collect_journal () {
  [ -z "$CURSOR" ] && return 1
  [ -z "$JOURNAL_FILE" ] && return 2
  [ -z "$JOURNAL_NM_FILE" ] && return 4

  journalctl --after-cursor $CURSOR > "$JOURNAL_FILE"
  journalctl -u NetworkManager -o cat --after-cursor $CURSOR > "$JOURNAL_NM_FILE"
  echo "See system journal: $JOURNAL_FILE"
  echo "See messages from NetworkManager: $JOURNAL_NM_FILE"
  nmcli general logging level INFO
}

check_prerequisites || exit 1

for i in $(seq 1 1 $N); do
  # Remember the positions of the last entry in the journal.
  CURSOR=$(get_journal_cursor)

  length=43
  printf -v line '%*s' "$length"
  echo ${line// /-}
  printf "| %-39s |\n" "Start iterration: $i"
  echo ${line// /-}

  nmcli general logging level TRACE domains ALL

  create_wep_tls "$CONNECTION"
  if ! does_exist "$CONNECTION"; then
    echo "GAME OVER"
    collect_journal
    exit 1
  fi

  # Activate connection.
  nmcli con up "$CONNECTION"

  echo "Wait 10 sec."
  sleep 10

  if is_active "$CONNECTION"; then
    echo "Test PASSED. OK."
  else
    echo "GAME OVER"
    nmcli con del "$CONNECTION"
    collect_journal
    exit 1
  fi

  nmcli con del "$CONNECTION"

  echo "Wait 10 sec."
  sleep 10
done

nmcli general logging level INFO

# For more information about troubleshooting NetworkManager, see:
# https://cgit.freedesktop.org/NetworkManager/NetworkManager/tree/contrib/fedora/rpm/NetworkManager.conf