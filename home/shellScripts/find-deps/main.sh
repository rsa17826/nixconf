#!/usr/bin/env bash
# nix-autodep — Auto-generate flake.nix by detecting missing dependencies
# Usage: nix-autodep [options] -- <command> [args...]
#
# Requires: nix (with flakes enabled), bash 4+, python3
# Optional: nix-index (for nix-locate, more accurate binary searches)

set -uo pipefail

VERSION="1"
SCRIPT_NAME="$(basename "$0")"

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
  B='\033[0;34m' C='\033[0;36m' BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
else
  R='' G='' Y='' B='' C='' BOLD='' DIM='' NC=''
fi

# ── Config (overridden by flags) ──────────────────────────────────────────────
OUTPUT_FILE="flake.nix"
SYSTEM=""
MAX_ITER=10
PYTHON_ATTR="python3"
NIXPKGS_CHANNEL="github:NixOS/nixpkgs/nixos-unstable"

# ── Global state ──────────────────────────────────────────────────────────────
CMD_ARGS=()
RESOLVED_PKGS=()   # top-level nixpkgs attrs added so far
RESOLVED_PYTHON=() # python package attrs added so far
RESOLVED_CMDS=()   # cmd names already resolved (dedup guard)
RESOLVED_PYMODS=() # python module names already resolved (dedup guard)
RESOLVED_LIBS=()   # -lFOO names already resolved (dedup guard)
LAST_STDOUT=""
LAST_STDERR=""
LAST_EXIT=0

# ── Logging ───────────────────────────────────────────────────────────────────
log() { echo -e "${B}▶${NC} $*"; }
ok() { echo -e "${G}✓${NC} $*"; }
warn() { echo -e "${Y}⚠${NC}  $*" >&2; }
err() { echo -e "${R}✗${NC} $*" >&2; }
section() { echo -e "\n${BOLD}${C}━━ $* ━━${NC}"; }
dim() { echo -e "${DIM}$*${NC}"; }
hr() { echo -e "${DIM}────────────────────────────────────${NC}"; }

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF

${BOLD}nix-autodep${NC} v${VERSION} — Auto-generate flake.nix by detecting missing dependencies

${BOLD}USAGE${NC}
  ${SCRIPT_NAME} [options] -- <command> [args...]

${BOLD}OPTIONS${NC}
  -o, --output FILE       Output path for flake.nix  (default: ./flake.nix)
  -s, --system SYSTEM     Nix system triple           (default: auto-detect)
  -p, --python ATTR       Python attr to use          (default: python3)
  -c, --channel URL       nixpkgs flake URL           (default: nixos-unstable)
  -i, --iterations N      Max resolution iterations   (default: 10)
  -h, --help              Show this help

${BOLD}EXAMPLES${NC}
  ${SCRIPT_NAME} -- python3 myapp.py
  ${SCRIPT_NAME} -- ./build.sh
  ${SCRIPT_NAME} -o ~/project/flake.nix -- node index.js
  ${SCRIPT_NAME} -p python311 -- python3 train.py

${BOLD}HOW IT WORKS${NC}
  1. Runs your command in a stripped environment (no PATH pollution)
  2. Parses stderr for "command not found" and Python import errors
  3. Searches nixpkgs for packages that provide each missing dep
  4. Lets you pick the right package interactively
  5. Re-runs with those packages to find any remaining deps
  6. Writes (or updates) flake.nix when everything resolves

${BOLD}NOTES${NC}
  • Needs flakes enabled: add 'experimental-features = nix-command flakes'
    to /etc/nix/nix.conf (or ~/.config/nix/nix.conf)
  • Install nix-index for more accurate binary → package lookups:
    nix-env -iA nixpkgs.nix-index && nix-index

EOF
  exit 0
}

