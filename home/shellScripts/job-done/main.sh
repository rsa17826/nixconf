#!/usr/bin/env bash
# job-done -- Mark a job as complete (removes it from the pending store)
#
# Usage:
#   job-done <job-id>

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: job-done <job-id>" >&2
  exit 1
fi

JOB_DIR="$HOME/.local/share/job-resume"
JOB_FILE="$JOB_DIR/$1.json"

rm -f "$JOB_FILE"
