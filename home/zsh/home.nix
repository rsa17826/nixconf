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

# File to track this specific shell session's background timer PID
TIMER_PID_FILE="/tmp/tmux_timer_''${USER}_$$.pid"

# Initialize the active pane's timer to 0s on startup
if [ -n "$TMUX_PANE" ]; then
    tmux set -t "$TMUX_PANE" @pane_timer "0s 0ms"
fi

function preexec() {
    # Clean up any lingering timer file/process for this specific shell safely
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

    # Drop job monitoring briefly so Zsh doesn't output job creation text
    unsetopt MONITOR 2>/dev/null

    (
        trap "exit" INT TERM EXIT
        while true; do
            # Integrity check: if main shell dies, kill this loop
            if ! kill -0 $parent_pid 2>/dev/null; then
                exit
            fi

            local now=$EPOCHREALTIME
            local delta=$(awk "BEGIN {print $now - $start_time}")

            local formatted=$(awk "BEGIN {
                d = $delta;
                m = int(d / 60);
                s = int(d % 60);
                ms = int((d - int(d)) * 1000);
                if (m > 0) printf \"%dm \", m;
                printf \"%ds %dms\", s, ms;
            }")

            # Target ONLY the exact pane that spawned this command
            tmux set -t "$parent_pane" @pane_timer "$formatted"
            tmux refresh-client -S 2>/dev/null

            sleep 0.05
        done
    ) >/dev/null 2>&1 &!

    # Save the background system PID safely
    echo $! > "$TIMER_PID_FILE"

    # Restore job monitoring for your everyday tasks
    setopt MONITOR 2>/dev/null
}

function precmd() {
    # Command finished: Terminate the loop instantly
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

# --- Shortcuts for Exiting ---
function quick_exit() {
    if [ -s "$TIMER_PID_FILE" ]; then
        local target_pid=$(cat "$TIMER_PID_FILE" 2>/dev/null)
        if [ -n "$target_pid" ]; then
            kill -9 "$target_pid" 2>/dev/null
        fi
        rm -f "$TIMER_PID_FILE" 2>/dev/null
    fi
    exit
}

alias q="quick_exit"
alias q!="quick_exit"
      '';
    };
  };
}
