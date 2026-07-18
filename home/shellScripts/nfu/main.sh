#!/usr/bin/env sh

# 1. Take a snapshot of the lockfile before doing anything
# If flake.lock doesn't exist yet, we treat it as empty
if [ -f flake.lock ]; then
  BEFORE_HASH=$(sha256sum flake.lock)
else
  BEFORE_HASH=""
fi

# 2. Run your existing update logic
if [ $# -gt 0 ]; then
  nix flake update --option access-tokens "github.com=$(gh auth token)" "$@"
else
  nix flake metadata --json | jq -r --rawfile excluded ./flake.lock.lock '
  ($excluded | split("\n") | map(select(length > 0))) as $list
  | .locks as $lock
  | $lock.nodes.root.inputs | keys[]
  | select(. as $k | $list | index($k) | not)
  | select(($lock.nodes[.] | .locked.owner) != "rsa17826")
' | xargs -d '\n' nix flake update --option access-tokens "github.com=$(gh auth token)"
fi

# 3. Take a snapshot after the update
if [ -f flake.lock ]; then
  AFTER_HASH=$(sha256sum flake.lock)
else
  AFTER_HASH=""
fi

# 4. Compare and exit 1 if they are the same
if [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
  echo "No changes detected in flake.lock." >&2
  exit 1
fi

echo "flake.lock updated successfully."
