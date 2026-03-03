#!/bin/bash

PORT=1234
SINK_NAME="VirtualSink"
TITLE="Audio Streamer"

# This function handles the firewall and must run as root
apply_firewall() {
  local target_ip=$1
  iptables -I INPUT -p tcp -s "$target_ip" --dport "$PORT" -j ACCEPT
  iptables -A INPUT -p tcp --dport "$PORT" -j DROP
}

cleanup_firewall() {
  iptables -D INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null
  while iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; do :; done
}

# --- MAIN LOGIC ---
case "$1" in
start)
  # 1. PulseAudio (Runs as USER)
  pactl load-module module-null-sink sink_name="$SINK_NAME" ... # (other params)
  pactl load-module module-simple-protocol-tcp port="$PORT" ... # (other params)

  notify-send "$TITLE" "Waiting for connection..."

  # 2. Wait for IP (Runs as USER)
  while true; do
    FIRST_IP=$(ss -ntp | grep ":$PORT" | grep "ESTAB" | awk '{print $5}' | cut -d: -f1 | head -n1)
    if [[ -n "$FIRST_IP" ]]; then
      # 3. ELEVATE ONLY THE FIREWALL COMMANDS
      # We call the script itself with a hidden flag
      sudo "$0" --internal-firewall "$FIRST_IP"

      notify-send -u critical "$TITLE" "Locked to $FIRST_IP"
      break
    fi
    sleep 1
  done
  ;;

--internal-firewall)
  # This block runs as ROOT via the sudo rule
  apply_firewall "$2"
  ;;

stop)
  # Clean up firewall via sudo
  sudo "$0" --internal-cleanup
  pactl unload-module ...
  ;;

--internal-cleanup)
  cleanup_firewall
  ;;
esac
