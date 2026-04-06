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

  # ── cc parser: lives in the Nix store, no heredoc/escaping issues ──────────
  ccParser = pkgs.writeText "cc-parser.py" ''
    import sys, base64, re

    n        = int(sys.argv[1])
    log_path = sys.argv[2]

    ansi_re = re.compile(r'\x1B[@-Z\\-_]|\x1B\[[\d;]*[ -/]*[@-~]')

    entries       = []
    current_cmd   = None
    current_lines = []

    try:
        with open(log_path, 'r', errors='replace') as fh:
            for raw in fh:
                line = ansi_re.sub(${"'"}', raw.rstrip('\n'))
                if line.startswith('__CC_START__ '):
                    if current_cmd is not None:
                        entries.append((current_cmd, '\n'.join(current_lines).strip()))
                    encoded     = line[len('__CC_START__ '):]
                    current_cmd = base64.b64decode(encoded).decode('utf-8', errors='replace')
                    current_lines = []
                else:
                    if current_cmd is not None:
                        current_lines.append(line)
        if current_cmd is not None:
            entries.append((current_cmd, '\n'.join(current_lines).strip()))
    except FileNotFoundError:
        print("No session log found yet — run a command first.", file=sys.stderr)
        sys.exit(1)

    if not entries:
        print("No commands captured yet.", file=sys.stderr)
        sys.exit(1)

    sep    = '─' * 60
    blocks = []
    for cmd, out in entries[-n:]:
        block = f'$ {cmd}'
        if out:
            block += f'\n{out}'
        blocks.append(block)

    print(f'\n{sep}\n'.join(blocks))
  '';
in
{
  programs = {
    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      dotDir = "${config.xdg.configHome}/zsh";
      enable = true;
      history.size = 10000;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
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
        bindkey "\e[1;5D" backward-word
        bindkey "\e[1;5C" forward-word
        bindkey "\e[1;6D" backward-word
        bindkey "\e[1;6C" forward-word
        bindkey '^H' backward-kill-word
        bindkey "\e[3;5~" kill-word
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey "$terminfo[kcuu1]" history-substring-search-up
        bindkey "$terminfo[kcud1]" history-substring-search-down
        bindkey '^[[Z' reverse-menu-complete

        # ── cc: copy last N commands + output/errors to clipboard ──────────────
        typeset -gx _CC_LOG="$XDG_RUNTIME_DIR/zsh-cc-$$.log"

        # Tee all stdout+stderr into the session log
        exec 3>&1 4>&2
        exec 1> >(stdbuf -oL tee -a "$_CC_LOG" >&3) \
             2> >(stdbuf -oL tee -a "$_CC_LOG" >&4)

        _cc_preexec() {
          local encoded
          encoded=$(printf '%s' "$1" | base64 -w0)
          printf '__CC_START__ %s\n' "$encoded" >> "$_CC_LOG"
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook preexec _cc_preexec

        cc() {
          local n="''${1:-1}"
          sleep 0.12
          local result
          result=$(python3 ${ccParser} "$n" "$_CC_LOG" 2>&1)
          [[ $? -ne 0 ]] && { echo "$result"; return 1; }
          if   command -v wl-copy &>/dev/null; then
            printf '%s' "$result" | wl-copy
          elif command -v xclip   &>/dev/null; then
            printf '%s' "$result" | xclip -selection clipboard
          elif command -v xsel    &>/dev/null; then
            printf '%s' "$result" | xsel --clipboard --input
          else
            echo "cc: no clipboard tool found (wl-copy / xclip / xsel)" >&2
            return 1
          fi
          local word="command"; (( n != 1 )) && word="commands"
          echo "✓ Copied last $n $word with output to clipboard."
        }
      '';
    };
  };
}
