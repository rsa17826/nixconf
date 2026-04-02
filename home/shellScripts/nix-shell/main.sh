#!/usr/bin/env bash
if [[ "$1" == "-p" ]]; then
  shift
  exec nix shell "${@/#/nixpkgs#}" -c zsh
else
  exec /run/current-system/sw/bin/nix-shell "$@"
fi
