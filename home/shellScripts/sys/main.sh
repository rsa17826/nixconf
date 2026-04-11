#!/usr/bin/env bash

COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

msg() { echo -e "${COLOR_BLUE}➜ $1${COLOR_RESET}"; }

find_service() {
  local query="$1"
  systemctl list-units --type=service --all --no-legend |
    awk '{print $1}' | grep -i "$query" | head -n 1
}

get_service() {
  local input="$1"

  [[ "$input" == *.service ]] && echo "$input" && return

  local found
  found=$(find_service "$input")

  [[ -n "$found" ]] && echo "$found" || echo "${input}.service"
}

usage() {
  echo "Usage:"
  echo "  sys log <service> [-f] [-n lines]"
  echo "  sys status <service>"
  echo "  sys restart <service>"
  echo "  sys stop <service>"
  echo "  sys start <service>"
  exit 1
}

if [[ ! "$1" =~ ^(log|status|restart|stop|start)$ ]]; then
  set -- log "$@"
fi

cmd="$1"
shift || true

case "$cmd" in
status | restart | stop | start)
  service="$1"
  [[ -z "$service" ]] && usage

  sys=$(get_service "$service")
  msg "$cmd $sys"

  if [[ "$cmd" == "status" ]]; then
    systemctl status "$sys" --no-pager --lines=0
  else
    systemctl status "$sys" --no-pager --lines=0
    systemctl "$cmd" "$sys"
  fi
  ;;

log)
  follow=()
  lines=()
  service=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -f)
      follow=(-f)
      shift
      ;;
    -n)
      shift
      lines=(-n "$1")
      shift
      ;;
    *)
      service="$1"
      shift
      ;;
    esac
  done

  [[ -z "$service" ]] && usage

  sys=$(get_service "$service")

  args=(-u "$sys")
  args+=("${follow[@]}")

  # default lines if not set
  if [[ ${#lines[@]} -eq 0 ]]; then
    args+=(-n 100)
  else
    args+=("${lines[@]}")
  fi

  if [[ ${#follow[@]} -eq 0 ]]; then
    journalctl "${args[@]}" --no-pager -r
  else
    journalctl "${args[@]}" --no-pager
  fi
  systemctl status "$sys" --no-pager --lines=0
  ;;

esac
