#!/usr/bin/env bash
set -eo

auto_fix_hashes() {
  local tmpfile="$1"
  local fixed=false

  local output
  mapfile -t output < <(sed -n 's/^@nix //p' "$tmpfile" |
    jq -r '.msg?' |
    grep "hash mismatch in fixed-output derivation" -A 2 |
    grep -oE "sha256-[^=]+=")

  if [[ ${#output[@]} -eq 2 ]]; then
    echo "🔧 Hash mismatch detected:"
    echo "   old: ${output[0]}"
    echo "   new: ${output[1]}"

    local filepath
    filepath="$PWD/flake.nix"
    echo "$filepath"
    if [[ -f "$filepath" ]] && grep -qF "${output[0]}" "$filepath"; then
      sed -i "s|${output[0]}|${output[1]}|g" "$filepath"
      fixed=true
    fi
  fi

  $fixed
}

TMPOUT=$(mktemp)
err=1

while true; do
  if nix build --json --log-format internal-json 2>"$TMPOUT"; then
    BUILD_EXIT=0
  else
    BUILD_EXIT=$?
  fi

  if [[ $BUILD_EXIT -eq 0 ]]; then
    rm -f "$TMPOUT"
    break
  fi

  if auto_fix_hashes "$TMPOUT"; then
    echo "🔁 Hash patched — retrying..."
    rm -f "$TMPOUT"
    err=0
  else
    echo "⚠️  No fixable hashes found. Manual intervention needed."
    echo "$TMPOUT"
    err=1
    break
  fi
done

if [[ "$err" == 0 ]]; then
  rm -rf "$PWD/result"
  echo "hash is now valid"
fi

exit "$err"
