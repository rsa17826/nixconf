#!/usr/bin/env bash
# urlhandler - register and handle arbitrary custom URL protocols on Linux
# (Wayland-friendly, uses xdg-mime under the hood).
#
# Usage:
#   ./urlhandler register <scheme> '<command>'
#       Register <scheme>:// to run <command>, using the current working
#       directory (at the time of registration) as the launch cwd.
#       Example: ./urlhandler register mb 'wine game.exe'
#
#   ./urlhandler run <url>
#       (internal) invoked by the desktop when a <scheme>:// link is opened.
#       Not meant to be run by hand.
#
# Once registered, opening a link like:
#   mb://game?connect=example.com:27015&name=Alice&password=hunter2
# cds into the directory that was current at registration time and runs the
# registered command, with the URL broken out into environment variables,
# prefixed with the uppercased scheme name:
#   <SCHEME>_URL      - the full url as opened
#   <SCHEME>_PATH     - the part between scheme:// and the first '?'
#   <SCHEME>_<KEY>    - one per query param, uppercased (e.g. MB_NAME)
#   <SCHEME>_HOST     - if a "connect=host:port" style param was present
#   <SCHEME>_PORT     - if a "connect=host:port" style param was present
#
# Any scheme, any params - nothing here is specific to "mb" or to
# connect/name/password. The registered command is responsible for reading
# these env vars itself (via a wrapper/mod/launch script) and acting on them.

set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
BASE_DIR="$HOME/.local/share/urlhandler"
DESKTOP_DIR="$HOME/.local/share/applications"

usage() {
  cat >&2 <<EOF
Usage:
  $0 register <scheme> '<command>'
  $0 run <scheme://url>
EOF
  exit 1
}

validate_scheme() {
  local scheme="$1"
  if [[ ! "$scheme" =~ ^[a-z][a-z0-9+.-]*$ ]]; then
    echo "ERROR: invalid scheme '$scheme' (must match [a-z][a-z0-9+.-]*)" >&2
    exit 1
  fi
}

url_decode() {
  local data="${1//+/ }"
  printf '%b' "${data//%/\\x}"
}

