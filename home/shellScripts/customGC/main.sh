#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck source=/etc/profiles/per-user/nyix/bin/admin
. admin && requiresSudo "$@"

TODAY=$(date +%Y-%m-%d)

# ── Helper: keep oldest generation of a given day in a given profile ──────────
keep_oldest_of_day() {
  local gens="$1" date_str="$2"
  echo "$gens" | grep "$date_str" | head -n1 | awk '{print $1}'
}

# ── Core cleanup function ─────────────────────────────────────────────────────
clean_profile() {
  local PROFILE="$1"
  local RUN_AS="$2" # "root" or a username to run as

  # nix-env wrapper: run as correct user
  nix_env() {
    if [[ "$RUN_AS" == "root" ]]; then
      nix-env "$@"
    else
      sudo -u "$RUN_AS" nix-env "$@"
    fi
  }

  # Check profile exists
  if [[ ! -e "$PROFILE" ]]; then
    echo "  [skip] Profile not found: $PROFILE"
    return
  fi

  echo ""
  echo "=========================================="
  echo "Profile: $PROFILE"
  echo "=========================================="

  local gens current
  gens=$(nix_env -p "$PROFILE" --list-generations 2>/dev/null | awk '{print $1, $2}')
  if [[ -z "$gens" ]]; then
    echo "  [skip] No generations found."
    return
  fi

  current=$(nix_env -p "$PROFILE" --list-generations 2>/dev/null | grep "(current)" | awk '{print $1}')

  # Today's generations
  mapfile -t gens_today < <(echo "$gens" | grep "$TODAY" | awk '{print $1}')

  # Build keep list
  local keep=("$current" "${gens_today[@]}")

  # Last 7 days: oldest of each day
  for i in {1..7}; do
    local d oldest
    d=$(date -d "$i days ago" +%Y-%m-%d)
    oldest=$(keep_oldest_of_day "$gens" "$d")
    [[ -n "$oldest" ]] && keep+=("$oldest")
  done

  # Last 30 days: oldest 2 overall
  local month_start
  month_start=$(date -d "30 days ago" +%Y-%m-%d)
  while read -r g; do
    keep+=("$g")
  done < <(echo "$gens" | awk -v start="$month_start" '$2 >= start {print $1}' | sort -n | head -n2)

  # Deduplicate keep list
  local keep_final
  keep_final=$(printf "%s\n" "${keep[@]}" | sort -un | tr '\n' ' ')

  # Build delete list
  local all_gens to_delete=()
  all_gens=$(echo "$gens" | awk '{print $1}')
  for g in $all_gens; do
    [[ -z "$g" ]] && continue
    local pattern=" $g "
    if [[ ! " $keep_final " =~ $pattern ]]; then
      to_delete+=("$g")
    fi
  done

  echo "  Current:   $current"
  echo "  Today:     ${gens_today[*]:-none}"
  echo "  Keeping:   $keep_final"
  echo "------------------------------------------"

  if [[ ${#to_delete[@]} -gt 0 ]]; then
    echo "  Deleting:  ${to_delete[*]}"
    nix_env -p "$PROFILE" --delete-generations "${to_delete[@]}"
  else
    echo "  Nothing to delete."
  fi
}

# ── Detect the real invoking user (even under sudo) ───────────────────────────
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
USER_PROFILES_DIR="$REAL_HOME/.local/state/nix/profiles"

# ── Run against all profiles ──────────────────────────────────────────────────

# 1. System profile (runs as root)
clean_profile "/nix/var/nix/profiles/system" "root"

# 2. User nix-env profile
clean_profile "$USER_PROFILES_DIR/profile" "$REAL_USER"

# 3. Home-manager profile
clean_profile "$USER_PROFILES_DIR/home-manager" "$REAL_USER"

# ── Final GC ─────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "Running nix-store --gc ..."
echo "=========================================="
nix-store --gc

echo ""
echo "Done. Store size:"
du -sh /nix/store
