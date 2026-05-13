#!/usr/bin/env bash
set -e
EMPTY_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

sanitize_hashes() {
  local file="$1"
  # extract all sha256 hashes in file and replace them with the empty placeholder
  # This forces Nix to tell us the 'correct' hash for every single one
  mapfile -t hashes < <(grep -oE 'sha256-[A-Za-z0-9+/=]{43,44}' "$file" | sort -u)

  echo "found ${#hashes[@]} hashes, resetting to empty..."
  for h in "${hashes[@]}"; do
    sed -i "s|$h|$EMPTY_HASH|g" "$file"
  done
}

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
sanitize_hashes "$PWD/flake.nix"
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
