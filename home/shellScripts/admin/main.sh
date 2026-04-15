#!/usr/bin/env sh
# sudo_require.sh — source this file, then call: requiresSudo "$@"
#
# Usage in any script that needs root:
#
#   #!/usr/bin/env sh
#   # shellcheck source=./sudo_require.sh
#   . /usr/local/lib/sudo_require.sh
#   requiresSudo "$@"
#
# If not already root, the script transparently re-launches itself under sudo
# and exits. If already root, it returns immediately and execution continues.

# Resolve the absolute path of the calling script ($0), handling three cases:
#   /abs/path/script   → already absolute, use as-is
#   rel/path/script    → relative with directory, expand to absolute
#   bare-name          → looked up on PATH via `command -v`
_sudo_require_resolve_self() {
  case "$0" in
  /*)
    printf '%s' "$0"
    ;;
  */*)
    # shellcheck disable=SC2169  # realpath may not exist; use cd+pwd instead
    _srs_dir="$(cd "$(dirname "$0")" && pwd)" || return 1
    printf '%s/%s' "$_srs_dir" "$(basename "$0")"
    ;;
  *)
    # On PATH → use that; otherwise assume it's in $PWD
    command -v "$0" || printf '%s/%s' "$PWD" "$0"
    ;;
  esac
}

requiresSudo() {
  # Already root — nothing to do.
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi

  _sudo_require_script="$(_sudo_require_resolve_self)" || {
    printf 'requiresSudo: could not resolve script path\n' >&2
    exit 1
  }

  printf 'This script requires root. Re-running with sudo...\n' >&2
  exec sudo "$_sudo_require_script" "$@"
}
