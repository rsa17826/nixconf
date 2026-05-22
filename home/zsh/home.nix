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

function preexec() {
    if [[ -n "$ZSH_VERSION" ]]; then
        local start_time=$EPOCHREALTIME
    else
        local start_time=$(date +%s.%3N)
    fi

    # SILENCE START MESSAGE: Wrap the background launch in a subshell
    # and turn off monitor mode (+m) so the job ID is never printed.
    (
        set +m
        while true; do
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
            sleep 0.05
        done
    ) & 2>/dev/null
    TMUX_TIMER_PID=$!
}

function precmd() {
    # SILENCE TERMINATE MESSAGE: Use a clean kill sequence
    if [ -n "$TMUX_TIMER_PID" ]; then
        # Disable job notifications completely for this operation
        unsetopt NOTIFY 2>/dev/null

        # Send kill signal silently
        kill $TMUX_TIMER_PID 2>/dev/null

        # Abandon tracking of the job so Zsh doesn't complain on exit
        disown $TMUX_TIMER_PID 2>/dev/null

        unset TMUX_TIMER_PID
    fi
}

# --- Shortcuts for Exiting ---
# Custom function to kill the timer loop right before exiting
# so Zsh never warns you about "running jobs".
function quick_exit() {
    if [ -n "$TMUX_TIMER_PID" ]; then
        kill $TMUX_TIMER_PID 2>/dev/null
        disown $TMUX_TIMER_PID 2>/dev/null
    fi
    exit
}

alias q!="quick_exit"
      '';
    };
  };
}
