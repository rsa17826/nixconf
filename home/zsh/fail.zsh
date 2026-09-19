#!/usr/bin/env zsh

# @regex (?<!/)rm
# @replace /run/current-system/sw/bin/rm
# @endregex

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

# Directory to store command output logs
export CC_LOG_DIR="/tmp/.cc_logs"
mkdir -p "$CC_LOG_DIR"

# Save original stdout and stderr
exec 3>&1 4>&2

cc() {
  local count="${1:-1}"
  local -a files
  local i

  if ! [[ "$count" == <-> ]] || ((count < 1)); then
    print -u2 "Usage: cc [positive-count]"
    return 2
  fi

  # Newest first.
  files=("$CC_LOG_DIR"/*.log(Nom))

  if ((${#files[@]} == 0)); then
    print -u2 "No command logs found."
    return 1
  fi

  # Don't use zsh array slicing.
  # Just cat the first $count files.
  (
    for ((i = 1; i <= count && i <= ${#files[@]}; i++)); do
      cat -- "${files[i]}" || return 1
    done
  ) | wl-copy
}

# Load Zsh modules & hooks
zmodload zsh/datetime
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
TERMBAR_OWNER_FILE="${TERMBAR_STATUS_FILE:+${TERMBAR_STATUS_FILE}.owner}"

_set_status() {
  [[ -n "$TERMBAR_STATUS_FILE" ]] && echo "$1" >|"$TERMBAR_STATUS_FILE"
}

_set_status "0s 000ms"

format_duration() {
  local delta=$1
  integer d=$delta
  integer h=$((d / 3600))
  integer m=$(((d % 3600) / 60))
  integer s=$((d % 60))
  integer ms=$(((delta - d) * 1000))

  if ((h > 0)); then
    printf "%dh %02dm %02ds %03dms" $h $m $s $ms
  elif ((m > 0)); then
    printf "%dm %02ds %03dms" $m $s $ms
  else
    printf "%ds %03dms" $s $ms
  fi
}

_preexec() {
  # Prevent 'cc' from logging itself and overwriting the target history
  case "$1" in
  exec\ * | cc | cc\ *)
    return
    ;;
  esac

  if [[ -s "$TIMER_PID_FILE" ]]; then
    local old_pid=$(<"$TIMER_PID_FILE")
    [[ -n "$old_pid" ]] && kill -9 "$old_pid" 2>/dev/null
    /run/current-system/sw/bin/rm -f "$TIMER_PID_FILE"
  fi

  # Fallback generation in case zsh/datetime fails to load
  mkdir -p "$CC_LOG_DIR"
  local ts="${EPOCHREALTIME//./_}"
  [[ -z "$ts" ]] && ts="$(date +%s 2>/dev/null)_fallback"

  CC_CURRENT_LOG="$CC_LOG_DIR/${ts}.log"
  echo "$ $1" >"$CC_CURRENT_LOG"
  exec 1> >(tee -a "$CC_CURRENT_LOG") 2>&1

  [[ -n "$TERMBAR_OWNER_FILE" ]] && echo "$$" >|"$TERMBAR_OWNER_FILE"

  local start_time=$EPOCHREALTIME
  local parent_pid=$$

  echo "$start_time" >|"$TIMER_START_FILE"
  unsetopt MONITOR 2>/dev/null

  (
    trap "exit" INT TERM EXIT
    while true; do
      kill -0 $parent_pid 2>/dev/null || exit

      if [[ -n "$TERMBAR_OWNER_FILE" ]] && [[ "$(<"$TERMBAR_OWNER_FILE")" != "$$" ]]; then
        sleep 0.1
        continue
      fi

      local now=$EPOCHREALTIME
      # Prevent syntax errors in background subshell if EPOCHREALTIME is empty
      [[ -z "$now" ]] && now=$(date +%s)
      local delta=$((now - start_time))
      _set_status "$(format_duration $delta)"

      sleep 0.05
    done
  ) >/dev/null 2>&1 &|

  echo $! >|"$TIMER_PID_FILE"
  setopt MONITOR 2>/dev/null
}

_precmd() {
  local -a _codes=("${pipestatus[@]}")
  local exact_end_time=$EPOCHREALTIME

  # Restore normal stdout/stderr cleanly
  exec 1>&3 2>&4

  local code_str=""
  local all_ok=true
  for c in "${_codes[@]}"; do
    ((c != 0)) && all_ok=false
    code_str+="${code_str:+,}$c"
  done

  if [[ -s "$TIMER_START_FILE" ]]; then
    local start_time=$(<"$TIMER_START_FILE")
    if [[ -n "$start_time" ]]; then
      # Ensure numeric evaluation doesn't fail
      [[ -z "$exact_end_time" ]] && exact_end_time=$(date +%s)
      local delta=$((exact_end_time - start_time))
      local time_str="$(format_duration $delta)"
      if $all_ok; then
        _set_status "$time_str"
      else
        _set_status "[$code_str] $time_str"
      fi
    fi
    /run/current-system/sw/bin/rm -f "$TIMER_START_FILE"
  fi

  if [[ -s "$TIMER_PID_FILE" ]]; then
    local target_pid=$(<"$TIMER_PID_FILE")
    if [[ -n "$target_pid" ]]; then
      unsetopt MONITOR 2>/dev/null
      kill -9 "$target_pid" 2>/dev/null
      setopt MONITOR 2>/dev/null
    fi
    /run/current-system/sw/bin/rm -f "$TIMER_PID_FILE"
  fi
}

_zshexit() {
  if [[ -s "$TIMER_PID_FILE" ]]; then
    local _pid=$(<"$TIMER_PID_FILE")
    [[ -n "$_pid" ]] && kill -9 "$_pid" 2>/dev/null
    /run/current-system/sw/bin/rm -f "$TIMER_PID_FILE"
  fi
  /run/current-system/sw/bin/rm -f "$TIMER_START_FILE"
  if [[ -n "$TERMBAR_OWNER_FILE" ]] && [[ "$(<"$TERMBAR_OWNER_FILE")" == "$$" ]]; then
    /run/current-system/sw/bin/rm -f "$TERMBAR_OWNER_FILE"
  fi
}

# Register hooks properly
add-zsh-hook preexec _preexec
add-zsh-hook precmd _precmd
add-zsh-hook zshexit _zshexit

# Safely check and launch termbar
if [[ -n "$PS1" ]] && tty | grep -qv tty; then
  if [[ "$(ps -o comm= -p $PPID 2>/dev/null)" != "termbar" ]]; then
    exec termbar
  fi
fi
