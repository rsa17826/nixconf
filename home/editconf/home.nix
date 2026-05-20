# lib/mkEditableConfig.nix
{ pkgs, lib }:

configs:
# configs is a list of:
# { name = "hypr"; src = "/home/user/nixconf/home/hyprland"; dest = "hypr"; files = [...]; dirs = [...]; }

let
  # ── xdg.configFile entries ───────────────────────────────────────────────
  mkFile = cfg: f: {
    name = "${cfg.dest}/${f}";
    value.source = /. + "${cfg.src}/${f}";
  };
  mkDir = cfg: d: {
    name = "${cfg.dest}/${d}";
    value = {
      source = /. + "${cfg.src}/${d}";
      recursive = true;
    };
  };

  xdgEntries = lib.foldl (
    acc: cfg:
    acc
    // builtins.listToAttrs (map (mkFile cfg) cfg.files)
    // builtins.listToAttrs (map (mkDir cfg) cfg.dirs)
  ) { } configs;

  # ── Bake app configs into the script ────────────────────────────────────
  # Renders:  FILES_hypr=(a b c)  DIRS_hypr=(x y)  etc.
  appBlock = cfg: ''
    FILES_${cfg.name}=(${builtins.concatStringsSep " " cfg.files})
    DIRS_${cfg.name}=(${builtins.concatStringsSep " " cfg.dirs})
    SRC_${cfg.name}="${cfg.src}"
    DEST_${cfg.name}="$HOME/.config/${cfg.dest}"
  '';

  appNames = map (c: c.name) configs;

  editScript = pkgs.writeShellScriptBin "edit-conf" ''
    set -euo pipefail

    # ── Baked-in app configs ──────────────────────────────────────────────
    APPS=(${builtins.concatStringsSep " " appNames})
    ${builtins.concatStringsSep "\n" (map appBlock configs)}

    # ── Helpers ───────────────────────────────────────────────────────────
    enter_app() {
      local app=$1
      local src dest files_var dirs_var marker
      eval "src=\$SRC_$app"
      eval "dest=\$DEST_$app"
      eval "files_var=(\"\''${FILES_$app[@]}\")"
      eval "dirs_var=(\"\''${DIRS_$app[@]}\")"
      marker="$dest/.editmode"

      [[ -f "$marker" ]] && { echo "$app: already in edit mode"; return; }

      for f in "''${files_var[@]}"; do rm -f  "$dest/$f"; ln -s "$src/$f" "$dest/$f"; done
      for d in "''${dirs_var[@]}"; do rm -rf  "$dest/$d"; ln -s "$src/$d" "$dest/$d"; done
      touch "$marker"
      echo "$app: edit mode active ($src)"
    }

    exit_app() {
      local app=$1
      local dest files_var dirs_var marker
      eval "dest=\$DEST_$app"
      eval "files_var=(\"\''${FILES_$app[@]}\")"
      eval "dirs_var=(\"\''${DIRS_$app[@]}\")"
      marker="$dest/.editmode"

      [[ ! -f "$marker" ]] && { echo "$app: not in edit mode"; return; }

      for f in "''${files_var[@]}"; do rm -f "$dest/$f"; done
      for d in "''${dirs_var[@]}"; do rm -f "$dest/$d"; done
      rm -f "$marker"
      echo "$app: symlinks removed"
    }

    status_app() {
      local app=$1
      local dest marker
      eval "dest=\$DEST_$app"
      marker="$dest/.editmode"
      if [[ -f "$marker" ]]; then
        echo "$app: ACTIVE"
        eval "files_var=(\"\''${FILES_$app[@]}\") dirs_var=(\"\''${DIRS_$app[@]}\")"
        for f in "''${files_var[@]}"; do [[ -L "$dest/$f" ]] && echo "    $dest/$f → $(readlink "$dest/$f")"; done
        for d in "''${dirs_var[@]}"; do [[ -L "$dest/$d" ]] && echo "    $dest/$d → $(readlink "$dest/$d")"; done
      else
        echo "$app: inactive"
      fi
    }

    # ── Dispatch ──────────────────────────────────────────────────────────
    CMD="''${1:-}"
    TARGET="''${2:-}"  # optional app name; empty = all

    resolve_apps() {
      if [[ -n "$TARGET" ]]; then
        echo "$TARGET"
      else
        echo "''${APPS[@]}"
      fi
    }

    case "$CMD" in
      enter)
        for app in $(resolve_apps); do enter_app "$app"; done
        [[ -z "$TARGET" ]] && { echo ""; echo "Rebuilding to restore is not needed — run 'edit-conf exit' when done."; }
        ;;
      exit)
        for app in $(resolve_apps); do exit_app "$app"; done
        echo "Running home-manager switch to restore..."
        home-manager switch
        ;;
      status)
        for app in "''${APPS[@]}"; do status_app "$app"; done
        ;;
      *)
        echo "Usage: edit-conf <enter|exit|status> [app]"
        echo ""
        echo "  enter [app]   Symlink app config(s) to nixconf for live editing"
        echo "  exit  [app]   Remove symlinks and restore via home-manager switch"
        echo "  status        Show edit mode state for all apps"
        echo ""
        echo "  Apps: ''${APPS[*]}"
        exit 1
        ;;
    esac
  '';

in
{
  inherit xdgEntries editScript;
}
