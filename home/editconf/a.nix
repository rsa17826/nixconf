{ pkgs, lib }:

configs:
# configs is a list of:
# { name = "hypr"; src = "/home/user/nixconf/home/hyprland"; dest = "hypr"; files = [...]; dirs = [...]; }

let
  # ── xdg.configFile entries ───────────────────────────────────────────────
  mkFile = cfg: f: {
    name = "${cfg.dest}/${f}";
    value.source = cfg.src + "/${f}";
  };
  mkDir = cfg: d: {
    name = "${cfg.dest}/${d}";
    value = {
      source = cfg.src + "/${d}";
      recursive = true;
    };
  };

  xdgEntries = lib.foldl (
    acc: cfg:
    acc
    // builtins.listToAttrs (map (mkFile cfg) (cfg.files or [ ]))
    // builtins.listToAttrs (map (mkDir cfg) (cfg.dirs or [ ]))
  ) { } configs;

  # ── Bake app configs into the script ────────────────────────────────────
  # Renders:  FILES_hypr=(a b c)  DIRS_hypr=(x y)  etc.
  appBlock = cfg: ''
    FILES_${cfg.name}=(${builtins.concatStringsSep " " (cfg.files or [ ])})
    DIRS_${cfg.name}=(${builtins.concatStringsSep " " (cfg.dirs or [ ])})
    SRC_${cfg.name}="${cfg.srcStr}"
    DEST_${cfg.name}="${cfg.dest}"
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
      local -n _files="FILES_"
      local -n _dirs="DIRS_"
      local -n _src="SRC_"
      local -n _dest="DEST_"
      local marker="$_dest/.editmode"
      local saved="$_dest/.editmode_saved_"

      [[ -f "$marker" ]] && { echo "$app: already in edit mode"; return; }

      rm -f "$saved"
      for f in "''${_files[@]}"; do
        if   [[ -L "$_dest/$f" ]]; then printf '%s\t%s\n' "$f" "$(readlink "$_dest/$f")" >> "$saved"
        elif [[ -e "$_dest/$f" ]]; then printf '%s\tFILE\n'    "$f"                       >> "$saved"
        else                            printf '%s\tMISSING\n' "$f"                       >> "$saved"
        fi
      done
      for d in "''${_dirs[@]}"; do
        if   [[ -L "$_dest/$d" ]]; then printf '%s\t%s\n' "$d" "$(readlink "$_dest/$d")" >> "$saved"
        elif [[ -e "$_dest/$d" ]]; then printf '%s\tDIR\n'     "$d"                      >> "$saved"
        else                            printf '%s\tMISSING\n' "$d"                      >> "$saved"
        fi
      done

      for f in "''${_files[@]}"; do rm -f  "$_dest/$f"; ln -s "$_src/$f" "$_dest/$f"; done
      for d in "''${_dirs[@]}";  do rm -rf "$_dest/$d"; ln -s "$_src/$d" "$_dest/$d"; done
      touch "$marker"
      echo "$app: edit mode active ($_src)"
    }

    exit_app() {
      local app=$1
      local -n _files="FILES_"
      local -n _dirs="DIRS_"
      local -n _dest="DEST_"
      local marker="$_dest/.editmode"
      local saved="$_dest/.editmode_saved_"
      local name target

      [[ ! -f "$marker" ]] && { echo "$app: not in edit mode"; return; }

      for f in "''${_files[@]}"; do rm -f "$_dest/$f"; done
      for d in "''${_dirs[@]}";  do rm -f "$_dest/$d"; done

      if [[ -f "$saved" ]]; then
        while IFS=$'\t' read -r name target; do
          case "$target" in
            FILE|DIR|MISSING) ;;  # leave absent; hm restores on next switch
            *) ln -s "$target" "$_dest/$name" && echo "  restored $name → $target" ;;
          esac
        done < "$saved"
        rm -f "$saved"
      else
        echo "  warning: no saved state for $app — run a rebuild to fully restore"
      fi

      rm -f "$marker"
      echo "$app: restored"
    }

    status_app() {
      local app=$1
      local -n _files="FILES_"
      local -n _dirs="DIRS_"
      local -n _dest="DEST_"
      local marker="$_dest/.editmode"

      if [[ -f "$marker" ]]; then
        echo "$app: ACTIVE"
        for f in "''${_files[@]}"; do [[ -L "$_dest/$f" ]] && echo "    $_dest/$f → $(readlink "$_dest/$f")"; done
        for d in "''${_dirs[@]}";  do [[ -L "$_dest/$d" ]] && echo "    $_dest/$d → $(readlink "$_dest/$d")"; done
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
        hyprctl reload
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
