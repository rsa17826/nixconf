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
    // builtins.listToAttrs (map (mkFile cfg) cfg.files)
    // builtins.listToAttrs (map (mkDir cfg) cfg.dirs)
  ) { } configs;

  # ── Bake app configs into the script ────────────────────────────────────
  # Renders:  FILES_hypr=(a b c)  DIRS_hypr=(x y)  etc.
  appBlock = cfg: ''
    FILES_${cfg.name}=(${builtins.concatStringsSep " " cfg.files})
    DIRS_${cfg.name}=(${builtins.concatStringsSep " " cfg.dirs})
    SRC_${cfg.name}="${cfg.srcStr}"
    DEST_${cfg.name}=${cfg.dest}"
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
      local src dest files_var dirs_var marker saved
      eval "src=\$SRC_$app"
      eval "dest=\$DEST_$app"
      eval "files_var=(\"\''${FILES_$app[@]}\")"
      eval "dirs_var=(\"\''${DIRS_$app[@]}\")"
      marker="$dest/.editmode"
      saved="$dest/.editmode_saved_$app"

      [[ -f "$marker" ]] && { echo "$app: already in edit mode"; return; }

      # Save existing link targets before replacing — format: "name<TAB>target"
      # If the path is a regular file/dir (not a symlink), record it as "FILE" so
      # exit_app knows not to try to ln it (hm will restore it on next switch anyway)
      rm -f "$saved"
      for f in "''${files_var[@]}"; do
        if [[ -L "$dest/$f" ]]; then
          echo "$f	$(readlink "$dest/$f")" >> "$saved"
        elif [[ -e "$dest/$f" ]]; then
          echo "$f	FILE" >> "$saved"
        else
          echo "$f	MISSING" >> "$saved"
        fi
      done
      for d in "''${dirs_var[@]}"; do
        if [[ -L "$dest/$d" ]]; then
          echo "$d	$(readlink "$dest/$d")" >> "$saved"
        elif [[ -e "$dest/$d" ]]; then
          echo "$d	DIR" >> "$saved"
        else
          echo "$d	MISSING" >> "$saved"
        fi
      done

      for f in "''${files_var[@]}"; do rm -f   "$dest/$f"; ln -s "$src/$f" "$dest/$f"; done
      for d in "''${dirs_var[@]}"; do rm -rf   "$dest/$d"; ln -s "$src/$d" "$dest/$d"; done
      touch "$marker"
      echo "$app: edit mode active ($src)"
    }

    exit_app() {
      local app=$1
      local dest files_var dirs_var marker saved name target
      eval "dest=\$DEST_$app"
      eval "files_var=(\"\''${FILES_$app[@]}\")"
      eval "dirs_var=(\"\''${DIRS_$app[@]}\")"
      marker="$dest/.editmode"
      saved="$dest/.editmode_saved_$app"

      [[ ! -f "$marker" ]] && { echo "$app: not in edit mode"; return; }

      # Remove live edit symlinks
      for f in "''${files_var[@]}"; do rm -f "$dest/$f"; done
      for d in "''${dirs_var[@]}"; do rm -f "$dest/$d"; done

      # Restore saved symlinks
      if [[ -f "$saved" ]]; then
        while IFS=$'\t' read -r name target; do
          case "$target" in
            FILE|DIR|MISSING)
              # Was not a symlink before — leave absent so hm restores on next switch
              ;;
            *)
              ln -s "$target" "$dest/$name" && echo "  restored $name → $target"
              ;;
          esac
        done < "$saved"
        rm -f "$saved"
      else
        echo "  warning: no saved state found for $app — run a rebuild to fully restore"
      fi

      rm -f "$marker"
      echo "$app: restored"
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
