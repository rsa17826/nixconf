#!/usr/bin/env sh
f=$(realpath "$1")
"/home/nyix/goldberg emu/steamclient_loader/steamclient_loader.sh" -exe "$f" -appid "$2" -cwd "$(dirname "$f")"
