#!/usr/bin/env sh
nix flake update --option access-tokens "github.com=$(gh auth token)"
