#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
SRC_URL="https://raw.githubusercontent.com/puckzxz/NotAnotherAnimeTheme/refs/heads/master/NotAnotherAnimeTheme.theme.css"
BG_IMAGE="${1:-./bg.png}"
OUT_FILE="${2:-./NotAnotherAnimeTheme.merged.css}"
TMP_BASE="$(mktemp)"
TMP_APPEND="$(mktemp)"
cat <<'EOF' >>"$TMP_BASE"
    /* ==UserStyle==
@name           discord.com
@namespace      github.com/openstyles/stylus
@version        1.0.0
@description    A new userstyle
@author         Me
==/UserStyle== */
@-moz-document domain("discord.com") {
  [class*="premium"],
  [class*="Upsell"],
  [class*="upsell"],
  [class*="upsellContainer"],
  [class*="premiumTab"],
  :is( [class*="premiumTrialAcknowledgedBadge"],
  [class*="premiumTrialBadge"]),
  [style="background-color: var(--status-danger);"],
  .container__8279f, .container__0d0f9, .containerWithMargin__0d0f9,
  [class*="colorPremium"],
  div>a[href="/shop"],
  div>a[href="/store"],
  [class*="popover"]/* :has-text("Go to Shop") */ {
    display: none !important;
    visibility: hidden !important;
    width: 0 !important;
    height: 0 !important;
  }
  .bd-fallback-editor {
    background-color: #111;
  }
EOF
trap 'rm -f "$TMP_BASE" "$TMP_APPEND"' EXIT

echo "==> Downloading base theme CSS..."
curl -sSL "$SRC_URL" >>"$TMP_BASE"

echo "==> Scanning for @import url(...) lines pointing to .css files..."
: >"$TMP_APPEND"

# Extract every https URL ending in .css referenced via @import url(...) or url(...)
mapfile -t CSS_URLS < <(grep -oE 'url\(https?://[^)]+\.css\)' "$TMP_BASE" | sed -E 's/url\((.*)\)/\1/')

if [ "${#CSS_URLS[@]}" -eq 0 ]; then
  echo "No linked .css imports found."
else
  for url in "${CSS_URLS[@]}"; do
    echo "  -> Found imported stylesheet: $url"
    echo "  -> Removing its line from base file"
    # Remove any line that contains this exact url(...) reference
    grep -vF "$url" "$TMP_BASE" >"${TMP_BASE}.tmp" && mv "${TMP_BASE}.tmp" "$TMP_BASE"

    echo "  -> Downloading and appending its contents"
    {
      echo ""
      echo "/* ===== Inlined from: $url ===== */"
      curl -sSL "$url"
      echo ""
    } >>"$TMP_APPEND"
  done
fi

echo "==> Combining base + appended imported CSS..."
cat "$TMP_BASE" "$TMP_APPEND" >"$OUT_FILE"

# --- Embed background image as data URI ---
if [ -f "$BG_IMAGE" ]; then
  echo "==> Encoding $BG_IMAGE as base64 data URI..."
  ext="${BG_IMAGE##*.}"
  case "$ext" in
  jpg | jpeg) mime="image/jpeg" ;;
  png) mime="image/png" ;;
  webp) mime="image/webp" ;;
  gif) mime="image/gif" ;;
  *) mime="image/png" ;;
  esac

  TMP_DATAURI="$(mktemp)"
  trap 'rm -f "$TMP_BASE" "$TMP_APPEND" "$TMP_DATAURI"' EXIT

  {
    printf 'data:%s;base64,' "$mime"
    base64 -w0 "$BG_IMAGE"
  } >"$TMP_DATAURI"

  echo "==> Replacing --theme-background-image value with data URI..."
  # Replace the whole existing declaration line regardless of its current URL.
  # Data URI can be huge (megabytes), so it's passed via a file, never as an
  # argv string, to avoid "Argument list too long" (E2BIG) from sed/awk.
  if grep -q -- '--theme-background-image:' "$OUT_FILE"; then
    awk -v uri_file="$TMP_DATAURI" '
            BEGIN {
                getline uri < uri_file
                close(uri_file)
            }
            /--theme-background-image:[[:space:]]*url\(/ {
                sub(/--theme-background-image:[[:space:]]*url\([^)]*\);/, "--theme-background-image: url(" uri ");")
            }
            { print }
        ' "$OUT_FILE" >"${OUT_FILE}.tmp" && mv "${OUT_FILE}.tmp" "$OUT_FILE"
  else
    echo "  WARNING: --theme-background-image declaration not found; appending a new rule at bottom."
    {
      echo ""
      echo ":root {"
      printf '  --theme-background-image: url(%s);\n' "$(cat "$TMP_DATAURI")"
      echo "}"
    } >>"$OUT_FILE"
  fi
else
  echo "==> WARNING: $BG_IMAGE not found; skipping background image embed."
fi

echo -e "\n}" >>"$OUT_FILE"
echo "==> Done. Output written to: $OUT_FILE"
cat "$OUT_FILE" | wl-copy
rm "$OUT_FILE"
