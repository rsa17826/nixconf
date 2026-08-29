#!/usr/bin/env bash
#
# create_release.sh
#
# Creates a new GitHub release on the repo located in the current working
# directory. The tag name and title are the next available integer
# (based on existing tags/releases). Files to upload are read from a
# config file (default: release_config.txt) in the same directory.
#
# Config file format (one entry per line):
#   asset_name:literal_path
#   asset_name:run command_to_run
#
#   - "asset_name:./game.exe"        -> uploads ./game.exe as game.exe
#   - "asset_name:run ./thing.sh"    -> runs ./thing.sh, which must
#                                        print a file path on its final
#                                        line of stdout; that file is
#                                        uploaded as asset_name
#
# Requires: git, gh (GitHub CLI), authenticated (`gh auth login`)
#
# Usage:
#   ./create_release.sh [config_file]
#
set -euo pipefail

CONFIG_FILE="${1:-release_config.txt}"

if [ -f "$CONFIG_FILE" ]; then
  # --- sanity checks ---------------------------------------------------------

  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI 'gh' is not installed. See https://cli.github.com" >&2
    exit 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: current directory is not a git repository." >&2
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: gh is not authenticated. Run 'gh auth login' first." >&2
    exit 1
  fi

  # Determine the repo slug (owner/name) for the changelog URL.
  REPO_SLUG="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

  # --- determine next available integer tag ----------------------------------

  # Look at existing releases' tag names (falls back to git tags if gh has none),
  # keep only ones that are pure integers, and pick max+1. If none exist, start at 1.
  existing_tags="$(gh release list --limit 1000 --json tagName -q '.[].tagName' 2>/dev/null || true)"
  if [ -z "$existing_tags" ]; then
    existing_tags="$(git tag -l || true)"
  fi

  max_num=0
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    if [[ "$t" =~ ^[0-9]+$ ]]; then
      if ((t > max_num)); then
        max_num=$t
      fi
    fi
  done <<<"$existing_tags"

  next_num=$((max_num + 1))
  prev_num=$max_num

  TAG_NAME="$next_num"
  TITLE="$next_num"

  echo "Next release: tag='$TAG_NAME' title='$TITLE'"

  # --- build release notes ----------------------------------------------------

  if [ "$prev_num" -gt 0 ]; then
    NOTES="**Full Changelog**: https://github.com/${REPO_SLUG}/compare/${prev_num}...${next_num}"
  else
    NOTES="**Full Changelog**: https://github.com/${REPO_SLUG}/commits/${next_num}"
  fi

  echo "Release notes:"
  echo "$NOTES"

  # --- resolve asset files from config ----------------------------------------
  #
  # For "run" specs, the command is started in the background. It must print
  # the file path as its FIRST line of stdout, then may keep running (e.g.
  # waiting to be signaled) to perform cleanup afterwards. Once the release
  # upload is complete, this script sends SIGTERM to each such background
  # process so it can run its own `trap ... SIGTERM` cleanup handler.
  #
  # Example command script (thing.sh):
  #   #!/usr/bin/env bash
  #   zip -r /tmp/1.zip somedir
  #   echo /tmp/1.zip
  #   trap 'rm -f /tmp/1.zip' SIGTERM
  #   while true; do sleep 1; done   # stay alive to receive the signal

  ASSET_PATHS=()
  CLEANUP_PIDS=()
  FIFO_DIR="$(mktemp -d)"

  cleanup_bg_processes() {
    for pid in "${CLEANUP_PIDS[@]:-}"; do
      [ -z "$pid" ] && continue
      if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
      fi
    done
    rm -rf "$FIFO_DIR"
  }
  trap cleanup_bg_processes EXIT

  echo "Reading asset config from '$CONFIG_FILE'..."
  entry_num=0
  while IFS= read -r line || [ -n "$line" ]; do
    # skip blanks and comments
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue

    asset_name="${line%%:*}"
    spec="${line#*:}"
    asset_name="$(echo "$asset_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    spec="$(echo "$spec" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [ -z "$asset_name" ] || [ -z "$spec" ]; then
      echo "  Warning: skipping malformed config line: $line" >&2
      continue
    fi

    if [[ "$spec" == run\ * ]]; then
      cmd="${spec#run }"
      entry_num=$((entry_num + 1))
      fifo="$FIFO_DIR/fifo_$entry_num"
      mkfifo "$fifo"

      echo "  Running command for '$asset_name': $cmd"
      # Run in background, stdout -> fifo. Process may keep running
      # after printing the path, waiting to be killed for cleanup.
      VERSION=$entry_num bash -c "exec $cmd" >"$fifo" &
      cmd_pid=$!

      # Read only the first line (the path); the fifo stays open so the
      # command can keep running/writing (or just idling) afterward.
      IFS= read -r out_path <"$fifo" || true

      if [ -z "$out_path" ] || [ ! -f "$out_path" ]; then
        echo "  Error: command for '$asset_name' did not return a valid file path on its first line (got: '$out_path')" >&2
        kill -TERM "$cmd_pid" 2>/dev/null || true
        exit 1
      fi

      src_path="$out_path"
      CLEANUP_PIDS+=("$cmd_pid")
    else
      src_path="$spec"
      if [ ! -f "$src_path" ]; then
        echo "  Error: file not found for '$asset_name': $src_path" >&2
        exit 1
      fi
    fi

    # gh lets you rename uploaded assets via "path#displayname"
    ASSET_PATHS+=("${src_path}#${asset_name}")
    echo "  -> will upload '$src_path' as '$asset_name'"
  done <"$CONFIG_FILE"
else
  echo "No config file found at '$CONFIG_FILE'." >&2
  cp "$SCRIPT_DATA_DIR/release_config.txt" "$CONFIG_FILE"
  chmod u+w "$CONFIG_FILE"
  exit 1
fi

# --- create the release ------------------------------------------------------

echo "Creating release..."
gh release create "$TAG_NAME" \
  --title "$TITLE" \
  --notes "$NOTES" \
  --target "$(git rev-parse --abbrev-ref HEAD)" \
  "${ASSET_PATHS[@]}"

echo "Done. Release '$TAG_NAME' created."

# Signal all "run" background processes so they can clean up (e.g. delete
# temp files) now that the upload is finished. Handled by the EXIT trap.
