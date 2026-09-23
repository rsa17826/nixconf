#!/usr/bin/env bash
set -e

# --- Argument Parsing ---
SKIP_HOOKS=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-hooks)
    SKIP_HOOKS=true
    shift
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

# Restore positional parameters (for the commit message)
set -- "${POSITIONAL_ARGS[@]}"

FLAKE_DIR="$HOME/nixconf"
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
MESSAGE="${*:-NO MESSAGE SET}"

TRACK_FILE="$HOME/.config/goproxy-rsa17826/modules.tsv"

# Guard against infinite recursion across a chain of repos: fixHash calls
# `push` (this script) again once it patches a hash, and that push may in
# turn update further downstream repos, whose fixHash calls push again, and
# so on: A -> update B -> fixHash B -> push B -> update C -> fixHash C ->
# push C -> ... If that chain ever comes back around to a repo already
# visited (e.g. C depends on A again), we must stop there instead of
# looping forever. GOPROXY_CHAIN carries the comma-separated list of
# owner/repo entries already visited in the current propagation chain.
CHAIN="${GOPROXY_CHAIN:-}"

# True if $1 (an owner/repo) is already present in the newline-separated $CHAIN.
chain_contains() {
  local repo="$1"
  local seen
  while IFS= read -r seen; do
    [ "$seen" = "$repo" ] && return 0
  done <<<"$CHAIN"
  return 1
}

# Update only the tracked module(s) matching the repo that was just pushed
# ($1 = owner/repo, e.g. "rsa17826/go-input-lib").
update_tracked_go_modules() {
  local repo_filter="$1"

  [ -f "$TRACK_FILE" ] || return 0
  [ -z "$repo_filter" ] && return 0

  if chain_contains "$repo_filter"; then
    echo "[cycle] $repo_filter already updated earlier in this chain (${CHAIN//$'\n'/ -> }), stopping propagation here."
    return 0
  fi

  local NEW_CHAIN="$repo_filter"
  [ -n "$CHAIN" ] && NEW_CHAIN="$CHAIN"$'\n'"$repo_filter"

  echo "===== go module update run: $(date -Iseconds) (filter: $repo_filter, chain: ${NEW_CHAIN//$'\n'/ -> }) ====="

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
        echo "[fixHash] running in $dir"
        (GOPROXY_CHAIN="$NEW_CHAIN" fixHash || echo "[warn] fixHash failed in $dir") &
      else
        echo "[fail] $module failed to update in $dir"
      fi
    )
  done <"$TRACK_FILE"

  echo "===== done ====="
}

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git-push"
mkdir -p "$CONF_DIR"
TRUSTED_HASHES_FILE="$CONF_DIR/trusted_prepush_hashes.tsv"

# Look up whether $1 (a hash) is already trusted for $2 (an absolute path)
# in TRUSTED_HASHES_FILE (tab-separated: path<TAB>hash).
is_trusted_hash() {
  local path="$1" hash="$2"
  [ -f "$TRUSTED_HASHES_FILE" ] || return 1
  local p h
  while IFS=$'\t' read -r p h; do
    [ "$p" = "$path" ] && [ "$h" = "$hash" ] && return 0
  done <"$TRUSTED_HASHES_FILE"
  return 1
}

# Run ./prepush.sh in the current repo root if it exists. Returns nonzero
# to signal the push should be aborted (script missing trust approval, or
# the script itself failed).
run_prepush() {
  local script="$PWD/prepush.sh"
  [ -f "$script" ] || return 0

  local hash
  hash=$(sha256sum "$script" | awk '{print $1}')

  if ! is_trusted_hash "$script" "$hash"; then
    echo "Untrusted prepush.sh found:"
    echo "  path: $script"
    echo "  sha256: $hash"
    read -r -p "Trust and run this script? [y/N] " answer
    case "$answer" in
    [Yy]*)
      mkdir -p "$(dirname "$TRUSTED_HASHES_FILE")"
      printf '%s\t%s\n' "$script" "$hash" >>"$TRUSTED_HASHES_FILE"
      ;;
    *)
      echo "prepush.sh not trusted, aborting push."
      return 1
      ;;
    esac
  fi

  echo "Running prepush.sh..."
  bash "$script"
}

git add -A
if ! git diff --cached --quiet; then
  git commit -m "$MESSAGE"
else
  echo "No changes to commit."
fi

if [ "$SKIP_HOOKS" != true ]; then
  if ! run_prepush; then
    exit 1
  fi
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
      update_tracked_go_modules "$CLEAN_URL"

    else
      echo "Failed to push to $url, continuing..."
    fi
  done
done
