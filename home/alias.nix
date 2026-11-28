{ ... }:
let
  shellAliases = {
    vim = "nvim";
    vi = "nvim";
    nano = "nvim";
    # "nix-env" = "echo wrong command";
    clearcache = "nix-collect-garbage";
    clearallcache = "sudo nix-collect-garbage --delete-older-than 15d";
    worm = "magic-wormhole send";
    hole = "magic-wormhole receive";
    q = "exit 0";
    "q!" = "kill -9 -$(ps -o sid= -p $$ | tr -d ' ') 2>/dev/null";
    c = "clear";
    nix-shell-alias = "nix-shell";
    repairStore = "sudo nix-store --verify --check-contents --repair";
    sd = "shutdown";
    reb = "reboot";
    la = "eza -la --icons --git --header --total-size";
    lt = "eza --tree --level=7 --icons --git --group-directories-first";
    ls = "eza -l --icons --git --header --color-scale --group-directories-first --time-style=relative";
    wiz = "ncdu"; # wiztree
    updatec = "cd ~/nixconf ; (nix flake metadata | grep -oE 'ext-[a-zA-Z0-9_-]+'|xargs nix flake update) && pkill -9 codium ; update && codium && q";
    dea = "echo 'use flake' > .envrc && echo '\\n.direnv' >> .gitignore && git rm -r --cached .direnv 2>/dev/null; direnv allow";
    "7z" = "7zz";
    yo = "nix-shell -p nodejs --run 'npx --package yo --package generator-code -- yo code'";
    wl-reload = "pkill -9 wl-mirror;wl-mirror --title top test_top&disown;wl-mirror --title bottom test_bottom&disown";
    go = "go-get-proxy";
    gcusd = "customGC;usd";
    ee = "thunar";
    gc = "git clone";
    ga = "git rm -r --cached --ignore-unmatch * -f && git add -A && VISUAL=echo git commit --amend";
    gA = "git add -A";
    gs = "git status";
    gi = "git init";
    qs-reload = "fuser -k 8765/tcp; pkill -9 quicksh; qs -d -p ~/nixconf/quickshell/bar/";
    # "(/|(../){0-6}..(/|))" = "cd \1";
    #
    "/" = "cd /";
    "../" = "cd ../";
    ".." = "cd ..";
    "../../" = "cd ../../";
    "../.." = "cd ../..";
    "../../../" = "cd ../../../";
    "../../.." = "cd ../../..";
    "../../../../" = "cd ../../../../";
    "../../../.." = "cd ../../../..";
    "../../../../../" = "cd ../../../../../";
    "../../../../.." = "cd ../../../../..";
    "../../../../../../" = "cd ../../../../../../";
    "../../../../../.." = "cd ../../../../../..";
    "../../../../../../../" = "cd ../../../../../../../";
    "../../../../../../.." = "cd ../../../../../../..";
    "-" = "cd -";
    "~" = "cd ~";
    #
    # "grep -h" = "grep --help";
    "grep" = "grep --color=auto";
    "+x" = "chmod +x";
    "mangohud" = "LD_LIBRARY_PATH=/run/opengl-driver/lib mangohud";
    "clear-yt" = ''
      nix shell nixpkgs#sqlite -c sh -c "sqlite3 /home/nyix/.config/net.imput.helium/Default/History <<"SQL"
      BEGIN;

      CREATE TEMP TABLE yt AS
        SELECT id FROM urls
        WHERE url GLOB 'http*://youtube.com/*'
           OR url GLOB 'http*://*.youtube.com/*';

      CREATE TEMP TABLE yv AS
        SELECT id FROM visits WHERE url IN (SELECT id FROM yt);

      DELETE FROM visit_source        WHERE id IN (SELECT id FROM yv);
      DELETE FROM content_annotations WHERE visit_id IN (SELECT id FROM yv);
      DELETE FROM context_annotations WHERE visit_id IN (SELECT id FROM yv);
      DELETE FROM clusters_and_visits WHERE visit_id IN (SELECT id FROM yv);
      DELETE FROM keyword_search_terms WHERE url_id IN (SELECT id FROM yt);
      DELETE FROM segment_usage WHERE segment_id IN (SELECT id FROM segments WHERE url_id IN (SELECT id FROM yt));
      DELETE FROM segments WHERE url_id IN (SELECT id FROM yt);
      DELETE FROM visits WHERE url IN (SELECT id FROM yt);
      DELETE FROM urls   WHERE id  IN (SELECT id FROM yt);
      COMMIT;
      VACUUM;
      SQL"
    '';
  };
  interactiveShellInit = ''
    alias rm="gio trash"
    alias OA=""
  '';
in
{
  environment = { inherit shellAliases; };
  programs = {
    dconf = {
      enable = true;
    };
    bash = {
      enable = true;
      shellAliases = shellAliases;
      interactiveShellInit = interactiveShellInit;
    };
    zsh = {
      enable = true;
      shellAliases = shellAliases;
      interactiveShellInit = interactiveShellInit;
    };
  };
}
