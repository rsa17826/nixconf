#!/usr/bin/env bash
# Only touches rules for the one port, nothing else.
set -eu
PORT=1234

case "${1:-}" in
lock)
  ip="${2:?ip required}"
  # strict IPv4 validation so the argument can't be abused
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || {
    echo "bad ip" >&2
    exit 1
  }
  iptables -I INPUT -p tcp -s "$ip" --dport "$PORT" -j ACCEPT
  iptables -A INPUT -p tcp --dport "$PORT" -j DROP
  ;;
clear)
  iptables -D INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null || true
  while iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; do :; done
  ;;
*)
  echo "usage: $0 {lock <ip>|clear}" >&2
  exit 1
  ;;
esac
