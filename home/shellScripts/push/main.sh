#!/usr/bin/env bash
set -e

FLAKE_DIR="$HOME/nixconf"

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)

MESSAGE="${*:-NO MESSAGE SET}"

git add -A
if ! git diff --cached --quiet; then
  git commit -m "$MESSAGE"
else
  echo "No changes to commit."
fi

REMOTES=$(git remote)
if [ -z "$REMOTES" ]; then
  echo "No remotes configured."
  exit 0
fi
for remote in $REMOTES; do
  PUSH_URLS=$(git remote get-url --push "$remote" 2>/dev/null || echo "")
  [ -z "$PUSH_URLS" ] && continue

  echo "$PUSH_URLS" | while read -r url; do
    echo "Pushing to $remote ($url)..."

    if git push "$url" "$BRANCH"; then

      # Extract "owner/repo" from the Git URL (handles SSH and HTTPS)
      CLEAN_URL=$(echo "$url" | sed -E 's|.*github.com[:/]([^/]+/[^/.]+)(\.git)?$|\1|')

      # Query the flake metadata for inputs matching that owner/repo
      MATCHING_INPUTS=$(
        nix flake metadata "$FLAKE_DIR" --json | jq -r --arg TARGET "$CLEAN_URL" '
        .locks.nodes | to_entries[] |
        select(
          (.value.original.owner + "/" + .value.original.repo == $TARGET) or
          (.value.original.url | strings | contains($TARGET))
        ) | .key'
      )

      if [ -n "$MATCHING_INPUTS" ]; then
        pushd "$FLAKE_DIR" >/dev/null
        for input in $MATCHING_INPUTS; do
          echo "✨ Match found! Updating flake input: $input"
          nix flake update "$input"
        done
        popd >/dev/null
      fi

    else
      echo "Failed to push to $url, continuing..."
    fi
  done
done
