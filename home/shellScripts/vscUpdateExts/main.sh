#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cacert curl jq unzip python3
# shellcheck shell=bash
set -eu -o pipefail

# Reads extensions from a marketplace.nix file and updates their versions/hashes
# one block at a time, preserving any commented-out blocks in the list.
# Usage: ./update_marketplace_exts.sh [path/to/marketplace.nix]

function fail() {
  echo "$1" >&2
  exit 1
}

function clean_up() {
  TDIR="${TMPDIR:-/tmp}"
  echo "Script killed, cleaning up tmpdirs: $TDIR/vscode_exts_*" >&2
  rm -Rf "$TDIR/vscode_exts_*"
}

function get_vsixpkg() {
  local PUBLISHER="$1"
  local NAME="$2"
  local N="$PUBLISHER.$NAME"

  EXTTMP=$(mktemp -d -t vscode_exts_XXXXXXXX)

  URL="https://$PUBLISHER.gallery.vsassets.io/_apis/public/gallery/publisher/$PUBLISHER/extension/$NAME/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

  curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/$N.zip" "$URL"
  VER=$(jq -r '.version' <(unzip -qc "$EXTTMP/$N.zip" "extension/package.json"))
  HASH=$(nix-hash --flat --sri --type sha256 "$EXTTMP/$N.zip")

  rm -Rf "$EXTTMP"

  # Indent matches the surrounding nix file style (6 spaces)
  cat <<-EOF
      {
        name = "$NAME";
        publisher = "$PUBLISHER";
        version = "$VER";
        hash = "$HASH";
      }
EOF
}

# Replace a single { ... } block in NIX_FILE that matches the given publisher+name.
# Commented-out blocks (lines beginning with #) are left untouched.
function replace_block() {
  local PUBLISHER="$1"
  local NAME="$2"
  local NEW_BLOCK="$3"
  local FILE="$4"

  python3 - "$PUBLISHER" "$NAME" "$NEW_BLOCK" "$FILE" <<'PYEOF'
import sys, re

publisher = sys.argv[1]
name      = sys.argv[2]
new_block = sys.argv[3]
filepath  = sys.argv[4]

with open(filepath, 'r') as f:
    lines = f.readlines()

result   = []
i        = 0
replaced = False

while i < len(lines):
    line     = lines[i]
    stripped = line.strip()

    # Start of a non-commented bare block?
    if stripped == '{' and not line.lstrip().startswith('#'):
        block = [line]
        j = i + 1
        blk_publisher = None
        blk_name      = None

        # Collect lines until the matching closing brace.
        while j < len(lines):
            bl  = lines[j]
            bls = bl.strip()
            block.append(bl)

            # Only read attributes from non-commented lines.
            if not bl.lstrip().startswith('#'):
                pm = re.search(r'publisher\s*=\s*"([^"]+)"', bl)
                nm = re.search(r'name\s*=\s*"([^"]+)"', bl)
                if pm:
                    blk_publisher = pm.group(1)
                if nm:
                    blk_name = nm.group(1)
                if bls == '}':
                    break
            j += 1

        if blk_publisher == publisher and blk_name == name and not replaced:
            # Emit the replacement block, keeping the original trailing newline.
            result.append(new_block + '\n')
            replaced = True
        else:
            result.extend(block)

        i = j + 1
    else:
        result.append(line)
        i += 1

if not replaced:
    print(f"WARNING: no uncommented block found for {publisher}.{name} — skipped", file=sys.stderr)

with open(filepath, 'w') as f:
    f.writelines(result)
PYEOF
}

# Determine the nix file to operate on.
if [ $# -ne 0 ]; then
  NIX_FILE="$1"
else
  NIX_FILE="$HOME/home/vscode/extensions/marketplace.nix"
fi

if [ ! -f "$NIX_FILE" ]; then
  fail "marketplace.nix not found: $NIX_FILE"
fi

trap clean_up SIGINT

# Parse publisher+name pairs from uncommented lines only.
mapfile -t EXTENSIONS < <(
  awk '
    /^\s*#/        { next }
    /publisher = / { gsub(/.*publisher = "|";.*/, ""); pub = $0 }
    /name = /      { gsub(/.*name = "|";.*/, "");      nam = $0 }
    pub && nam     { print pub "\t" nam; pub = ""; nam = "" }
  ' "$NIX_FILE"
)

if [ ${#EXTENSIONS[@]} -eq 0 ]; then
  fail "No uncommented extensions found in $NIX_FILE"
fi

echo "Found ${#EXTENSIONS[@]} extension(s) in $NIX_FILE, fetching updates..." >&2

for entry in "${EXTENSIONS[@]}"; do
  PUBLISHER="${entry%%	*}"
  NAME="${entry##*	}"
  echo "  Updating $PUBLISHER.$NAME ..." >&2
  NEW_BLOCK=$(get_vsixpkg "$PUBLISHER" "$NAME")
  replace_block "$PUBLISHER" "$NAME" "$NEW_BLOCK" "$NIX_FILE"
done

echo "Done. $NIX_FILE updated." >&2
