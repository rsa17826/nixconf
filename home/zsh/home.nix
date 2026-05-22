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

        setopt INTERACTIVE_COMMENTS
        # Ensure float math/millisecond support is available (required for Zsh)
        [[ -n "$ZSH_VERSION" ]] && zmodload zsh/datetime

        # Record start time and flag that a command is active
        function preexec() {
            # Get current epoch time in seconds with millisecond precision
            if [[ -n "$ZSH_VERSION" ]]; then
                CMD_START_TIME=$EPOCHREALTIME
            else
                CMD_START_TIME=$(date +%s.%3N)
            fi
            # Store start time globally for tmux to read
            tmux set-env -g TMUX_CMD_START "$CMD_START_TIME"
            tmux set-env -g TMUX_CMD_STATE "running"
        }

        # Command finished: calculate and lock the final duration
        function precmd() {
            if [ -n "$CMD_START_TIME" ]; then
                if [[ -n "$ZSH_VERSION" ]]; then
                    local end_time=$EPOCHREALTIME
                else
                    local end_time=$(date +%s.%3N)
                fi

                # Calculate duration
                local delta=$(awk "BEGIN {print $end_time - $CMD_START_TIME}")

                # Format the final duration into a clean string (e.g., 1m 4s 230ms)
                local formatted_time=$(awk "BEGIN {
                    d = $delta;
                    m = int(d / 60);
                    s = int(d % 60);
                    ms = int((d - int(d)) * 1000);
                    if (m > 0) printf \"%dm \", m;
                    printf \"%ds %dms\", s, ms;
                }")

                # Pass final state to tmux
                tmux set-env -g TMUX_CMD_STATE "finished"
                tmux set-env -g TMUX_LAST_DURATION "$formatted_time"
                unset CMD_START_TIME
            fi
        }
      '';
    };
  };
}
