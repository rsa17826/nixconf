#!/usr/bin/env bash

STATE_FILE="$HOME/.local/share/nix-update-target"
DEFAULT_TARGET="nyx"

mkdir -p "$(dirname "$STATE_FILE")"

# Flag for dry-run
DRY_RUN=false
if [[ "$*" == *"--dry-run"* ]]; then
  DRY_RUN=true
  set -- "${@/--dry-run/}"
fi

# Determine the target
if [ -n "$1" ]; then
  TARGET="$1"
  [[ "$DRY_RUN" == false ]] && echo "$TARGET" >"$STATE_FILE"
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

# Save current directory and move to nixconf
# We use pushd/popd because it's cleaner for directory management in scripts
pushd "$HOME/nixconf" >/dev/null || {
  echo "❌ Could not find ~/nixconf"
  exit 1
}
export NIXPKGS_ALLOW_INSECURE=0
if [ "$DRY_RUN" = true ]; then
  echo "🧪 DRY RUN: Building #$TARGET (No commit, no push, no switch)"

  sudo nixos-rebuild build --flake ".#$TARGET" --log-format internal-json -v --show-trace |& nom --json

  # Return to original directory
  popd >/dev/null
  echo "✅ Dry run complete. If no errors appeared, it's safe to update."
else
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
  echo "📡 Checking remote for updates..."
  git fetch --quiet

  UPSTREAM=${1:-'@{u}'}
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
  echo $next_generation

  # branch=$(git branch 2>/dev/null | sed -n '/^\* / { s|^\* ||; p; }')
  # revision=$(git rev-parse HEAD)
  NIXOS_LABEL_VERSION="Generation $next_generation - $TARGET - $now"

  # Output the label to verify
  echo "NIXOS_LABEL_VERSION: $NIXOS_LABEL_VERSION"

  # Commit and push changes
  if [ "$SKIP_GIT" = false ]; then
    git add -A
    git commit -m "$NIXOS_LABEL_VERSION"
    git push
  fi

  NIXOS_LABEL_VERSION=$(echo "$NIXOS_LABEL_VERSION" | sed -E 's/ /./g')

  export NIXOS_LABEL_VERSION
  echo "🚀 Switching to #$TARGET..."
  sudo nixos-rebuild switch --flake ".#$TARGET" --log-format internal-json -v --show-trace --impure |& nom --json
  # sudo nixos-rebuild switch --profile-name "$NIXOS_LABEL_VERSION" --flake ".#$TARGET" --log-format internal-json -v --show-trace |& nom --json

  # Return to original directory
  popd >/dev/null
fi
