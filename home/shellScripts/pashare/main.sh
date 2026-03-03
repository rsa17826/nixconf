#!/bin/bash

# shellcheck disable=SC2317
sudo -v || exit 1

PORT=1234
SINK_NAME="VirtualSink"
RATE=24000
TITLE="Audio Streamer"

# Function to clean up on exit or stop
cleanup() {
  echo "Cleaning up..."
  # Remove firewall rules
  sudo iptables -D INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null
  while sudo iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; do :; done

  # Kill processes and unload Pulse modules
  fuser -k "$PORT/tcp" 2>/dev/null
  pactl unload-module module-simple-protocol-tcp 2>/dev/null
  pactl unload-module module-null-sink 2>/dev/null

  notify-send -u low "$TITLE" "Stream stopped and ports cleaned."
}

# Trap signals like Ctrl+C (SIGINT) or Terminal Close (SIGHUP)
trap cleanup SIGINT SIGHUP SIGTERM

case "$1" in
start)
  # Ensure a clean slate
  cleanup 2>/dev/null
  sleep 1

  # 1. Create Virtual Sink
  echo "Creating Virtual Sink..."
  pactl load-module module-null-sink \
    sink_name="$SINK_NAME" \
    rate="$RATE" \
    channels=1 \
    sink_properties=device.description="Virtual_Sink"

  # 2. Start TCP Broadcast
  pactl load-module module-simple-protocol-tcp \
    rate="$RATE" \
    format=s16le \
    channels=1 \
    source="${SINK_NAME}.monitor" \
    record=true \
    port="$PORT" \
    record_buffer_size=512

  # 3. Move existing audio
  sleep 1
  mapfile -t inputs < <(pactl list sink-inputs short | cut -f1)
  for id in "${inputs[@]}"; do
    pactl move-sink-input "$id" "$SINK_NAME" 2>/dev/null
  done

  notify-send -u normal "$TITLE" "Server live. Waiting for connection on port $PORT..."
  echo "Waiting for the first connection to lock the IP..."

  # 4. Connection Monitoring Loop
  while true; do
    # ss -ntp lists numeric addresses and ports
    FIRST_IP=$(ss -ntp | grep ":$PORT" | grep "ESTAB" | awk '{print $5}' | cut -d: -f1 | head -n1)

    if [[ -n "$FIRST_IP" ]]; then
      # Apply Firewall Lock
      sudo iptables -I INPUT -p tcp -s "$FIRST_IP" --dport "$PORT" -j ACCEPT
      sudo iptables -A INPUT -p tcp --dport "$PORT" -j DROP

      echo "Locked to IP: $FIRST_IP"
      notify-send -u critical "$TITLE" "Locked to connection from: $FIRST_IP"
      exit 0
    fi
    sleep 1
  done
  ;;

stop)
  cleanup
  exit 0
  ;;

*)
  echo "Usage: $0 {start|stop}"
  exit 1
  ;;
esac