# xdg-mime writes into $XDG_CONFIG_HOME/mimeapps.list, which on NixOS/home-manager
# is often a symlink into the read-only nix store. When that's the case, set the
# default ourselves in $XDG_DATA_HOME/applications/mimeapps.list instead - that
# file is checked as a fallback by every spec-compliant resolver and isn't
# managed by home-manager, so it's actually writable.
set_default_fallback() {
  local scheme="$1" desktop="$2"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local mimeapps="$data_home/applications/mimeapps.list"
  local mimetype="x-scheme-handler/$scheme"

  mkdir -p "$(dirname "$mimeapps")"

  local tmp
  tmp="$(mktemp)"

  if [ -f "$mimeapps" ]; then
    awk -v mt="$mimetype" -v df="$desktop" '
      BEGIN { insec=0; done=0; mtline=mt"=" }
      /^\[Default Applications\]/ { insec=1; print; next }
      /^\[/ {
        if (insec && !done) { print mt"="df; done=1 }
        insec=0
        print
        next
      }
      {
        if (insec && substr($0,1,length(mtline))==mtline) {
          print mt"="df
          done=1
          next
        }
        print
      }
      END { if (insec && !done) print mt"="df }
    ' "$mimeapps" >"$tmp"

    if ! grep -q '^\[Default Applications\]' "$tmp"; then
      printf '\n[Default Applications]\n%s=%s\n' "$mimetype" "$desktop" >>"$tmp"
    fi
  else
    printf '[Default Applications]\n%s=%s\n' "$mimetype" "$desktop" >"$tmp"
  fi

  mv "$tmp" "$mimeapps"
}

register() {
  local scheme="${1:-}"
  local cmd="${2:-}"

  if [ -z "$scheme" ]; then
    echo "ERROR: no scheme given. Usage: $0 register <scheme> '<command>'" >&2
    exit 1
  fi
  if [ -z "$cmd" ]; then
    echo "ERROR: no command given. Usage: $0 register <scheme> '<command>'" >&2
    exit 1
  fi
  validate_scheme "$scheme"

  local config_dir="$BASE_DIR/$scheme"
  local config_file="$config_dir/config"
  local desktop_file="$DESKTOP_DIR/urlhandler-$scheme.desktop"

  mkdir -p "$config_dir" "$DESKTOP_DIR"

  {
    printf 'CWD=%q\n' "$PWD"
    printf 'CMD=%q\n' "$cmd"
  } >"$config_file"

  cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=urlhandler-$scheme
Exec=$SCRIPT_PATH run %u
Terminal=false
Categories=Network;
MimeType=x-scheme-handler/$scheme;
EOF

  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

  if xdg-mime default "urlhandler-$scheme.desktop" "x-scheme-handler/$scheme" 2>/tmp/urlhandler-xdg-mime.err; then
    :
  else
    echo "NOTE: xdg-mime default failed (likely a read-only ~/.config/mimeapps.list, e.g. NixOS/home-manager):" >&2
    cat /tmp/urlhandler-xdg-mime.err >&2
    echo "Falling back to writing the default directly into \$XDG_DATA_HOME/applications/mimeapps.list" >&2
    set_default_fallback "$scheme" "urlhandler-$scheme.desktop"
  fi
  rm -f /tmp/urlhandler-xdg-mime.err

  echo "Registered $scheme:// -> (cwd: $PWD) $cmd"
}

run() {
  local url="${1:-}"
  if [ -z "$url" ]; then
    echo "ERROR: no url given to run" >&2
    exit 1
  fi
  if [[ "$url" != *"://"* ]]; then
    echo "ERROR: '$url' is not a scheme://... url" >&2
    exit 1
  fi

  local scheme="${url%%://*}"
  validate_scheme "$scheme"

  local config_file="$BASE_DIR/$scheme/config"
  if [ ! -f "$config_file" ]; then
    echo "ERROR: '$scheme://' is not registered yet. Run '$0 register $scheme <command>' first." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$config_file"

  if [ -z "${CWD:-}" ]; then
    echo "ERROR: $config_file is missing CWD" >&2
    exit 1
  fi
  if [ ! -d "$CWD" ]; then
    echo "ERROR: registered working directory no longer exists: $CWD" >&2
    exit 1
  fi

  local prefix
  prefix="$(echo "$scheme" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9' '_')"

  local rest="${url#*://}"
  local path="${rest%%\?*}"
  local query=""
  if [[ "$rest" == *"?"* ]]; then
    query="${rest#*?}"
  fi

  export "${prefix}_URL=$url"
  export "${prefix}_PATH=$(url_decode "$path")"

  if [ -n "$query" ]; then
    local IFS='&'
    local pair key val envkey
    for pair in $query; do
      [ -n "$pair" ] || continue
      key="${pair%%=*}"
      val="${pair#*=}"
      key="$(url_decode "$key")"
      val="$(url_decode "$val")"
      envkey="${prefix}_$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')"
      export "$envkey=$val"
    done
  fi

  local connect_var="${prefix}_CONNECT"
  if [ -n "${!connect_var:-}" ]; then
    local connect_val="${!connect_var}"
    if [[ "$connect_val" != *:* ]]; then
      echo "ERROR: connect param must be host:port, got '$connect_val'" >&2
      exit 1
    fi
    export "${prefix}_HOST=${connect_val%%:*}"
    export "${prefix}_PORT=${connect_val#*:}"
  fi

  cd "$CWD"
  exec bash -c "$CMD"
}

case "${1:-}" in
register)
  shift
  register "${1:-}" "${2:-}"
  ;;
run)
  shift
  run "${1:-}"
  ;;
*)
  usage
  ;;
esac
