{ pkgs, lib }:

configs:
# configs is a list of:
# { name = "hypr"; src = <path>; srcStr = "..."; nixKey = "hypr"; dest = "$HOME/.config/hypr"; files = [...]; dirs = [...]; }
# nixKey  = key prefix for xdg.configFile or home.file (relative)
# dest    = full shell path used in the edit-conf script

let
  # ── entries for xdg.configFile or home.file ──────────────────────────────
  mkFile = cfg: f: {
    name = "${cfg.nixKey}/${f}";
    value.source = cfg.src + "/${f}";
  };
  mkDir = cfg: d: {
    name = "${cfg.nixKey}/${d}";
    value = {
      source = cfg.src + "/${d}";
      recursive = true;
    };
  };

  entries = lib.foldl (
    acc: cfg:
    acc
    // builtins.listToAttrs (map (mkFile cfg) (cfg.files or [ ]))
    // builtins.listToAttrs (map (mkDir cfg) (cfg.dirs or [ ]))
  ) { } configs;

  # ── Bake app configs into the script ─────────────────────────────────────
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
      local -n _files="FILES_''${app}"
      local -n _dirs="DIRS_''${app}"
      local -n _src="SRC_''${app}"
      local -n _dest="DEST_''${app}"
      local marker="''${_dest}/.editmode"
      local saved="''${_dest}/.editmode_saved_''${app}"

      [[ -f "$marker" ]] && { echo "$app: already in edit mode"; return; }

      rm -f "$saved"
      for f in "''${_files[@]}"; do
        if   [[ -L "''${_dest}/$f" ]]; then printf '%s\t%s\n' "$f" "$(readlink "''${_dest}/$f")" >> "$saved"
        elif [[ -e "''${_dest}/$f" ]]; then printf '%s\tFILE\n'    "$f"                       >> "$saved"
        else                            printf '%s\tMISSING\n' "$f"                       >> "$saved"
        fi
      done
      for d in "''${_dirs[@]}"; do
        if   [[ -L "''${_dest}/$d" ]]; then printf '%s\t%s\n' "$d" "$(readlink "''${_dest}/$d")" >> "$saved"
        elif [[ -e "''${_dest}/$d" ]]; then printf '%s\tDIR\n'     "$d"                      >> "$saved"
        else                            printf '%s\tMISSING\n' "$d"                      >> "$saved"
        fi
      done

      for f in "''${_files[@]}"; do rm -f  "''${_dest}/$f"; ln -s "''${_src}/$f" "''${_dest}/$f"; done
      for d in "''${_dirs[@]}";  do rm -rf "''${_dest}/$d"; ln -s "''${_src}/$d" "''${_dest}/$d"; done
      touch "$marker"
      echo "$app: edit mode active (''${_src})"
      hyprctl reload
    }

    exit_app() {
      local app=$1
      local -n _files="FILES_''${app}"
      local -n _dirs="DIRS_''${app}"
      local -n _dest="DEST_''${app}"
      local marker="''${_dest}/.editmode"
      local saved="''${_dest}/.editmode_saved_''${app}"
      local name target

      [[ ! -f "$marker" ]] && { echo "$app: not in edit mode"; return; }

      for f in "''${_files[@]}"; do rm -f "''${_dest}/$f"; done
      for d in "''${_dirs[@]}";  do rm -f "''${_dest}/$d"; done

      if [[ -f "$saved" ]]; then
        while IFS=$'\t' read -r name target; do
          case "$target" in
            FILE|DIR|MISSING) ;;
            *) ln -s "$target" "''${_dest}/$name" && echo "  restored $name → $target" ;;
          esac
        done < "$saved"
        rm -f "$saved"
      else
        echo "  warning: no saved state for $app — run a rebuild to fully restore"
      fi

      rm -f "$marker"
      echo "$app: restored"
      hyprctl reload
    }

    status_app() {
      local app=$1
      local -n _files="FILES_''${app}"
      local -n _dirs="DIRS_''${app}"
      local -n _dest="DEST_''${app}"
      local marker="''${_dest}/.editmode"

      if [[ -f "$marker" ]]; then
        echo "$app: ACTIVE"
        for f in "''${_files[@]}"; do [[ -L "''${_dest}/$f" ]] && echo "    ''${_dest}/$f → $(readlink "''${_dest}/$f")"; done
        for d in "''${_dirs[@]}";  do [[ -L "''${_dest}/$d" ]] && echo "    ''${_dest}/$d → $(readlink "''${_dest}/$d")"; done
      else
        echo "$app: inactive"
      fi
    }

    # ── Dispatch ──────────────────────────────────────────────────────────
    CMD="''${1:-}"
    TARGET="''${2:-}"

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
        [[ -z "$TARGET" ]] && echo -e "\nRun 'edit-conf exit' when done."
        ;;
      exit)
        for app in $(resolve_apps); do exit_app "$app"; done
        ;;
      status)
        for app in "''${APPS[@]}"; do status_app "$app"; done
        ;;
      *)
        for app in $(resolve_apps); do enter_app "$app"; done
        if [[ -z "$TARGET" ]]; then
          read -r
          for app in $(resolve_apps); do exit_app "$app"; done
        done
        ;;
    esac
  '';
in
{
  inherit entries editScript;
}
