#!/usr/bin/env bash
set -e

sanitize_hashes() {
  local file="$1"

  awk '
    function gen(i,    s, n) {
      s = ""
      n = i
      do {
        s = sprintf("%c", 65 + (n % 26)) s
        n = int(n / 26) - 1
      } while (n >= 0)

      while (length(s) < 43) {
        s = s "A"
      }
      return "sha256-" s "="
    }

    {
      # Fixed regex: Added a-z, 0-9, and / to cover standard Base64
      n = split($0, parts, /sha256-[A-Za-z0-9\/+=]{43,44}/, seps)

      out = parts[1]
      for (i = 2; i <= n; i++) {
        h = seps[i-1]
        if (h != "" && !(h in map)) {
          map[h] = gen(idx++)
        }
        if (h != "") {
          out = out map[h]
        }
        out = out parts[i]
      }
      print out
    }
  ' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
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
if [ -f "$PWD/flake.nix" ]; then
  git add flake.nix
  lastText=$(<"$PWD/flake.nix")

  TMPOUT=$(mktemp)
  err=1
  go mod tidy
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

  if [[ -d "$PWD/result" ]]; then
    rm -rf "$PWD/result"
  fi
  if [[ "$err" == 0 ]]; then
    echo "hash is now valid"

    newText=$(<"$PWD/flake.nix")
    if [[ "$newText" != "$lastText" ]]; then
      DONT_UPDATE_GO_LIBS=1 push fixed the hashes
    fi
  fi
  exit "$err"
else
  exit 0
fi