# ── Argument parsing ──────────────────────────────────────────────────────────
parse_args() {
  if [[ $# -eq 0 ]]; then usage; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -o | --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -s | --system)
      SYSTEM="$2"
      shift 2
      ;;
    -p | --python)
      PYTHON_ATTR="$2"
      shift 2
      ;;
    -c | --channel)
      NIXPKGS_CHANNEL="$2"
      shift 2
      ;;
    -i | --iterations)
      MAX_ITER="$2"
      shift 2
      ;;
    -h | --help) usage ;;
    --)
      shift
      CMD_ARGS=("$@")
      break
      ;;
    -*)
      err "Unknown option: $1"
      echo "Run '${SCRIPT_NAME} --help' for usage."
      exit 1
      ;;
    *)
      err "Unexpected argument: $1 (did you forget '--'?)"
      exit 1
      ;;
    esac
  done

  if [[ ${#CMD_ARGS[@]} -eq 0 ]]; then
    err "No command specified."
    echo "Usage: ${SCRIPT_NAME} [options] -- <command> [args...]"
    exit 1
  fi
}

# ── Preflight checks ──────────────────────────────────────────────────────────
preflight() {
  if ! command -v nix &>/dev/null; then
    err "nix not found in PATH. Install Nix first: https://nixos.org/download"
    exit 1
  fi

  if ! command -v python3 &>/dev/null; then
    err "python3 not found. This script uses python3 to parse nix search JSON."
    exit 1
  fi

  # Warn if flakes probably not enabled
  if ! nix flake --help &>/dev/null 2>&1; then
    warn "Nix flakes may not be enabled."
    warn "Add to /etc/nix/nix.conf:  experimental-features = nix-command flakes"
  fi

  if command -v nix-locate &>/dev/null; then
    ok "nix-locate found — will use for accurate binary → package mapping"
  else
    dim "  nix-locate not found. Using 'nix search' (less precise for binaries)."
    dim "  For better results: nix-env -iA nixpkgs.nix-index && nix-index"
  fi
}

# ── System detection ──────────────────────────────────────────────────────────
detect_system() {
  [[ -n "$SYSTEM" ]] && return
  local arch
  arch=$(uname -m)
  case "$(uname -s)" in
  Linux) SYSTEM="${arch}-linux" ;;
  Darwin) SYSTEM="${arch}-darwin" ;;
  *) SYSTEM="x86_64-linux" ;;
  esac
}

# ── Load existing flake.nix ───────────────────────────────────────────────────
# If OUTPUT_FILE already exists, parse its buildInputs and pre-populate
# RESOLVED_PKGS/RESOLVED_PYTHON so this run extends rather than replaces.
load_existing_flake() {
  [[ -f "$OUTPUT_FILE" ]] || return 0
  log "Found existing ${BOLD}${OUTPUT_FILE}${NC} — loading packages as starting point..."

  local parsed
  parsed=$(
    python3 "$OUTPUT_FILE" "$PYTHON_ATTR" <<'PARSEEOF'
import sys, re
flake_path = sys.argv[1]
py_attr    = sys.argv[2]
with open(flake_path) as f:
    text = f.read()
bi = re.search(r'buildInputs\s*=\s*\[(.*?)\]', text, re.DOTALL)
if not bi:
    sys.exit(0)
block = bi.group(1)
for m in re.finditer(r'pkgs\.([a-zA-Z0-9_./-]+)', block):
    attr = m.group(1)
    if py_attr in attr or attr.startswith('python'):
        continue
    print("PKG:" + attr)
py_m = re.search(r'withPackages\s*\([^)]*\)\s*\[(.*?)\]', block, re.DOTALL)
if py_m:
    for word in py_m.group(1).split():
        word = word.strip()
        if word and not word.startswith('#'):
            print("PY:" + word)
PARSEEOF
  ) || true

  while IFS= read -r line; do
    case "$line" in
    PKG:*)
      local attr="${line#PKG:}"
      _in_array "$attr" "${RESOLVED_PKGS[@]:-}" || {
        RESOLVED_PKGS+=("$attr")
        ok "  Loaded: pkgs.${attr}"
      }
      ;;
    PY:*)
      local mod="${line#PY:}"
      _in_array "$mod" "${RESOLVED_PYTHON[@]:-}" || {
        RESOLVED_PYTHON+=("$mod")
        ok "  Loaded python: ${mod}"
      }
      ;;
    esac
  done <<<"$parsed"
  echo ""
}

