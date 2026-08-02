#!/usr/bin/env bash
set -e

FLAKE_DIR="$HOME/nixconf"
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
MESSAGE="${*:-NO MESSAGE SET}"

TRACK_FILE="$HOME/.config/goproxy-rsa17826/modules.tsv"

# Guard against infinite recursion: fixHash calls `push` (this script) again
# once it patches a hash. When that happens we must NOT re-run the go module
# update step, or we'd loop: update -> fixHash -> push -> update -> ...

# Update only the tracked module(s) matching the repo that was just pushed
# ($1 = owner/repo, e.g. "rsa17826/go-input-lib").
update_tracked_go_modules() {
  local repo_filter="$1"

  [ -f "$TRACK_FILE" ] || return 0
  [ -z "$repo_filter" ] && return 0

  echo "===== go module update run: $(date -Iseconds) (filter: $repo_filter) ====="

  while IFS=$'\t' read -r module dir; do
    [ -z "$module" ] && continue
    [ -z "$dir" ] && continue

    # Only touch entries for the module(s) belonging to the repo we just pushed
    case "$module" in
    *"$repo_filter"*) ;;
    *) continue ;;
    esac

    if [ ! -d "$dir" ]; then
      echo "[skip] $module: dir not found: $dir"
      continue
    fi

    local moduleCheck="$module"
    if [[ $module =~ ^(([^/]+/){2}[^/]+) ]]; then moduleCheck="${BASH_REMATCH[1]}"; fi
    if [ -f "$dir/go.mod" ] && ! grep -qF "$moduleCheck" "$dir/go.mod"; then
      echo "[ignore] $module: no longer in $dir/go.mod, skipping"
      continue
    fi

    echo "[update] $module in $dir"
    (
      cd "$dir" || exit 1
      if go get -u "${module}@latest"; then
        echo "[ok] $module updated in $dir"
        if [ -f go.mod ]; then
          go mod tidy || echo "[warn] go mod tidy failed in $dir"
        fi
        if command -v fixHash >/dev/null 2>&1; then
          echo "[fixHash] running in $dir"
          (fixHash || echo "[warn] fixHash failed in $dir") &
        else
          echo "[warn] fixHash not found on PATH, skipping"
        fi
      else
        echo "[fail] $module failed to update in $dir"
      fi
    )
  done <"$TRACK_FILE"

  echo "===== done ====="
}

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

      # --- UPDATED: AUTO-INCREMENT GO VERSION ---
      if [ -f "go.mod" ]; then
        echo "Detected go.mod, handling version tag..."

        # Get the highest version tag across all branches
        LATEST_TAG=$(git tag -l "v*" | sort -V | tail -n1)
        [ -z "$LATEST_TAG" ] && LATEST_TAG="v0.0.0"

        # Split version (v1.2.3 -> 1 2 3)
        VERSION_PART="${LATEST_TAG#v}"
        IFS='.' read -r major minor patch <<<"$VERSION_PART"

        # Increment patch
        NEW_PATCH=$((patch + 1))
        NEW_TAG="v$major.$minor.$NEW_PATCH"

        echo "Bumping version: $LATEST_TAG -> $NEW_TAG"

        # Create and push the tag
        if git tag "$NEW_TAG"; then
          git push "$url" "$NEW_TAG"
        else
          echo "Failed to create tag $NEW_TAG trying to get newest version."
          # Sync tags from remote to ensure local view is accurate
          git fetch --tags --quiet
          # Get the highest version tag across all branches
          LATEST_TAG=$(git tag -l "v*" | sort -V | tail -n1)
          [ -z "$LATEST_TAG" ] && LATEST_TAG="v0.0.0"

          # Split version (v1.2.3 -> 1 2 3)
          VERSION_PART="${LATEST_TAG#v}"
          IFS='.' read -r major minor patch <<<"$VERSION_PART"

          # Increment patch
          NEW_PATCH=$((patch + 1))
          NEW_TAG="v$major.$minor.$NEW_PATCH"

          echo "Bumping version: $LATEST_TAG -> $NEW_TAG"
          if git tag "$NEW_TAG"; then
            git push "$url" "$NEW_TAG"
          else
            echo "Failed to create tag $NEW_TAG."
          fi
        # Create and push the tag
        fi
      fi
      # --- END AUTO-INCREMENT ---

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

      # --- UPDATE ONLY THE GO MODULE(S) BELONGING TO THE REPO JUST PUSHED ---
      if [ -z "${DONT_UPDATE_GO_LIBS:-}" ]; then
        update_tracked_go_modules "$CLEAN_URL"
      else
        echo "Skipping go module update (already inside an update-triggered push)."
      fi

    else
      echo "Failed to push to $url, continuing..."
    fi
  done
done
