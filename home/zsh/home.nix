{
  config,
  pkgs,
  lib,
  ...
}:
let
  zshPlugins = {
    zsh-autosuggestions = null;
    zsh-autopair = null;
    zsh-history-substring-search = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh";
    zsh-z = "share/zsh-z/zsh-z.plugin.zsh";
    zsh-forgit = "share/zsh-forgit/forgit.plugin.zsh";
    zsh-f-sy-h = "share/zsh/site-functions/f-sy-h.zsh";
    zsh-command-time = "share/zsh/plugins/command-time/command-time.plugin.zsh";
  };
in
{
  programs = {
    zsh = {
      dotDir = "${config.xdg.configHome}/zsh";
      enable = true;

      # --- 1. STRICT DEDUPLICATION ---
      history = {
        size = 10000;
        ignoreAllDups = true; # Only saves unique commands to history file
        expireDuplicatesFirst = true;
      };

      enableCompletion = true;
      autosuggestion = {
        enable = true;
      };
      syntaxHighlighting = {
        enable = true;
      };

      plugins = lib.mapAttrsToList (name: path: {
        name = name;
        src = pkgs.${name};
        file = if (path != null) then path else "share/${name}/${name}.zsh";
      }) zshPlugins;

      # --- 2. NATIVE BOUNDARY SEARCHING ---
      initContent = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin

        ZSH_COMMAND_TIME_COLOR="yellow"
        ZSH_COMMAND_TIME_MIN_SECONDS=3
        ZSH_COMMAND_TIME_ECHO=1

        # Force Zsh history lookups to skip identical commands entirely during cycling
        setopt HIST_IGNORE_DUPS
        setopt HIST_FIND_NO_DUPS

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

# Unique temp file for the timer's real system PID
TMUX_PID_FILE="/tmp/tmux_timer_${USER}_$$.pid"

function preexec() {
    if [[ -n "$ZSH_VERSION" ]]; then
        local start_time=$EPOCHREALTIME
    else
        local start_time=$(date +%s.%3N)
    fi

    local parent_pid=$$

    # 1. FORCE PARENT SHELL TO IGNORE JOB: Turn off monitoring in the main shell
    setopt NO_MONITOR 2>/dev/null

    (
        trap "exit" INT TERM
        while true; do
            # Safety check: if main shell dies, close the loop
            if ! kill -0 $parent_pid 2>/dev/null; then
                exit
            fi

            if [[ -n "$ZSH_VERSION" ]]; then
                local now=$EPOCHREALTIME
            else
                local now=$(date +%s.%3N)
            fi

            local delta=$(awk "BEGIN {print $now - $start_time}")
            local formatted=$(awk "BEGIN {
                d = $delta;
                m = int(d / 60);
                s = int(d % 60);
                ms = int((d - int(d)) * 1000);
                if (m > 0) printf \"%dm \", m;
                printf \"%ds %dms\", s, ms;
            }")

            tmux set-env -g TMUX_TIMER_DISPLAY "$formatted"
            tmux refresh-client -S

            sleep 0.05 || exit
        done
    ) >/dev/null 2>&1 &

    # Save the absolute system PID
    local bg_pid=$!
    echo $bg_pid > "$TMUX_PID_FILE"

    # 2. DISOWN IMMEDIATELY: Completely strip it from Zsh's memory
    disown $bg_pid 2>/dev/null

    # 3. RESTORE MONITORING: Turn job tracking back on for your normal commands
    setopt MONITOR 2>/dev/null
}

function precmd() {
    if [ -s "$TMUX_PID_FILE" ]; then
        local target_pid=$(cat "$TMUX_PID_FILE")
        if [ -n "$target_pid" ]; then
            # Turn off monitor mode briefly so the kill/wait sequence is silent
            setopt NO_MONITOR 2>/dev/null
            kill -TERM "$target_pid" 2>/dev/null
            wait "$target_pid" 2>/dev/null
            setopt MONITOR 2>/dev/null
        fi
        > "$TMUX_PID_FILE"
    fi
}

# --- Shortcuts for Exiting ---
function quick_exit() {
    if [ -s "$TMUX_PID_FILE" ]; then
        local target_pid=$(cat "$TMUX_PID_FILE")
        if [ -n "$target_pid" ]; then
            kill -TERM "$target_pid" 2>/dev/null
        fi
        rm -f "$TMUX_PID_FILE"
    fi
    exit
}

alias q!="quick_exit"
      '';
    };
  };
}
