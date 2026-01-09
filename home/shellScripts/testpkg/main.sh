#!/usr/bin/env sh

# Run nix-shell with the current package name
exec nix-shell -p "$0" --run fish
