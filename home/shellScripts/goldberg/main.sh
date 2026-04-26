#!/usr/bin/env bash
if [[ -n "$1" ]]; then
  f=$(realpath "$1")
  echo "$f" >"$(dirname "$f")/ldr_exe.txt"
  echo "$2" >"$(dirname "$f")/ldr_appid.txt"
  dirname "$f" >"$(dirname "$f")/ldr_cwd.txt"
fi
# "/home/nyix/goldberg emu/steamclient_loader/steamclient_loader.sh" -exe "$f" -appid "$2" -cwd "$(dirname "$f")"
"/home/nyix/goldberg emu/steamclient_loader/steamclient_loader.sh"
