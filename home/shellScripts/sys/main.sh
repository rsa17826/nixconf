#!/usr/bin/env bash

COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

msg() { echo -e "${COLOR_BLUE}➜ $1${COLOR_RESET}"; }

# Returns "system:name.service" or "user:name.service"
find_service() {
  local query="$1"
  local found

  found=$(systemctl list-units --type=service --all --no-legend 2>/dev/null |
    awk '{print $1}' | grep -i "$query" | head -n 1)
  if [[ -n "$found" ]]; then
    echo "system:$found"
    return
  fi

  found=$(systemctl --user list-units --type=service --all --no-legend 2>/dev/null |
    awk '{print $1}' | grep -i "$query" | head -n 1)
  if [[ -n "$found" ]]; then
    echo "user:$found"
    return
  fi
}

# Sets globals: SERVICE (name) and SCOPE_FLAG (empty or "--user")
resolve_service() {
  local input="$1"
  local name="$input"
  [[ "$name" != *.service ]] && name="${name}.service"

  local found
  found=$(find_service "$input")

  if [[ -n "$found" ]]; then
    local scope="${found%%:*}"
    SERVICE="${found##*:}"
    [[ "$scope" == "user" ]] && SCOPE_FLAG="--user" || SCOPE_FLAG=""
  else
    SERVICE="$name"
    SCOPE_FLAG=""
  fi
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
  [[ -z "$1" ]] && usage
  resolve_service "$1"

  local_flag="${SCOPE_FLAG:+ (user)}"
  msg "$cmd $SERVICE${local_flag}"

  if [[ "$cmd" == "status" ]]; then
    systemctl "$SCOPE_FLAG" status "$SERVICE" --no-pager --lines=0
  else
    systemctl "$SCOPE_FLAG" status "$SERVICE" --no-pager --lines=0
    systemctl "$SCOPE_FLAG" "$cmd" "$SERVICE"
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
  resolve_service "$service"

  args=("$SCOPE_FLAG" -u "$SERVICE")
  args+=("${follow[@]}")

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

  systemctl "$SCOPE_FLAG" status "$SERVICE" --no-pager --lines=0
  ;;
esac