# ── Clean-environment runner ──────────────────────────────────────────────────
# Strips PATH down to just nix and coreutils, then runs CMD_ARGS.
# If RESOLVED_PKGS is non-empty, wraps in `nix shell` so those packages
# are available on PATH for this test run.
run_clean() {
  LAST_STDOUT=$(mktemp /tmp/nix-autodep-stdout.XXXXXX)
  LAST_STDERR=$(mktemp /tmp/nix-autodep-stderr.XXXXXX)
  LAST_EXIT=0

  # Minimal PATH: only nix itself + bare system utils
  local base_path
  base_path="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"

  echo ""
  hr

  if [[ ${#RESOLVED_PKGS[@]} -gt 0 ]]; then
    local pkg_flags=()
    for pkg in "${RESOLVED_PKGS[@]}"; do
      pkg_flags+=("nixpkgs#${pkg}")
    done

    log "Re-running with: ${BOLD}${RESOLVED_PKGS[*]}${NC}"
    log "Command: ${BOLD}${CMD_ARGS[*]}${NC}"
    echo ""

    # Key trick: run inside nix shell so our packages are on PATH, then use
    # env -i with $PATH passed through (not the host PATH — nix shell's PATH).
    # This strips unrelated host packages while keeping our resolved ones.
    local cmd_q
    cmd_q=$(printf '%q ' "${CMD_ARGS[@]}")

    nix shell "${pkg_flags[@]}" --command \
      bash -c "exec env -i HOME='$HOME' TERM='${TERM:-xterm-256color}' PATH=\"\$PATH\" ${cmd_q}" \
      >"$LAST_STDOUT" 2>"$LAST_STDERR" ||
      LAST_EXIT=$?
  else
    log "Running in clean environment: ${BOLD}${CMD_ARGS[*]}${NC}"
    echo ""

    # Direct redirection (not process substitution) avoids the async tee race
    # condition where parse_missing reads empty files before tee has flushed.
    env -i \
      HOME="$HOME" \
      TERM="${TERM:-xterm-256color}" \
      PATH="$base_path" \
      "${CMD_ARGS[@]}" \
      >"$LAST_STDOUT" 2>"$LAST_STDERR" ||
      LAST_EXIT=$?
  fi

  # Show captured output to the terminal now that files are fully written
  [[ -s "$LAST_STDOUT" ]] && cat "$LAST_STDOUT"
  [[ -s "$LAST_STDERR" ]] && cat "$LAST_STDERR" >&2

  echo ""
  hr
}

# ── Error parser ──────────────────────────────────────────────────────────────
# Reads LAST_STDOUT + LAST_STDERR and populates:
#   NEW_CMDS   — command names not found this iteration
#   NEW_PYTHON — python module names that failed to import this iteration
parse_missing() {
  NEW_CMDS=()
  NEW_PYTHON=()
  NEW_LIBS=()

  local combined
  combined=$(cat "$LAST_STDOUT" "$LAST_STDERR" 2>/dev/null)

  while IFS= read -r line; do

    # ── "command not found" patterns ──
    #
    #   bash: foo: command not found          (bash interactive)
    #   foo: command not found                (generic)
    #   sh: 1: foo: not found                 (dash/sh)
    #   env: 'go': No such file or directory  (env can't exec the binary)
    #   /usr/bin/env: 'go': No such ...       (full-path env variant)
    #   exec: 'foo': not found                (exec builtin)
    local cmd=""

    if [[ "$line" =~ ([[:alnum:]_.-]+)[[:space:]]*:[[:space:]]*(command not found) ]]; then
      # "bash: foo: command not found"
      cmd="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ [[:space:]]([[:alnum:]_.-]+):[[:space:]]not[[:space:]]found ]]; then
      # "sh: 1: foo: not found"
      cmd="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ (exec|env):[[:space:]]+([^[:space:]:]+):[[:space:]]*(No[[:space:]]such|not[[:space:]]found|cannot[[:space:]]execute) ]]; then
      # "env: ‘go’: No such file or directory" — token between colons; quotes stripped below.
      # glibc env uses Unicode smart quotes (U+2018/2019, 0xE2 0x80 0x98/99) not ASCII 0x27.
      cmd="${BASH_REMATCH[2]}"
    elif [[ "$line" =~ No[[:space:]]such[[:space:]]file[[:space:]]or[[:space:]]directory ]]; then
      # Fallback: grab the colon-delimited token before "No such"
      if [[ "$line" =~ :[[:space:]]+([^/:[:space:]]+):[[:space:]]*No[[:space:]]such ]]; then
        cmd="${BASH_REMATCH[1]}"
      fi
    fi

    # Strip ASCII and Unicode smart quotes via python3 (bash substitution only sees bytes,
    # missing multi-byte U+2018/2019/201C/201D that some env builds output)
    [[ -n "$cmd" ]] && cmd=$(_strip_quotes "$cmd")

    if [[ -n "$cmd" ]]; then
      # Skip pure numbers, skip already-resolved
      if ! [[ "$cmd" =~ ^[0-9]+$ ]] && ! _in_array "$cmd" "${RESOLVED_CMDS[@]:-}"; then
        NEW_CMDS+=("$cmd")
      fi
    fi

    # ── Linker "cannot find -lFOO" ──
    #   ld.bfd: cannot find -lX11: No such file or directory
    if [[ "$line" =~ cannot[[:space:]]find[[:space:]]-l([[:alnum:]_+.-]+) ]]; then
      local lib="${BASH_REMATCH[1]}"
      # Skip always-present glibc pseudo-libs
      if ! [[ "$lib" =~ ^(m|dl|rt|pthread|resolv|c|stdc[+][+]|gcc_s|atomic)$ ]]; then
        _in_array "$lib" "${RESOLVED_LIBS[@]:-}" || NEW_LIBS+=("$lib")
      fi
    fi
    # ── Python import errors ──
    #   ModuleNotFoundError: No module named 'requests'
    #   ModuleNotFoundError: No module named 'PIL'  (top-level of pillow)
    #   ImportError: No module named foo
    #   ImportError: cannot import name 'X' from 'foo'
    local pymod=""

    if [[ "$line" =~ ModuleNotFoundError:[[:space:]]*No[[:space:]]+module[[:space:]]+named[[:space:]]+[\'\"]([^.\'\"]+) ]]; then
      pymod="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ImportError:[[:space:]]*(No[[:space:]]+module[[:space:]]+named|cannot[[:space:]]+import[[:space:]]+name)[[:space:]]+[\'\"]([^.\'\"]+) ]]; then
      pymod="${BASH_REMATCH[2]}"
    fi

    if [[ -n "$pymod" ]] && ! _in_array "$pymod" "${RESOLVED_PYMODS[@]:-}"; then
      NEW_PYTHON+=("$pymod")
    fi

  done <<<"$combined"

  # Deduplicate within this batch
  # For NEW_CMDS
  mapfile -t NEW_CMDS < <(printf '%s\n' "${NEW_CMDS[@]:-}" | sort -u | grep -v '^$' || true)

  # For NEW_PYTHON
  mapfile -t NEW_PYTHON < <(printf '%s\n' "${NEW_PYTHON[@]:-}" | sort -u | grep -v '^$' || true)
}

# ── Array helpers ─────────────────────────────────────────────────────────────
_in_array() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# Strip ASCII and Unicode smart quotes from a string.
# Some env implementations (glibc) use U+2018/2019 (E2 80 98/99) instead of
# ASCII 0x27, which bash character classes and parameter substitution miss.
_strip_quotes() {
  printf '%s' "$1" | python3 -c "
import sys
s = sys.stdin.read()
for c in (\"'\", '\"', '\u2018', '\u2019', '\u201c', '\u201d'):
    s = s.replace(c, '')
print(s.strip())
" || printf '%s' "${1//\'/}"
}

# ── Package searchers ─────────────────────────────────────────────────────────

# Search for a nix package that provides a given binary name.
# Prints one candidate per line: "pkgattr  # description"
search_for_cmd() {
  local cmd="$1"
  local results=()

  # 1. nix-locate --whole-name "bin/go" matches ONLY a file named exactly "go"
  #    inside a bin/ directory. Plain --minimal "bin/go" is a substring match
  #    and returns hundreds of false positives. --top-level does not exist.
  if command -v nix-locate &>/dev/null; then
    local loc_out
    loc_out=$(nix-locate --minimal --whole-name "bin/${cmd}" 2>/dev/null | head -30) || true
    if [[ -n "$loc_out" ]]; then
      while IFS= read -r raw; do
        [[ -z "$raw" ]] && continue
        # Output format: "pkgAttr.outputName"  e.g. "go.out", "curl.out"
        # Strip the trailing output suffix (.out .bin .dev .lib .man etc.)
        local attr="${raw%.*}"
        # Skip non-runnable plugin/library namespaces
        if [[ "$attr" =~ ^(vimPlugin|emacsPackage|vimExtraPlugin|font|python[0-9]*Package|perl[0-9]*Package|ruby[0-9]*Package|lua[0-9]*Package|haskellPackage|nodePackage|ocaml[0-9]*Package) ]]; then
          continue
        fi
        results+=("${attr}  # (nix-locate: provides bin/${cmd})")
      done <<<"$loc_out"
    fi
  fi

  # 2. nix search nixpkgs as supplement / fallback
  if [[ ${#results[@]} -lt 5 ]]; then
    local json
    json=$(nix search nixpkgs "$cmd" --json 2>/dev/null) || true
    if [[ -n "$json" ]]; then
      local extra
      extra=$(
        python3 - "$cmd" <<'PYEOF'
import json, sys

cmd = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

SKIP_NS = ("vimPlugins", "emacsPackages", "fonts.", "python3Packages",
           "python2Packages", "nodePackages", "perlPackages", "luaPackages")

scored = []
for key, meta in data.items():
    pkg  = key.split(".")[-1]
    desc = (meta.get("description") or "")[:72]
    score = 0
    if pkg == cmd:            score = 100
    elif pkg.startswith(cmd): score = 60
    elif cmd in pkg:          score = 30
    if any(ns in key for ns in SKIP_NS):
        score -= 60
    if score > 0:
        scored.append((score, pkg, desc))

scored.sort(key=lambda x: (-x[0], x[1]))
seen = set()
for _, pkg, desc in scored[:10]:
    if pkg not in seen:
        seen.add(pkg)
        print(f"{pkg}  # {desc}")
PYEOF
      ) || true
      while IFS= read -r line; do
        [[ -n "$line" ]] && results+=("$line")
      done <<<"$extra"
    fi
  fi

  # Deduplicate by attr name (nix-locate and nix search may overlap)
  local seen_attrs=()
  local deduped=()
  for entry in "${results[@]:-}"; do
    local attr
    attr=$(echo "$entry" | awk '{print $1}')
    if ! _in_array "$attr" "${seen_attrs[@]:-}"; then
      seen_attrs+=("$attr")
      deduped+=("$entry")
    fi
  done

  printf '%s\n' "${deduped[@]:-}"
}

# Search for a nix package providing a C library (-lFOO).
# Prints one candidate per line: "pkgattr  # description"
search_for_lib() {
  local lib="$1"
  local results=()

  # Well-known -l name -> nixpkgs attr mappings.
  # Keys with hyphens/dots MUST be quoted — unquoted [gtk-3] is arithmetic (gtk - 3).
  local -A KNOWN=(
    [X11]="xorg.libX11" [Xrandr]="xorg.libXrandr" [Xxf86vm]="xorg.libXxf86vm"
    [Xi]="xorg.libXi" [Xcursor]="xorg.libXcursor" [Xinerama]="xorg.libXinerama"
    [Xext]="xorg.libXext" [Xfixes]="xorg.libXfixes" [Xrender]="xorg.libXrender"
    [Xtst]="xorg.libXtst" [GL]="libGL" [GLU]="libGLU"
    [EGL]="libGL" [vulkan]="vulkan-loader" [z]="zlib"
    [ssl]="openssl" [crypto]="openssl" [curl]="curl"
    [sqlite3]="sqlite" [ffi]="libffi" [png]="libpng"
    [jpeg]="libjpeg" [tiff]="libtiff" [freetype]="freetype"
    [fontconfig]="fontconfig" [alsa]="alsa-lib" [pulse]="libpulseaudio"
    ["gtk-3"]="gtk3" ["gtk-4"]="gtk4" ["glib-2.0"]="glib"
    ["gobject-2.0"]="glib" ["dbus-1"]="dbus" ["wayland-client"]="wayland"
    ["wayland-egl"]="wayland" ["pipewire-0.3"]="pipewire" ["usb-1.0"]="libusb1"
    [avcodec]="ffmpeg" [avformat]="ffmpeg" [avutil]="ffmpeg"
    [udev]="udev" [portaudio]="portaudio" ["pangocairo-1.0"]="pango"
    ["pango-1.0"]="pango" [cairo]="cairo"
  )
  [[ -v "KNOWN[$lib]" ]] && results+=("${KNOWN[$lib]}  # (known: -l${lib})")

  # nix-locate: try exact libFOO.so, then substring
  if command -v nix-locate &>/dev/null && [[ ${#results[@]} -lt 3 ]]; then
    local loc
    loc=$(nix-locate --minimal --whole-name "lib/lib${lib}.so" 2>/dev/null | head -15) || true
    [[ -z "$loc" ]] && loc=$(nix-locate --minimal "lib/lib${lib}" 2>/dev/null | head -15) || true
    while IFS= read -r raw; do
      [[ -z "$raw" ]] && continue
      local attr="${raw%.*}"
      results+=("${attr}  # (nix-locate: lib${lib}.so)")
    done <<<"$loc"
  fi

  # nix search fallback
  if [[ ${#results[@]} -lt 3 ]]; then
    local json
    json=$(nix search nixpkgs "lib${lib}" --json 2>/dev/null) || true
    if [[ -n "$json" ]]; then
      local py_out
      py_out=$(echo "$json" | python3 -c "
import json,sys
lib=sys.argv[1] if len(sys.argv)>1 else ''
try: data=json.load(sys.stdin)
except: sys.exit(0)
scored=[]
for k,v in data.items():
    pkg=k.split('.')[-1]; desc=(v.get('description') or '')[:70]
    s=0
    lo=pkg.lower(); ll=lib.lower()
    if lo==f'lib{ll}' or lo==ll: s=80
    elif ll in lo: s=40
    if s>0: scored.append((s,pkg,desc))
scored.sort(key=lambda x:(-x[0],x[1]))
seen=set()
for _,pkg,desc in scored[:8]:
    if pkg not in seen: seen.add(pkg); print(f'{pkg}  # {desc}')
" "$lib") || true
      while IFS= read -r line; do [[ -n "$line" ]] && results+=("$line"); done <<<"$py_out"
    fi
  fi

  # Deduplicate
  local seen_a=() deduped=()
  for entry in "${results[@]:-}"; do
    local a
    a=$(echo "$entry" | awk '{print $1}')
    _in_array "$a" "${seen_a[@]:-}" || {
      seen_a+=("$a")
      deduped+=("$entry")
    }
  done
  printf '%s\n' "${deduped[@]:-}"
}

# Search for a nixpkgs python package for a given module name.
# Prints one candidate per line: "pkgattr  # description"
search_for_python() {
  local module="$1"
  local normalized="${module//_/-}"

  local json=""
  json=$(nix search nixpkgs "python.*${normalized}" --json 2>/dev/null) || true

  # If nothing, try bare module name
  if [[ -z "$json" ]] || [[ "$json" == "{}" ]]; then
    json=$(nix search nixpkgs "${module}" --json 2>/dev/null) || true
  fi

  [[ -z "$json" ]] && return

  python3 - "$module" "$normalized" <<'PYEOF'
import json, sys

module   = sys.argv[1]
normed   = sys.argv[2]

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

scored = []
for key, meta in data.items():
    pkg  = key.split(".")[-1]
    desc = (meta.get("description") or "")[:72]
    score = 0
    if "python" in key.lower():                           score += 40
    lo = pkg.lower()
    m  = module.lower()
    n  = normed.lower()
    if lo == m or lo == n:                                score += 80
    elif lo.startswith(m) or lo.startswith(n):            score += 40
    elif m in lo or n in lo:                              score += 20
    scored.append((score, pkg, desc))

scored.sort(key=lambda x: (-x[0], x[1]))
seen = set()
for _, pkg, desc in scored[:12]:
    if pkg not in seen:
        seen.add(pkg)
        print(f"{pkg}  # {desc}")
PYEOF
}

# ── Interactive selector ──────────────────────────────────────────────────────
# Contract: all display goes to >&2 (so it reaches the terminal even when this
# function is called inside $(...) command substitution); only the final chosen
# attr is printed to stdout so the caller can capture it cleanly.
prompt_select() {
  local dep_name="$1"
  local dep_kind="$2" # "command" or "Python module"
  shift 2
  local options=("$@")

  echo "" >&2
  section "Missing ${dep_kind}: ${BOLD}${dep_name}${NC}" >&2
  echo "" >&2

  if [[ ${#options[@]} -eq 0 ]]; then
    warn "No packages found automatically for '${dep_name}'."
    echo "" >&2
    echo -e "  ${C}[m]${NC}  Enter package name manually" >&2
    echo -e "  ${C}[s]${NC}  Skip (don't add anything for this dep)" >&2
    echo "" >&2
    while true; do
      read -rp "Choice [m/s]: " choice </dev/tty
      case "$choice" in
      m | M)
        read -rp "  Package attr (e.g. curl, python3Packages.requests): " m </dev/tty
        echo "${m:-}"
        return
        ;;
      s | S) return ;;
      *) warn "Enter 'm' to type manually, or 's' to skip." ;;
      esac
    done
  fi

  echo -e "  Found ${#options[@]} candidate(s) in nixpkgs:\n" >&2

  local i=1
  for opt in "${options[@]}"; do
    local pkgname rest
    pkgname=$(echo "$opt" | awk '{print $1}')
    rest=$(echo "$opt" | cut -d' ' -f2-)
    printf "  ${C}[%2d]${NC}  ${BOLD}%-30s${NC} ${DIM}%s${NC}\n" "$i" "$pkgname" "$rest" >&2
    ((i++))
  done

  echo "" >&2
  echo -e "  ${C}[m]${NC}  Enter package attr manually" >&2
  echo -e "  ${C}[s]${NC}  Skip this dependency" >&2
  echo "" >&2

  while true; do
    read -rp "Choice (1-${#options[@]} / m / s): " choice </dev/tty
    case "$choice" in
    [0-9]*)
      if ((choice >= 1 && choice <= ${#options[@]})); then
        echo "${options[$((choice - 1))]}" | awk '{print $1}'
        return
      fi
      warn "Enter a number between 1 and ${#options[@]}, 'm', or 's'." >&2
      ;;
    m | M)
      read -rp "  Package attr: " m </dev/tty
      echo "${m:-}"
      return
      ;;
    s | S)
      return
      ;;
    *)
      warn "Enter a number between 1 and ${#options[@]}, 'm', or 's'." >&2
      ;;
    esac
  done
}

# ── flake.nix writer ──────────────────────────────────────────────────────────
write_flake() {
  # Build the buildInputs lines
  local inputs=""
  for pkg in "${RESOLVED_PKGS[@]:-}"; do
    inputs+="            pkgs.${pkg}\n"
  done

  # Python block (if any)
  local pyblock=""
  if [[ ${#RESOLVED_PYTHON[@]} -gt 0 ]]; then
    pyblock="            (pkgs.${PYTHON_ATTR}.withPackages (ps: with ps; [\n"
    for pypkg in "${RESOLVED_PYTHON[@]}"; do
      pyblock+="              ${pypkg}\n"
    done
    pyblock+="            ]))\n"
  fi

  local all_inputs
  all_inputs=$(printf '%b' "${inputs}${pyblock}" | grep -v '^[[:space:]]*$' || true)

  local cmd_str="${CMD_ARGS[*]}"
  local timestamp
  timestamp=$(date -u '+%Y-%m-%d %H:%M UTC')

  # Overwrite unconditionally — existing packages were already loaded at startup

  _write_flake_file "$all_inputs" "$cmd_str" "$timestamp"
  ok "Wrote ${BOLD}${OUTPUT_FILE}${NC}"
}

_write_flake_file() {
  local all_inputs="$1"
  local cmd_str="$2"
  local timestamp="$3"

  # Note: \${system} is intentional — it's a nix expression, not bash
  cat >"$OUTPUT_FILE" <<FLAKE
{
  # Generated by nix-autodep ${VERSION} on ${timestamp}
  # Command: ${cmd_str}
  description = "Dev shell for: ${cmd_str}";

  inputs = {
    nixpkgs.url     = "${NIXPKGS_CHANNEL}";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.\${system};
      in {
        # Enter with: nix develop
        devShells.default = pkgs.mkShell {
          buildInputs = [
${all_inputs}
          ];
        };

        # Run directly with: nix run
        packages.default = pkgs.writeShellScriptBin "run" ''
          exec ${cmd_str} "\$@"
        '';
      });
}
FLAKE
}

_preview_flake() {
  _write_flake_file "$1" "$2" "$3" 2>/dev/null
  echo ""
  dim "─── Preview of flake.nix ───"
  cat "$OUTPUT_FILE"
  dim "────────────────────────────"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  section "Resolution summary"
  echo ""

  if [[ ${#RESOLVED_PKGS[@]} -gt 0 ]]; then
    echo -e "${BOLD}Top-level packages:${NC}"
    for pkg in "${RESOLVED_PKGS[@]}"; do
      echo -e "  ${G}+${NC} pkgs.${pkg}"
    done
    echo ""
  fi

  if [[ ${#RESOLVED_PYTHON[@]} -gt 0 ]]; then
    echo -e "${BOLD}Python packages (${PYTHON_ATTR}.withPackages):${NC}"
    for pkg in "${RESOLVED_PYTHON[@]}"; do
      echo -e "  ${G}+${NC} ${pkg}"
    done
    echo ""
  fi

  if [[ ${#RESOLVED_PKGS[@]} -eq 0 && ${#RESOLVED_PYTHON[@]} -eq 0 ]]; then
    echo -e "  ${Y}No packages were added.${NC}"
    echo ""
    return
  fi

  echo -e "${BOLD}${OUTPUT_FILE}${NC} written."
  echo ""
  echo -e "${DIM}Next steps:${NC}"
  echo -e "  ${C}nix develop${NC}                     # enter the dev shell"
  echo -e "  ${C}nix develop --command ${CMD_ARGS[*]}${NC}  # run directly in the shell"
  echo ""
}

# ── Main loop ─────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"
  preflight
  detect_system

  section "nix-autodep v${VERSION}"
  echo ""
  log "Command : ${BOLD}${CMD_ARGS[*]}${NC}"
  log "System  : ${BOLD}${SYSTEM}${NC}"
  log "Output  : ${BOLD}${OUTPUT_FILE}${NC}"
  log "Max iter: ${BOLD}${MAX_ITER}${NC}"

  load_existing_flake

  local iteration=0

  while ((iteration < MAX_ITER)); do
    ((iteration++))
    section "Iteration ${iteration} / ${MAX_ITER}"

    run_clean # sets LAST_EXIT, LAST_STDOUT, LAST_STDERR

    if [[ $LAST_EXIT -eq 0 ]]; then
      ok "Command succeeded! Dependency resolution complete."
      break
    fi

    log "Exit code ${LAST_EXIT} — scanning output for missing dependencies..."
    parse_missing # sets NEW_CMDS, NEW_PYTHON

    if [[ ${#NEW_CMDS[@]} -eq 0 && ${#NEW_PYTHON[@]} -eq 0 && ${#NEW_LIBS[@]} -eq 0 ]]; then
      warn "Command failed (exit ${LAST_EXIT}) but no recognizable missing deps found."
      warn "Check the output above. You may need to add packages manually."
      break
    fi

    log "Detected missing:"
    [[ ${#NEW_CMDS[@]} -gt 0 ]] && echo -e "  Commands : ${BOLD}${NEW_CMDS[*]}${NC}"
    [[ ${#NEW_PYTHON[@]} -gt 0 ]] && echo -e "  Python   : ${BOLD}${NEW_PYTHON[*]}${NC}"
    [[ ${#NEW_LIBS[@]} -gt 0 ]] && echo -e "  C libs   : ${BOLD}${NEW_LIBS[*]}${NC}"

    local added_this_round=false

    # ── Resolve missing commands ──
    for cmd in "${NEW_CMDS[@]:-}"; do
      [[ -z "$cmd" ]] && continue

      log "Searching nixpkgs for binary '${BOLD}${cmd}${NC}'..."
      local options=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && options+=("$line")
      done < <(search_for_cmd "$cmd")

      local selected
      selected=$(prompt_select "$cmd" "command" "${options[@]:-}")

      if [[ -n "$selected" ]]; then
        RESOLVED_PKGS+=("$selected")
        RESOLVED_CMDS+=("$cmd")
        added_this_round=true
        ok "Added: ${BOLD}nixpkgs#${selected}${NC}"
      else
        warn "Skipped '${cmd}' — you may need to add it manually later."
        RESOLVED_CMDS+=("$cmd") # mark as handled so we don't ask again
      fi
    done

    # ── Resolve missing C libraries (-lFOO) ──
    for lib in "${NEW_LIBS[@]:-}"; do
      [[ -z "$lib" ]] && continue
      log "Searching nixpkgs for C library '${BOLD}-l${lib}${NC}'..."
      local options=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && options+=("$line")
      done < <(search_for_lib "$lib")

      local selected
      selected=$(prompt_select "-l${lib}" "C library" "${options[@]:-}")

      if [[ -n "$selected" ]]; then
        RESOLVED_PKGS+=("$selected")
        RESOLVED_LIBS+=("$lib")
        added_this_round=true
        ok "Added: ${BOLD}nixpkgs#${selected}${NC}"
      else
        warn "Skipped -l${lib}."
        RESOLVED_LIBS+=("$lib")
      fi
    done

    # ── Resolve missing Python modules ──
    for mod in "${NEW_PYTHON[@]:-}"; do
      [[ -z "$mod" ]] && continue

      log "Searching nixpkgs for Python module '${BOLD}${mod}${NC}'..."
      local options=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && options+=("$line")
      done < <(search_for_python "$mod")

      local selected
      selected=$(prompt_select "$mod" "Python module" "${options[@]:-}")

      if [[ -n "$selected" ]]; then
        RESOLVED_PYTHON+=("$selected")
        RESOLVED_PYMODS+=("$mod")
        added_this_round=true
        ok "Added Python pkg: ${BOLD}${selected}${NC}"
      else
        warn "Skipped Python module '${mod}'."
        RESOLVED_PYMODS+=("$mod")
      fi
    done

    # If no new packages were chosen this round, stop iterating
    if ! $added_this_round; then
      warn "No new packages selected — stopping iteration."
      break
    fi
  done

  # ── Generate output ──────────────────────────────────────────────────────
  if [[ ${#RESOLVED_PKGS[@]} -eq 0 && ${#RESOLVED_PYTHON[@]} -eq 0 ]]; then
    warn "No packages selected. Nothing to write."
    exit 0
  fi

  section "Writing ${OUTPUT_FILE}"
  write_flake
  print_summary
}

# Cleanup temp files on exit
_cleanup() {
  [[ -n "${LAST_STDOUT:-}" && -f "${LAST_STDOUT:-}" ]] && rm -f "$LAST_STDOUT"
  [[ -n "${LAST_STDERR:-}" && -f "${LAST_STDERR:-}" ]] && rm -f "$LAST_STDERR"
}
trap _cleanup EXIT

main "$@"
