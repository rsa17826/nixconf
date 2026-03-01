#!/usr/bin/env bash

# Check if arguments were provided
if [ $# -eq 0 ]; then
  echo "Usage: nix-s <pkg1> <pkg2> ..."
  exit 1
fi

# Loop through all arguments and prefix them
args=()
for pkg in "$@"; do
  args+=("nixpkgs#$pkg")
done

# Run the modern nix shell with the prefixed list
echo "🔨 Loading: ${args[*]}"
nix shell "${args[@]}" -c zsh
