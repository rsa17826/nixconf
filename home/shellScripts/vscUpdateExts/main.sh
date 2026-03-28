#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cacert curl jq unzip python3
# shellcheck shell=bash
set -eu -o pipefail

# Usage: ./update_marketplace_exts.sh [path/to/marketplace.nix]

function fail() {
  echo "$1" >&2
  exit 1
}

function clean_up() {
  TDIR="${TMPDIR:-/tmp}"
  rm -Rf "$TDIR/vscode_exts_*"
}

function get_vsixpkg() {
  local PUBLISHER="$1"
  local NAME="$2"
  local N="$PUBLISHER.$NAME"

  EXTTMP=$(mktemp -d -t vscode_exts_XXXXXXXX)

  URL="https://$PUBLISHER.gallery.vsassets.io/_apis/public/gallery/publisher/$PUBLISHER/extension/$NAME/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

  if ! curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/$N.zip" "$URL"; then
    echo "    FAILED to download $N" >&2
    rm -Rf "$EXTTMP"
    return 1
  fi

  VER=$(jq -r '.version' <(unzip -qc "$EXTTMP/$N.zip" "extension/package.json"))
  HASH=$(nix-hash --flat --sri --type sha256 "$EXTTMP/$N.zip")

  rm -Rf "$EXTTMP"

  # Standardized indentation for the block
  cat <<-EOF
      {
        name = "$NAME";
        publisher = "$PUBLISHER";
        version = "$VER";
        hash = "$HASH";
      }
EOF
}

function replace_block() {
  local PUBLISHER="$1"
  local NAME="$2"
  local NEW_BLOCK="$3"
  local FILE="$4"

  python3 - "$PUBLISHER" "$NAME" "$NEW_BLOCK" "$FILE" <<'PYEOF'
import sys, re

publisher, name, new_block, filepath = sys.argv[1:5]

with open(filepath, 'r') as f:
    lines = f.readlines()

result = []
i = 0
replaced = False

while i < len(lines):
    line = lines[i]
    stripped = line.strip()

    # Look for a block starting with '{' that contains our target publisher and name
    # and isn't the start of the file or a function header.
    if stripped == '{' and not line.lstrip().startswith('#'):
        block_lines = [line]
        j = i + 1
        inner_publisher = None
        inner_name = None
        
        # Look ahead to see if this block matches
        while j < len(lines):
            bl = lines[j]
            block_lines.append(bl)
            if not bl.lstrip().startswith('#'):
                pm = re.search(r'publisher\s*=\s*"([^"]+)"', bl)
                nm = re.search(r'name\s*=\s*"([^"]+)"', bl)
                if pm: inner_publisher = pm.group(1)
                if nm: inner_name = nm.group(1)
                if bl.strip() == '}': break
            j += 1

        if inner_publisher == publisher and inner_name == name and not replaced:
            # Maintain indentation of the original block if possible
            indent = "      " 
            indented_block = "\n".join([indent + l.strip() if l.strip() else "" for l in new_block.splitlines()])
            result.append(indented_block + '\n')
            replaced = True
            i = j + 1
        else:
            result.append(line)
            i += 1
    else:
        result.append(line)
        i += 1

with open(filepath, 'w') as f:
    f.writelines(result)
PYEOF
}

# --- Main Script ---

if [ $# -ne 0 ]; then
  NIX_FILE="$1"
else
  NIX_FILE="$HOME/nixconf/home/vscode/extensions/marketplace.nix"
fi

[ ! -f "$NIX_FILE" ] && fail "File not found: $NIX_FILE"

trap clean_up SIGINT

# Extract only blocks that have both publisher and name
mapfile -t EXTENSIONS < <(
  awk '
    /^\s*#/        { next }
    /publisher = / { gsub(/.*publisher = "|";.*/, ""); pub = $0 }
    /name = /      { gsub(/.*name = "|";.*/, "");      nam = $0 }
    pub && nam     { print pub "\t" nam; pub = ""; nam = "" }
  ' "$NIX_FILE"
)

echo "Updating ${#EXTENSIONS[@]} extensions in $NIX_FILE..."

for entry in "${EXTENSIONS[@]}"; do
  # Extract tab-separated values
  PUBLISHER=$(echo "$entry" | cut -f1)
  NAME=$(echo "$entry" | cut -f2)

  echo "  -> $PUBLISHER.$NAME"
  NEW_BLOCK=$(get_vsixpkg "$PUBLISHER" "$NAME") || continue
  replace_block "$PUBLISHER" "$NAME" "$NEW_BLOCK" "$NIX_FILE"
done

echo "Update complete."
