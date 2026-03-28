#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cacert curl jq unzip
# shellcheck shell=bash
set -eu -o pipefail

# Reads extensions from a marketplace.nix file and updates their versions/hashes.
# Usage: ./update_marketplace_exts.sh [path/to/marketplace.nix]
#
# Expected nix file format:
# { pkgs, ... }:
# {
#   programs.vscode.profiles.default = {
#     extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
#       {
#         name = "...";
#         publisher = "...";
#         version = "...";
#         hash = "...";
#       }
#       ...
#     ];
#   };
# }

# Helper to just fail with a message and non-zero exit code.
function fail() {
  echo "$1" >&2
  exit 1
}

# Helper to clean up after ourselves if we're killed by SIGINT.
function clean_up() {
  TDIR="${TMPDIR:-/tmp}"
  echo "Script killed, cleaning up tmpdirs: $TDIR/vscode_exts_*" >&2
  rm -Rf "$TDIR/vscode_exts_*"
}

function get_vsixpkg() {
  local PUBLISHER="$1"
  local NAME="$2"
  local N="$PUBLISHER.$NAME"

  # Create a tempdir for the extension download.
  EXTTMP=$(mktemp -d -t vscode_exts_XXXXXXXX)

  URL="https://$PUBLISHER.gallery.vsassets.io/_apis/public/gallery/publisher/$PUBLISHER/extension/$NAME/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

  # Quietly but delicately curl down the file, blowing up at the first sign of trouble.
  curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/$N.zip" "$URL"
  # Unpack the file we need to stdout then pull out the version
  VER=$(jq -r '.version' <(unzip -qc "$EXTTMP/$N.zip" "extension/package.json"))
  # Calculate the hash
  HASH=$(nix-hash --flat --sri --type sha256 "$EXTTMP/$N.zip")

  # Clean up.
  rm -Rf "$EXTTMP"

  cat <<-EOF
      {
        name = "$NAME";
        publisher = "$PUBLISHER";
        version = "$VER";
        hash = "$HASH";
      }
EOF
}

# Determine the nix file to operate on.
if [ $# -ne 0 ]; then
  NIX_FILE="$1"
else
  NIX_FILE="$(dirname "$0")/marketplace.nix"
fi

if [ ! -f "$NIX_FILE" ]; then
  fail "marketplace.nix not found: $NIX_FILE"
fi

# Try to be a good citizen and clean up after ourselves if we're killed.
trap clean_up SIGINT

# Parse publisher/name pairs out of the nix file.
# Each extension block has lines like:  name = "foo";  and  publisher = "bar";
# We extract them as tab-separated PUBLISHER<TAB>NAME pairs, in order.
mapfile -t EXTENSIONS < <(
  awk '
    /publisher = / { gsub(/.*publisher = "|";.*/, ""); pub = $0 }
    /name = /      { gsub(/.*name = "|";.*/, "");      nam = $0 }
    pub && nam     { print pub "\t" nam; pub = ""; nam = "" }
  ' "$NIX_FILE"
)

if [ ${#EXTENSIONS[@]} -eq 0 ]; then
  fail "No extensions found in $NIX_FILE"
fi

echo "Found ${#EXTENSIONS[@]} extension(s) in $NIX_FILE, fetching updates..." >&2

# Build the updated extensions block.
ENTRIES=""
for entry in "${EXTENSIONS[@]}"; do
  PUBLISHER="${entry%%	*}"
  NAME="${entry##*	}"
  echo "  Updating $PUBLISHER.$NAME ..." >&2
  ENTRIES+="$(get_vsixpkg "$PUBLISHER" "$NAME")"$'\n'
done

# Write the updated file, preserving the surrounding nix boilerplate.
# We replace everything between the opening '[' and closing '];' of the
# extensionsFromVscodeMarketplace list.
TMPOUT=$(mktemp)
awk -v entries="$ENTRIES" '
  /extensionsFromVscodeMarketplace \[/ {
    print
    print entries
    skip = 1
    next
  }
  skip && /^\s*\];/ {
    print
    skip = 0
    next
  }
  skip { next }
  { print }
' "$NIX_FILE" >"$TMPOUT"

mv "$TMPOUT" "$NIX_FILE"
echo "Done. $NIX_FILE updated." >&2
