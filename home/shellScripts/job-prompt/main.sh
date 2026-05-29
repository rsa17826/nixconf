#!/usr/bin/env bash
# job-prompt -- Show a popup for each pending job on login/boot.
#
# For each pending job the user sees a dialog with three choices:
#   Resume  → runs the resume command in a terminal, then removes the job
#   Delete  → removes the job permanently
#   Ignore  → leaves the job for next time
#
# Install: add job-prompt.desktop to ~/.config/autostart/
# Depends: zenity (for dialogs), python3 (for JSON parsing)

set -euo pipefail

JOB_DIR="$HOME/.local/share/job-resume"
mkdir -p "$JOB_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────

check_deps() {
  local missing=()
  for dep in zenity python3; do
    command -v "$dep" &>/dev/null || missing+=("$dep")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "job-prompt: missing dependencies: ${missing[*]}" >&2
    exit 1
  fi
}

parse_job() {
  # Usage: parse_job <field> <json-file>
  python3 -c "
import json, sys
with open(sys.argv[2]) as f:
    d = json.load(f)
print(d.get(sys.argv[1], ''))
" "$1" "$2"
}

open_terminal_for_cmd() {
  local cmd="$1"
  # Try common terminals in order of preference
  if command -v kitty &>/dev/null; then
    kitty -- bash -c "$cmd; echo; echo '--- Done. Press Enter to close ---'; read" &
  elif command -v alacritty &>/dev/null; then
    alacritty -e bash -c "$cmd; echo; echo '--- Done. Press Enter to close ---'; read" &
  elif command -v foot &>/dev/null; then
    foot bash -c "$cmd; echo; echo '--- Done. Press Enter to close ---'; read" &
  elif command -v gnome-terminal &>/dev/null; then
    gnome-terminal -- bash -c "$cmd; echo; echo '--- Done. Press Enter to close ---'; read" &
  elif command -v xterm &>/dev/null; then
    xterm -e bash -c "$cmd; echo; echo '--- Done. Press Enter to close ---'; read" &
  else
    # Last resort: run in background without a terminal window
    bash -c "$cmd" &
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

check_deps

# Collect all pending job files
shopt -s nullglob
job_files=("$JOB_DIR"/*.json)
shopt -u nullglob

if [[ ${#job_files[@]} -eq 0 ]]; then
  exit 0
fi

job_count=${#job_files[@]}

# Optional: show an upfront summary notification if more than 1 job
if [[ $job_count -gt 1 ]]; then
  zenity --info \
    --title="Pending Jobs" \
    --text="You have <b>$job_count pending job(s)</b> from a previous session.\n\nYou'll be asked about each one." \
    --width=320 \
    --ok-label="Review Jobs" 2>/dev/null || exit 0
fi

# Process each job
for job_file in "${job_files[@]}"; do
  [[ -f "$job_file" ]] || continue # could have been deleted mid-loop

  job_id=$(parse_job "id" "$job_file")
  name=$(parse_job "name" "$job_file")
  cmd=$(parse_job "resume_cmd" "$job_file")
  created=$(parse_job "created" "$job_file")

  # Build a human-readable created timestamp
  created_fmt=$(python3 -c "
import sys
from datetime import datetime
try:
    dt = datetime.fromisoformat(sys.argv[1])
    print(dt.strftime('%a %d %b %Y at %H:%M'))
except Exception:
    print(sys.argv[1])
" "$created")

  action=$(zenity --list \
    --title="Pending Job" \
    --text="<b>${name//&/&amp;}</b>\n\nSaved: $created_fmt\n\nWhat would you like to do?" \
    --radiolist \
    --column="" --column="Action" \
    TRUE "Resume — run the job now" \
    FALSE "Ignore — ask me again next time" \
    FALSE "Delete — remove this job permanently" \
    --width=400 --height=290 \
    --ok-label="Confirm" \
    --cancel-label="Skip All" 2>/dev/null) || {
    # Cancel/close = stop prompting entirely
    exit 0
  }

  case "$action" in
  "Resume — run the job now")
    open_terminal_for_cmd "$cmd"
    job-done "$job_id" 2>/dev/null || rm -f "$job_file"
    ;;
  "Delete — remove this job permanently")
    job-done "$job_id" 2>/dev/null || rm -f "$job_file"
    ;;
  "Ignore — ask me again next time" | "")
    : # leave the file in place
    ;;
  esac
done

exit 0
