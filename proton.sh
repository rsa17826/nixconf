#!/usr/bin/env bash

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.proton"
export STEAM_COMPAT_DATA_PATH="$HOME/.proton-prefixes/mygame"

exec proton run "$@"
