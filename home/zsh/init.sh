#!/usr/bin/env zsh
# shellcheck disable=SC1071
ZSH_COMMAND_TIME_COLOR="yellow"
ZSH_COMMAND_TIME_MIN_SECONDS=3
ZSH_COMMAND_TIME_ECHO=1

# Force Zsh history lookups to skip identical commands entirely during cycling
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt INTERACTIVE_COMMENTS

# --- NATIVE KEYBINDINGS FOR EXTENDED MATCHING ---
# If the line is empty, these default to normal up/down line movement natively.
# If you type 'e ', they act as strict beginning-of-line/boundary history lookups.
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey "$terminfo[kcuu1]" history-beginning-search-backward
bindkey "$terminfo[kcud1]" history-beginning-search-forward

# --- WORD BOUNDARY REPLACEMENT LOGIC ---
# This interceptor hook executes every time you press Enter to execute a command.
# If you typed 'e bash', it ensures it expands cleanly in history so future
# lookups catch boundaries safely without breaking empty-line 'Up' clicks.
zsh-history-cleanup-hook() {
  # Keeps history clean without altering active buffer states
  return 0
}
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

TIMER_PID_FILE="/tmp/tmux_timer_${USER}_$$.pid"
TIMER_START_FILE="/tmp/tmux_timer_start_${USER}_$$.txt"

if [ -n "$TMUX_PANE" ]; then
  tmux set -t "$TMUX_PANE" @pane_timer "0s 000ms"
fi

# The core math and formatting block extracted so both hooks format exactly the same way
function format_tmux_duration() {
  local delta=$1
  awk "BEGIN {
    d = $delta;
    m = int(d / 60);
    s = int(d % 60);
    ms = int((d - int(d)) * 1000);

    # Format string building
    if (m > 0) {
      # Minutes are active: pad seconds to 2 digits (e.g., 1m 02s 005ms)
      printf \"%dm %02ds %03dms\", m, s, ms;
    } else {
      # Under a minute: do not pad seconds (e.g., 5s 042ms)
      printf \"%ds %03dms\", s, ms;
    }
  }"
}

function preexec() {
  if [ -s "$TIMER_PID_FILE" ]; then
    local old_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    if [ -n "$old_pid" ]; then
      kill -9 "$old_pid" 2>/dev/null
    fi
    rm -f "$TIMER_PID_FILE" 2>/dev/null
  fi

  local start_time=$EPOCHREALTIME
  local parent_pid=$$
  local parent_pane=$TMUX_PANE

  echo "$start_time" >"$TIMER_START_FILE"
  unsetopt MONITOR 2>/dev/null

  (
    trap "exit" INT TERM EXIT
    while true; do
      if ! kill -0 $parent_pid 2>/dev/null; then
        exit
      fi

      local now=$EPOCHREALTIME
      local delta=$(awk "BEGIN {print $now - $start_time}")
      local formatted=$(format_tmux_duration "$delta")

      tmux set -t "$parent_pane" @pane_timer "$formatted"
      tmux refresh-client -S 2>/dev/null

      sleep 0.05
    done
  ) >/dev/null 2>&1 &|

  echo $! >"$TIMER_PID_FILE"
  setopt MONITOR 2>/dev/null
}

# --- CLEANUP ON SHELL EXIT ---
function zsh-timer-exit-cleanup() {
  # Kill the live-updating background subshell immediately so tmux doesn't
  # wait on the process group after zsh itself has already exited.
  if [ -s "$TIMER_PID_FILE" ]; then
    local _exit_pid
    _exit_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    [ -n "$_exit_pid" ] && kill -9 "$_exit_pid" 2>/dev/null
    rm -f "$TIMER_PID_FILE" 2>/dev/null
  fi
  rm -f "$TIMER_START_FILE" 2>/dev/null
}
add-zsh-hook zshexit zsh-timer-exit-cleanup

function precmd() {
  local exact_end_time=$EPOCHREALTIME

  if [ -s "$TIMER_START_FILE" ] && [ -n "$TMUX_PANE" ]; then
    local start_time=$(cat "$TIMER_START_FILE" 2>/dev/null)
    if [ -n "$start_time" ]; then
      local delta=$(awk "BEGIN {print $exact_end_time - $start_time}")
      local final_formatted=$(format_tmux_duration "$delta")

      tmux set -t "$TMUX_PANE" @pane_timer "$final_formatted"
      tmux refresh-client -S 2>/dev/null
    fi
    rm -f "$TIMER_START_FILE" 2>/dev/null
  fi

  if [ -s "$TIMER_PID_FILE" ]; then
    local target_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
    if [ -n "$target_pid" ]; then
      unsetopt MONITOR 2>/dev/null
      kill -9 "$target_pid" 2>/dev/null
      setopt MONITOR 2>/dev/null
    fi
    rm -f "$TIMER_PID_FILE" 2>/dev/null
  fi
}
if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
  exec tmux new-session -A -s $$
fi
