#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cacert curl jq unzip python3
# shellcheck shell=bash
set -eu -o pipefail

function fail() {
  echo "$1" >&2
  exit 1
}

function clean_up() {
  echo -e "\nCleaning up..." >&2
  TDIR="${TMPDIR:-/tmp}"
  rm -Rf "$TDIR/vscode_exts_*"
  exit 1
}

trap clean_up SIGINT SIGTERM

function get_vsixpkg() {
  local PUBLISHER="$1"
  local NAME="$2"

  EXTTMP=$(mktemp -d -t vscode_exts_XXXXXXXX)
  URL="https://$PUBLISHER.gallery.vsassets.io/_apis/public/gallery/publisher/$PUBLISHER/extension/$NAME/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

  if ! curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/pkg.zip" "$URL"; then
    rm -Rf "$EXTTMP"
    return 1
  fi

  VER=$(jq -r '.version' <(unzip -qc "$EXTTMP/$N.zip" "extension/package.json"))
  # Calculate the hash
  HASH=$(nix-hash --flat --sri --type sha256 "$EXTTMP/$N.zip")
  rm -Rf "$EXTTMP"

  echo "$VER|$HASH"
}

function update_nix_file() {
  local PUBLISHER="$1"
  local NAME="$2"
  local VER_HASH="$3"
  local FILE="$4"

  local VER="${VER_HASH%|*}"
  local HASH="${VER_HASH#*|}"

  python3 - "$PUBLISHER" "$NAME" "$VER" "$HASH" "$FILE" <<'PYEOF'
import sys, re

pub, name, new_ver, new_hash, filepath = sys.argv[1:]

with open(filepath, 'r') as f:
    content = f.read()

# This regex finds a block { ... } containing the specific publisher and name.
# It uses a non-greedy match to ensure it only captures one extension block at a time.
pattern = rf'(\{{\s*name\s*=\s*"{re.escape(name)}";\s*publisher\s*=\s*"{re.escape(pub)}";.*?\s*\}})'

def replace_fields(match):
    block = match.group(1)
    # Only replace the version and hash inside this specific block
    block = re.sub(r'version\s*=\s*"[^"]*";', f'version = "{new_ver}";', block)
    block = re.sub(r'hash\s*=\s*"[^"]*";', f'hash = "{new_hash}";', block)
    return block

new_content = re.sub(pattern, replace_fields, content, flags=re.DOTALL)

with open(filepath, 'w') as f:
    f.write(new_content)
PYEOF
}

# --- Execution ---

NIX_FILE="${1:-$HOME/nixconf/home/vscode/extensions/marketplace.nix}"
[ ! -f "$NIX_FILE" ] && fail "File not found: $NIX_FILE"

# Extract extensions
mapfile -t EXTENSIONS < <(
  awk '
    /^\s*#/        { next }
    /publisher = / { gsub(/.*publisher = "|";.*/, ""); pub = $0 }
    /name = /      { gsub(/.*name = "|";.*/, "");      nam = $0 }
    pub && nam     { print pub "\t" nam; pub = ""; nam = "" }
  ' "$NIX_FILE"
)

echo "Found ${#EXTENSIONS[@]} extensions. Updating..."
# sleep 10
for entry in "${EXTENSIONS[@]}"; do
  P=$(echo "$entry" | cut -f1)
  N=$(echo "$entry" | cut -f2)

  echo "  Checking $P.$N..."
  RESULT=$(get_vsixpkg "$P" "$N") || {
    echo "    Skip: Fetch failed"
    continue
  }
  update_nix_file "$P" "$N" "$RESULT" "$NIX_FILE"
done

echo "Done! File updated without breaking structure."
