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

      # --- 1. REMOVE DUPLICATES FROM HISTORY ---
      history = {
        size = 10000;
        ignoreAllDups = true; # Ensures a command is only in history once
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

      initContent = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right | source /dev/stdin

        ZSH_COMMAND_TIME_COLOR="yellow"
        ZSH_COMMAND_TIME_MIN_SECONDS=3
        ZSH_COMMAND_TIME_ECHO=1

        # --- CUSTOM WORD-BOUNDARY HISTORY SEARCH ---
        # Track the original query and cursor position across consecutive searches
        typeset -g LAST_HISTORY_SEARCH_QUERY=""
        typeset -g LAST_HISTORY_SEARCH_INDEX=0

        custom-history-search() {
          setopt localoptions extendedglob

          # If the user is just moving up/down consecutively, reuse the original query.
          # Otherwise, reset it to whatever they just typed on the command line.
          if [[ "$LASTWIDGET" != custom-history-search-* ]]; then
            LAST_HISTORY_SEARCH_QUERY="$LBUFFER"
            LAST_HISTORY_SEARCH_INDEX=$HISTNO
          fi

          # If the line is empty, just perform normal up/down history traversal
          [[ -z "$LAST_HISTORY_SEARCH_QUERY" ]] && {
            if [[ "$WIDGET" == *down* ]]; then
              zle .down-line-or-history
            else
              zle .up-line-or-history
            fi
            return
          }

          # Break the *original* query down into shell tokens
          # shellcheck disable=SC2206
          local words=(''${(z)LAST_HISTORY_SEARCH_QUERY})
          local pattern=""
          local word

          for word in $words; do
            local escaped_word="''${word//([.\\*^$])/\\\$MATCH}"
            pattern="$pattern(|.*[;\|&[:space:]])$escaped_word"
          done
          pattern="^$pattern*"

          # Execute the built-in search using our sticky pattern
          if [[ "$WIDGET" == *down* ]]; then
            zle .history-beginning-search-forward "$pattern"
          else
            zle .history-beginning-search-backward "$pattern"
          fi
        }

        zle -N custom-history-search-up custom-history-search
        zle -N custom-history-search-down custom-history-search

        # --- BINDINGS ---
        bindkey "\e[1;5D" backward-word
        bindkey "\e[1;5C" forward-word
        bindkey "\e[1;6D" backward-word
        bindkey "\e[1;6C" forward-word
        bindkey '^H' backward-kill-word
        bindkey '^[d' kill-word
        bindkey "\e[3;5~" kill-word

        bindkey '^[[A' custom-history-search-up
        bindkey '^[[B' custom-history-search-down
        bindkey "$terminfo[kcuu1]" custom-history-search-up
        bindkey "$terminfo[kcud1]" custom-history-search-down

        bindkey '^[[Z' reverse-menu-complete
        setopt INTERACTIVE_COMMENTS
      '';
    };
  };
}
