#!/usr/bin/env zsh
# shellcheck disable=SC1071
ZSH_COMMAND_TIME_COLOR="yellow"
ZSH_COMMAND_TIME_MIN_SECONDS=3
ZSH_COMMAND_TIME_ECHO=1

setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt INTERACTIVE_COMMENTS

bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey "$terminfo[kcuu1]" history-beginning-search-backward
bindkey "$terminfo[kcud1]" history-beginning-search-forward

zsh-history-cleanup-hook() { return 0; }
autoload -Uz add-zsh-hook
add-zsh-hook preexec zsh-history-cleanup-hook

bindkey "\e[1;5D" backward-word
bindkey "\e[1;5C" forward-word
bindkey "\e[1;6D" backward-word
bindkey "\e[1;6C" forward-word
bindkey '^H' backward-kill-word
bindkey '^[d' kill-word
bindkey "\e[3;5~" kill-word
bindkey '^[[Z' reverse-menu-complete
[[ -n "$ZSH_VERSION" ]] && zmodload zsh/datetime

TIMER_PID_FILE="/tmp/termbar_timer_${USER}_$$.pid"
TIMER_START_FILE="/tmp/termbar_timer_start_${USER}_$$.txt"
# Shared ownership file — whichever shell most recently ran a command owns the display.
# Derived from TERMBAR_STATUS_FILE so it's scoped to this termbar session.
TERMBAR_OWNER_FILE="${TERMBAR_STATUS_FILE:+${TERMBAR_STATUS_FILE}.owner}"

# Write to the termbar status file (no-op if not running under termbar)
function _set_status() {
  [[ -n "$TERMBAR_STATUS_FILE" ]] && echo "$1" >|"$TERMBAR_STATUS_FILE"
}

[[ -n "$TERMBAR_ENABLED" ]] && _set_status "0s 000ms"

function format_duration() {
  local delta=$1
  awk "BEGIN {
    d = $delta;
    h = int(d / 3600);
    m = int((d % 3600) / 60);
    s = int(d % 60);
    ms = int((d - int(d)) * 1000);

    if (h > 0) {
      printf \"%dh %02dm %02ds %03dms\", h, m, s, ms;
    } else if (m > 0) {
      printf \"%dm %02ds %03dms\", m, s, ms;
    } else {
      printf \"%ds %03dms\", s, ms;
    }
  }"
}

function preexec() {
  if [[ -s "$TIMER_PID_FILE" ]]; then
    local old_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    [[ -n "$old_pid" ]] && kill -9 "$old_pid" 2>/dev/null
    /run/current-system/sw/bin/rm -f "$TIMER_PID_FILE"
  fi

  # Claim display ownership — nested shells will also do this, taking priority.
  [[ -n "$TERMBAR_OWNER_FILE" ]] && echo "$$" >|"$TERMBAR_OWNER_FILE"

  local start_time=$EPOCHREALTIME
  local parent_pid=$$

  echo "$start_time" >|"$TIMER_START_FILE"
  unsetopt MONITOR 2>/dev/null

  (
    trap "exit" INT TERM EXIT
    while true; do
      kill -0 $parent_pid 2>/dev/null || exit

      # If a nested shell has claimed ownership, idle instead of writing —
      # this prevents flickering between two concurrent timer loops.
      if [[ -n "$TERMBAR_OWNER_FILE" ]] &&
        [[ "$(cat "$TERMBAR_OWNER_FILE" 2>/dev/null)" != "$$" ]]; then
        sleep 0.05
        continue
      fi

      local now=$EPOCHREALTIME
      local delta=$(awk "BEGIN {print $now - $start_time}")
      _set_status "$(format_duration "$delta")"

      sleep 0.05
    done
  ) >/dev/null 2>&1 &|

  echo $! >|"$TIMER_PID_FILE"
  setopt MONITOR 2>/dev/null
}

function zsh-timer-exit-cleanup() {
  if [[ -s "$TIMER_PID_FILE" ]]; then
    local _pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    [[ -n "$_pid" ]] && kill -9 "$_pid" 2>/dev/null
    rm -f "$TIMER_PID_FILE"
  fi
  rm -f "$TIMER_START_FILE"
  # Release display ownership only if this shell still holds it, so the
  # parent shell's timer can resume once we exit.
  if [[ -n "$TERMBAR_OWNER_FILE" ]] &&
    [[ "$(cat "$TERMBAR_OWNER_FILE" 2>/dev/null)" == "$$" ]]; then
    rm -f "$TERMBAR_OWNER_FILE"
  fi
}
add-zsh-hook zshexit zsh-timer-exit-cleanup

function precmd() {
  # Capture pipestatus immediately — it's overwritten by the next command.
  local -a _codes=("${pipestatus[@]}")
  local exact_end_time=$EPOCHREALTIME

  # Build exit code string: omit entirely if all zero, else e.g. "1,0,1"
  local code_str=""
  local all_ok=true
  for c in "${_codes[@]}"; do
    [[ $c -ne 0 ]] && all_ok=false
    code_str+="${code_str:+,}$c"
  done

  if [[ -s "$TIMER_START_FILE" && -n "$TERMBAR_ENABLED" ]]; then
    local start_time=$(cat "$TIMER_START_FILE" 2>/dev/null)
    if [[ -n "$start_time" ]]; then
      local delta=$(awk "BEGIN {print $exact_end_time - $start_time}")
      local time_str="$(format_duration "$delta")"
      if $all_ok; then
        _set_status "$time_str"
      else
        _set_status "[$code_str] $time_str"
      fi
    fi
    rm -f "$TIMER_START_FILE"
  fi

  if [[ -s "$TIMER_PID_FILE" ]]; then
    local target_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    if [[ -n "$target_pid" ]]; then
      unsetopt MONITOR 2>/dev/null
      kill -9 "$target_pid" 2>/dev/null
      setopt MONITOR 2>/dev/null
    fi
    rm -f "$TIMER_PID_FILE"
  fi
}

# Auto-start termbar when in an interactive terminal that isn't already inside it
if [[ -z "$TERMBAR_ENABLED" && -n "$PS1" ]] && tty | grep -qv tty; then
  exec termbar
fi
