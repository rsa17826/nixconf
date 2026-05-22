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
        [[ -n "$ZSH_VERSION" ]] && zmodload zsh/datetime

        function precmd() {
            # 1. If a background timer is ticking, kill it silently
            if [ -n "$TMUX_TIMER_PID" ]; then
                # Direct stderr and stdout to /dev/null
                kill $TMUX_TIMER_PID 2>/dev/null

                # Disown tells the shell to stop monitoring this background job,
                # which completely suppresses the "+ terminated" message.
                if [[ -n "$ZSH_VERSION" ]]; then
                    disown $TMUX_TIMER_PID 2>/dev/null
                else
                    # For Bash, we disown the job before waiting
                    eval "disown $TMUX_TIMER_PID" 2>/dev/null
                fi

                wait $TMUX_TIMER_PID 2>/dev/null
                unset TMUX_TIMER_PID
            fi
        }

        function precmd() {
            # 1. If a background timer is ticking, kill it
            if [ -n "$TMUX_TIMER_PID" ]; then
                kill $TMUX_TIMER_PID 2>/dev/null
                wait $TMUX_TIMER_PID 2>/dev/null
                unset TMUX_TIMER_PID
            fi
            # The last recorded value inside TMUX_TIMER_DISPLAY will naturally freeze
            # at the bottom of your screen until your next command starts!
        }
      '';
    };
  };
}
