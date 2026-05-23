{ pkgs, lib }:

configs:
# configs is a list of:
# { name = "hypr"; src = <path>; srcStr = "..."; destDir = "hypr"; destDir = "$HOME/.config/hypr"; files = [...]; dirs = [...]; }
# destDir  = key prefix for xdg.configFile or home.file (relative)
# dest    = full shell path used in the edit-conf script

let
  # ── entries for xdg.configFile or home.file ──────────────────────────────
  mkFile = cfg: f: {
    name = "${cfg.destDir}/${f}";
    value = {
      source = cfg.src + "/${f}";
      force = true;
    };
  };
  mkDir = cfg: d: {
    name = "${cfg.destDir}/${d}";
    value = {
      source = cfg.src + "/${d}";
      # recursive = true;
      force = true;
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
    DEST_${cfg.name}="${if cfg.destDirSet then "$HOME/${cfg.destDir}" else "$HOME"}"
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
      local -n _srcRef="SRC_''${app}"
      local -n _destRef="DEST_''${app}"

      # Resolve namerefs to normal strings to prevent expansion bugs
      local src="''${_srcRef}"
      local dest="''${_destRef}"

      # Dynamically expand $HOME if present in strings
      dest=$(eval echo "''${dest}")

      local marker="''${dest}/.editmode"
      local saved="''${dest}/.editmode_saved_''${app}"

      [[ -f "$marker" ]] && { echo "$app: already in edit mode"; return; }

      rm -f "$saved"
      mkdir -p "''${dest}"

      for f in "''${_files[@]}"; do
        if   [[ -L "''${dest}/$f" ]]; then printf '%s\t%s\n' "$f" "$(readlink "''${dest}/$f")" >> "$saved"
        elif [[ -e "''${dest}/$f" ]]; then printf '%s\tFILE\n'    "$f"                       >> "$saved"
        else                            printf '%s\tMISSING\n' "$f"                       >> "$saved"
        fi
      done
      for d in "''${_dirs[@]}"; do
        if   [[ -L "''${dest}/$d" ]]; then printf '%s\t%s\n' "$d" "$(readlink "''${dest}/$d")" >> "$saved"
        elif [[ -e "''${dest}/$d" ]]; then printf '%s\tDIR\n'     "$d"                      >> "$saved"
        else                            printf '%s\tMISSING\n' "$d"                       >> "$saved"
        fi
      done

      for f in "''${_files[@]}"; do rm -f  "''${dest}/$f"; ln -s "''${src}/$f" "''${dest}/$f"; done
      for d in "''${_dirs[@]}";  do rm -rf "''${dest:?}/$d"; ln -s "''${src}/$d" "''${dest}/$d"; done
      touch "$marker"
      echo "$app: edit mode active (''${src})"
      hyprctl reload || true
    }

    exit_app() {
      local app=$1
      local -n _files="FILES_''${app}"
      local -n _dirs="DIRS_''${app}"
      local -n _destRef="DEST_''${app}"

      local dest="''${_destRef}"
      dest=$(eval echo "''${dest}")

      local marker="''${dest}/.editmode"
      local saved="''${dest}/.editmode_saved_''${app}"
      local name target

      [[ ! -f "$marker" ]] && { echo "$app: not in edit mode"; return; }

      for f in "''${_files[@]}"; do rm -f "''${dest}/$f"; done
      for d in "''${_dirs[@]}";  do rm -rf "''${dest:?}/$d"; done

      if [[ -f "$saved" ]]; then
        while IFS=$'\t' read -r name target; do
          case "$target" in
            FILE|DIR|MISSING) ;;
            *) ln -s "$target" "''${dest}/$name" && echo "  restored $name → $target" ;;
          esac
        done < "$saved"
        rm -f "$saved"
      else
        echo "  warning: no saved state for $app — run a rebuild to fully restore"
      fi

      rm -f "$marker"
      echo "$app: restored"
      hyprctl reload || true
    }

    status_app() {
      local app=$1
      local -n _files="FILES_''${app}"
      local -n _dirs="DIRS_''${app}"
      local -n _destRef="DEST_''${app}"

      local dest="''${_destRef}"
      dest=$(eval echo "''${dest}")
      local marker="''${dest}/.editmode"

      if [[ -f "$marker" ]]; then
        echo "$app: ACTIVE"
        for f in "''${_files[@]}"; do [[ -L "''${dest}/$f" ]] && echo "    ''${dest}/$f → $(readlink "''${dest}/$f")"; done
        for d in "''${_dirs[@]}";  do [[ -L "''${dest}/$d" ]] && echo "    ''${dest}/$d → $(readlink "''${dest}/$d")"; done
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
    restore(){
      for app in $(resolve_apps); do exit_app "$app"; done
    }
    case "$CMD" in
      enter)
        for app in $(resolve_apps); do enter_app "$app"; done
        [[ -z "$TARGET" ]] && echo -e "\nRun 'edit-conf exit' when done."
        ;;
      exit)
        restore
        ;;
      status)
        for app in "''${APPS[@]}"; do status_app "$app"; done
        ;;
      *)
        for app in $(resolve_apps); do enter_app "$app"; done
        if [[ -z "$TARGET" ]]; then
          trap restore EXIT
          read -r
          restore
        fi
        ;;
    esac
  '';
in
{
  inherit entries editScript;
}
