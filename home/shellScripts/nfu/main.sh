#!/usr/bin/env sh

nix flake metadata --json | jq -r --rawfile excluded ./flake.lock.lock '
  ($excluded | split("\n") | map(select(length > 0))) as $list
  | .locks.nodes.root.inputs | keys[]
  | select(. as $k | $list | index($k) | not)
' | xargs -d '\n' nix flake update --option access-tokens "github.com=$(gh auth token)" "$@"