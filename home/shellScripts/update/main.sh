#!/usr/bin/env bash

STATE_FILE="$HOME/.local/share/nix-update-target"
DEFAULT_TARGET="nyx"

mkdir -p "$(dirname "$STATE_FILE")"
err=0
# Flag for nogit
NO_GIT=false
if [[ "$*" == *"--nogit"* ]]; then
  NO_GIT=true
  set -- "${@/--nogit/}"
fi
hm=false
if [[ "$*" == *"hm"* ]]; then
  hm=true
  set -- "${@/hm/}"
fi

# Determine the target
if [ -n "${1:-}" ]; then
  TARGET="$1"
  [[ "$NO_GIT" == false ]] && echo "$TARGET" >"$STATE_FILE"
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

if [ "$PWD" != "$HOME/nixconf" ]; then
  if [ -f "$PWD/flake.nix" ]; then
    echo "fixing hash before updating"
    lastText=$(<"$PWD/flake.nix")
    fixHash
    newText=$(<"$PWD/flake.nix")
    if [[ "$newText" != "$lastText" ]]; then
      push fixed the hashes
    fi
  fi
fi

# Save current directory and move to nixconf
# We use pushd/popd because it's cleaner for directory management in scripts
pushd "$HOME/nixconf" >/dev/null || {
  echo "❌ Could not find ~/nixconf"
  exit 1
}
export NIXPKGS_ALLOW_INSECURE=0
# Real update logic
# now=$(date +%Y-%m-%d_%H-%M)
# Path to the system profiles directory
# directory="/nix/var/nix/profiles/system-profiles/"

# Extract generation numbers, then sort them numerically and get the highest one
# highest_generation=$(ls -l "$directory" | grep -oP 'Generation:_\K[0-9]+' | sort -n | tail -n 1)
# if [ -z "$highest_generation" ]; then
#   next_generation=1
# else
#   next_generation=$((highest_generation + 1))
# fi
now=$(date +"%Y_%m_%d_%H_%M_%S")

# for i in $(seq 10 10 100); do
#   prev_generation=$(git log -n $i --skip $((i - 10)) --format=%B | grep -E 'Generation [0-9]+' | head -n 1 | sed -E 's/Generation ([0-9]+) -.*/\1/')
#   if [[ "$prev_generation" =~ ^[0-9]+$ ]]; then
#     break
#   fi
# done
# 1. Fetch remote status without merging
# SKIP_GIT=true
# next_generation=40
echo "📡 Checking remote for updates..."
git fetch --quiet
HASH_FIX_FILES=(
  # Add paths relative to ~/nixconf, or absolute paths
  # e.g. "pkgs/better-end-line-actions/default.nix"
  "home/vscode/extensions/githubAndLocal.nix"
  "home/vscode/extensions/marketplace.nix"
  "home/programs.nix"
  "dev/python/conf.nix"
)
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

    for f in "${HASH_FIX_FILES[@]}"; do
      local filepath="$HOME/nixconf/$f"
      if [[ -f "$filepath" ]] && grep -qF "${output[0]}" "$filepath"; then
        sed -i "s|${output[0]}|${output[1]}|g" "$filepath"
        echo "   ✅ Fixed in $f"
        fixed=true
      fi
    done
  fi

  $fixed
}
# UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "@{u}" 2>/dev/null || echo "$LOCAL")
BASE=$(git merge-base @ "@{u}" 2>/dev/null || echo "$LOCAL")
if [ "$LOCAL" = "$REMOTE" ]; then
  echo "✅ Local is up to date with remote."
elif [ "$LOCAL" = "$BASE" ]; then
  echo "⚠️ Remote has new changes! Pulling now..."
  git pull --rebase
elif [ "$REMOTE" = "$BASE" ]; then
  echo "⬆️ Local has unpushed commits."
else
  echo "❌ Diverged! You have local and remote changes that conflict."
  echo "Please resolve manually in ~/nixconf before running this script."
  exit 1
fi
prev_generation=$(git log -n 50 --format=%B | grep -m 1 -oP 'Generation \K[0-9]+')
[[ ! "$prev_generation" =~ ^[0-9]+$ ]] && prev_generation=0
# Fallback to 0 if no generation is found in history

if git diff-index --quiet HEAD --; then
  echo "0️⃣ No changes detected. Staying on current generation."
  next_generation=$prev_generation

  SKIP_GIT=true
else
  echo "📝 Changes detected. Incrementing generation."
  next_generation=$((prev_generation + 1))
  SKIP_GIT=false
fi
echo "$next_generation"

# branch=$(git branch 2>/dev/null | sed -n '/^\* / { s|^\* ||; p; }')
# revision=$(git rev-parse HEAD)
NIXOS_LABEL_VERSION="Generation $next_generation - $TARGET - $now"
cat >"$HOME/nixconf/label.nix" <<EOF
"$(echo "$NIXOS_LABEL_VERSION" | sed -E 's/ /./g')"
EOF
# Output the label to verify
echo "NIXOS_LABEL_VERSION: $NIXOS_LABEL_VERSION"
if [[ "$NO_GIT" == 'true' ]]; then
  SKIP_GIT=true
fi
# Commit and push changes
if [ "$SKIP_GIT" = false ]; then
  git add -A
  git commit -m "$NIXOS_LABEL_VERSION"
  git push
fi

echo "🚀 Switching to #$TARGET..."
echo "hm is: $hm"
if [ "$hm" = true ]; then
  home-manager switch --flake ./#nyix
else
  TMPOUT=$(mktemp)
  err=1

  while true; do
    sudo nixos-rebuild switch --flake ".#$TARGET" --log-format internal-json -v --show-trace 2>&1 |
      tee "$TMPOUT" |
      nom --json
    BUILD_EXIT=${PIPESTATUS[0]}

    if [[ $BUILD_EXIT -eq 0 ]]; then
      rm -f "$TMPOUT"
      break
    fi

    if [[ $BUILD_EXIT -eq 0 ]]; then
      # SUCCESS: Update the commit message to reflect success
      if [[ "$SKIP_GIT" == false ]]; then
        echo "✅ Build success! Updating commit message..."
        git commit --amend -m "SUCCESS: $NIXOS_LABEL_VERSION"
        git push --force-with-lease
      fi
      rm -f "$TMPOUT"
      err=0
      break
    fi

    echo "❌ Build failed. Scanning for hash mismatches..."
    if auto_fix_hashes "$TMPOUT"; then
      echo "🔁 Hash patched — retrying..."
      # We commit the fix here so the next attempt starts clean
      if [[ "$SKIP_GIT" == false ]]; then
        git add -A
        git commit --amend --no-edit
      fi
      rm -f "$TMPOUT"
      continue # Re-run the while loop
    else
      # PERMANENT FAILURE: Update commit message to reflect failure
      echo "⚠️ No fixable hashes found."
      if [[ "$SKIP_GIT" == false ]]; then
        git commit --amend -m "FAILED: $NIXOS_LABEL_VERSION"
        git push --force-with-lease
      fi
      err=1
      break
    fi
  done
fi
# sudo nixos-rebuild switch --profile-name "$NIXOS_LABEL_VERSION" --flake ".#$TARGET" --log-format internal-json -v --show-trace |& nom --json

# Return to original directory
popd >/dev/null || exit 1
exit "$err"
