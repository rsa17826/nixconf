#!/usr/bin/env bash
# Example "run" command for release_config.txt.
#
# Contract:
#   1. Do your work and produce the file to upload.
#   2. Print its path as the FIRST line of stdout, then flush/exit that line
#      (the release script only reads one line before continuing).
#   3. Optionally keep running afterward (e.g. an idle loop) so you can
#      catch SIGTERM and clean up. The release script sends SIGTERM to this
#      process once the GitHub upload has finished.

set -euo pipefail

OUT="/tmp/1.zip"
zip -qr "$OUT" ./somedir

# First line of stdout = the path to upload.
echo "$OUT"

# Clean up when the release script signals us that the upload is done.
trap 'rm -f "$OUT"; exit 0' SIGTERM

# Stay alive so the trap can fire.
while true; do
  sleep 1
done
