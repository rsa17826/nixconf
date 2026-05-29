#!/usr/bin/env bash
# job-save -- Register a resumable job
#
# Usage:
#   job-save --name "Friendly name" --cmd "bash -c '...'" [--id "custom-id"]
#
# Prints the job ID on success so callers can store it for job-done.
# Returns exit 1 on bad args.

set -euo pipefail

JOB_DIR="$HOME/.local/share/job-resume"
mkdir -p "$JOB_DIR"

NAME=""
CMD=""
ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --name)
    NAME="$2"
    shift 2
    ;;
  --cmd)
    CMD="$2"
    shift 2
    ;;
  --id)
    ID="$2"
    shift 2
    ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if [[ -z "$NAME" || -z "$CMD" ]]; then
  echo "Usage: job-save --name NAME --cmd COMMAND [--id ID]" >&2
  exit 1
fi

# Generate a short unique ID if not provided
if [[ -z "$ID" ]]; then
  ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 12)
fi

JOB_FILE="$JOB_DIR/$ID.json"

# Use python3 to safely JSON-encode the cmd string (handles quotes, newlines, etc.)
python3 - "$ID" "$NAME" "$CMD" "$JOB_FILE" <<'PYEOF'
import sys, json, datetime

job_id, name, cmd, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
data = {
    "id":         job_id,
    "name":       name,
    "resume_cmd": cmd,
    "created":    datetime.datetime.now().isoformat(timespec="seconds"),
}

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

echo "$ID"
