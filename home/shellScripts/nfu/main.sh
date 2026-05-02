#!/usr/bin/env sh
# shellcheck disable=SC2068
nix flake update --option access-tokens "github.com=$(gh auth token)" $@
