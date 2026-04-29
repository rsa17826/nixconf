#!/usr/bin/env bash
STATE_FILE="$HOME/.local/share/nix-update-target"
DEFAULT_TARGET="nyx"
mkdir -p "$(dirname "$STATE_FILE")"
if [ -n "${1:-}" ]; then
  TARGET="$1"
  echo "$TARGET" >"$STATE_FILE"
  echo "🎯 Target set to: $TARGET"
else
  if [ -f "$STATE_FILE" ]; then
    TARGET=$(cat "$STATE_FILE")
    echo "🔄 Using last target: $TARGET"
  else
    TARGET="$DEFAULT_TARGET"
    echo "🆕 Defaulting to: $TARGET"
  fi
fi
pushd "$HOME/nixconf" >/dev/null || {
  echo "❌ Could not find ~/nixconf"
  exit 1
}
sudo nixos-rebuild switch --rollback --flake ".#$TARGET"
