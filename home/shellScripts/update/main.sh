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
    [[ "$DRY_RUN" == false ]] && echo "$TARGET" > "$STATE_FILE"
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
pushd "$HOME/nixconf" > /dev/null || { echo "❌ Could not find ~/nixconf"; exit 1; }
export NIXPKGS_ALLOW_INSECURE=0
if [ "$DRY_RUN" = true ]; then
    echo "🧪 DRY RUN: Building #$TARGET (No commit, no push, no switch)"
    
    sudo nixos-rebuild build --flake ".#$TARGET" --impure --log-format internal-json -v --show-trace |& nom --json
    
    # Return to original directory
    popd > /dev/null
    echo "✅ Dry run complete. If no errors appeared, it's safe to update."
else
    # Real update logic
    git add .
    now=$(date +%Y-%m-%d_%H-%M)
    export NIXOS_LABEL_VERSION="$TARGET - $now"
    git commit -m "$NIXOS_LABEL_VERSION"
    git push

    echo "🚀 Switching to #$TARGET..."
    # I kept --show-trace as you added it; it's helpful for debugging sops errors
    sudo nixos-rebuild switch --flake ".#$TARGET" --impure --log-format internal-json -v --show-trace |& nom --json
    
    # Return to original directory
    popd > /dev/null
fi
