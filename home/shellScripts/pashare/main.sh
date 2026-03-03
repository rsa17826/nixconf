#!/bin/bash

# Configuration
PORT=1234
SINK_NAME="VirtualSink"
RATE=24000

# Function to clean up on exit or stop
cleanup() {
  echo "Cleaning up..."
  # Remove firewall rules (using -D to delete)
  sudo iptables -D INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null
  # Loop to remove all specific ACCEPT rules for this port
  while sudo iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; do :; done

  # Kill processes and unload Pulse modules
  fuser -k "$PORT/tcp" 2>/dev/null
  pactl unload-module module-simple-protocol-tcp 2>/dev/null
  pactl unload-module module-null-sink 2>/dev/null
  echo "Done."
}

case "$1" in
start)
  # Ensure a clean slate
  cleanup
  sleep 1

  # 1. Create Virtual Sink
  echo "Creating Virtual Sink..."
  pactl load-module module-null-sink \
    sink_name="$SINK_NAME" \
    rate="$RATE" \
    channels=1 \
    sink_properties=device.description="Virtual_Sink"

  # 2. Start TCP Broadcast
  echo "Starting TCP Protocol on port $PORT..."
  pactl load-module module-simple-protocol-tcp \
    rate="$RATE" \
    format=s16le \
    channels=1 \
    source="${SINK_NAME}.monitor" \
    record=true \
    port="$PORT" \
    record_buffer_size=512

  # 3. Move existing audio streams to the sink
  sleep 1
  mapfile -t inputs < <(pactl list sink-inputs short | cut -f1)
  for id in "${inputs[@]}"; do
    pactl move-sink-input "$id" "$SINK_NAME" 2>/dev/null
  done

  echo "Waiting for the first connection to lock the IP..."

  # 4. Connection Monitoring Loop
  while true; do
    # Look for an established connection on our port
    # awk picks the 5th column (Remote Address)
    FIRST_IP=$(ss -ntp | grep ":$PORT" | grep "ESTAB" | awk '{print $5}' | cut -d: -f1 | head -n1)

    if [[ -n "$FIRST_IP" ]]; then
      echo "Locked to IP: $FIRST_IP"

      # Allow this specific IP
      sudo iptables -I INPUT -p tcp -s "$FIRST_IP" --dport "$PORT" -j ACCEPT
      # Drop all other traffic to this port
      sudo iptables -A INPUT -p tcp --dport "$PORT" -j DROP

      echo "Firewall rules applied. No other IPs can connect."
      break
    fi
    sleep 1
  done
  ;;

stop)
  cleanup
  ;;

*)
  echo "Usage: $0 {start|stop}"
  exit 1
  ;;
esac
