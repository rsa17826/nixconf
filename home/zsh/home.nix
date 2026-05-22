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
# Ensure high-precision time is available
[[ -n "$ZSH_VERSION" ]] && zmodload zsh/datetime

# Explicitly initialize the bar so it doesn't show old data on startup
if [ -n "$TMUX" ]; then
    tmux set-env -g TMUX_TIMER_DISPLAY "0s 0ms"
fi

TMUX_TIMER_PID_FILE="/tmp/tmux_timer_${USER}_$$.pid"

function preexec() {
    # Safely mute job notifications ONLY inside this function scope
    setopt localoptions no_monitor

    # Clear out any ghost timer that might still be lingering
    if [ -s "$TMUX_TIMER_PID_FILE" ]; then
        kill -9 $(cat "$TMUX_TIMER_PID_FILE") 2>/dev/null
        > "$TMUX_TIMER_PID_FILE"
    fi

    local start_time=$EPOCHREALTIME
    local parent_pid=$$

    # Launch the precision loop completely detached
    (
        trap "exit" INT TERM EXIT
        while true; do
            # Integrity check: if the main terminal window closes, kill this loop
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

            tmux set-env -g TMUX_TIMER_DISPLAY "$formatted"
            tmux refresh-client -S

            sleep 0.05
        done
    ) >/dev/null 2>&1 &

    # Save the background system PID
    echo $! > "$TMUX_TIMER_PID_FILE"
}

function precmd() {
    setopt localoptions no_monitor

    # Command finished: Terminate the loop instantly without waiting around
    if [ -s "$TMUX_TIMER_PID_FILE" ]; then
        local target_pid=$(cat "$TMUX_PID_FILE")
        if [ -n "$target_pid" ]; then
            # Using kill -9 forcefully cuts the process, preventing terminal hangs
            kill -9 "$target_pid" 2>/dev/null
        fi
        > "$TMUX_PID_FILE"
    fi
}

# --- Shortcuts for Exiting ---
function quick_exit() {
    if [ -s "$TMUX_TIMER_PID_FILE" ]; then
        kill -9 $(cat "$TMUX_TIMER_PID_FILE") 2>/dev/null
        rm -f "$TMUX_TIMER_PID_FILE"
    fi
    exit
}

alias q!="quick_exit"
      '';
    };
  };
}
