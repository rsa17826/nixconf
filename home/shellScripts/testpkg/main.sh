#/usr/bin/env sh
which nix-shell
nix-shell -p "$0" --run fish
# (which nix-shell) -p "$0" --run fish