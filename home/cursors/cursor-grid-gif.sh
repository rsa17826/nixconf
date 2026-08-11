#!/usr/bin/env bash
# Build a single GIF showing every cursor in a folder of hyprcursor themes,
# arranged in a grid, each cell playing its own animation loop, with an
# optional yellow dot marking the cursor's hotspot.
#
# Requires: ImageMagick (magick, montage), awk, mktemp, nproc
#
# Usage:
#   ./cursor-grid-gif.sh [cursor_dir] [output.gif] [size] [cell_px] [cols]

set -euo pipefail

CURSOR_DIR="${1:-cursorImages/hyprcursors}"
SIZE="${2:--1}"
CELL="${3:-128}"
COLS="${4:-6}"
OUT="${5:-cursors_grid.gif}"
TICK_MS="${TICK_MS:-20}"
SHOW_HOTSPOT="${SHOW_HOTSPOT:-1}"
bg="#444"
textColor="#000"
# Detect available CPU threads for parallel processing
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cursors=()
for d in "$CURSOR_DIR"/*/; do
  name=$(basename "$d")
  [[ -f "$d/meta.hl" ]] && cursors+=("$name")
done

if [[ ${#cursors[@]} -eq 0 ]]; then
  echo "No cursors with meta.hl found under $CURSOR_DIR" >&2
  exit 1
fi

declare -A TOTAL_MS

# Helper function to limit active parallel jobs to NPROC
run_job() {
  "$@" &
  if [[ $(jobs -r -p | wc -l) -ge $NPROC ]]; then
    wait -n
  fi
}

echo "=== Pre-rendering unique frame tiles in parallel ($NPROC workers) ==="

for name in "${cursors[@]}"; do
  meta="$CURSOR_DIR/$name/meta.hl"

  # Strip CRLF carriage returns (\r) to handle files formatted on Windows
  meta=$(tr -d '\r' <"$meta")

  hx=$(awk -F'=' '/^hotspot_x/{gsub(/ /,"",$2); print $2}' <<<"$meta")
  hy=$(awk -F'=' '/^hotspot_y/{gsub(/ /,"",$2); print $2}' <<<"$meta")
  hx="${hx:-0.5}"
  hy="${hy:-0.5}"

  # Calculate pixel offset once per cursor
  px=$(awk "BEGIN{printf \"%d\", $hx*$CELL}")
  py=$(awk "BEGIN{printf \"%d\", $hy*$CELL}")

  # Sanitize name for bash variables (replaces non-alphanumeric chars with underscores)
  var_name="${name//[^a-zA-Z0-9]/_}"

  # Dynamic array references for frame mapping using the sanitized name
  declare -a "CUM_${var_name}=()"
  declare -a "TILES_${var_name}=()"
  declare -n cum_ref="CUM_${var_name}"
  declare -n tiles_ref="TILES_${var_name}"

  files=() delays=()
  files=() delays=()
  while IFS= read -r line; do
    fn=$(echo "$line" | awk -F'[ ,]+' '{print $4}')
    dl=$(echo "$line" | awk -F'[ ,]+' '{print $5}')

    # 1. Strip non-numeric characters just to be safe
    dl="${dl//[^0-9]/}"
    sz="$(echo "$line" | awk -F'[ ,]+' '{print $3}')"
    if [[ "$SIZE" == -1 ]]; then
      SIZE="$sz"
    else
      if [[ "$sz" != "$SIZE" ]]; then
        continue
      fi
    fi

    # 2. Fallback to TICK_MS if the delay is missing/empty
    dl="${dl:-$TICK_MS}"

    # 3. FIX: Clamp absurdly large delays to a max of 2 seconds (2000ms)
    # This keeps "infinite" static frames from ruining the grid loop.
    if ((dl > 2000)); then
      dl=2000
    fi

    files+=("$CURSOR_DIR/$name/$fn")
    delays+=("$dl")
  done < <(grep '^define_size' <<<"$meta")

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "warning: no frames at size $SIZE for '$name', skipping" >&2
    continue
  fi

  cum=0
  for i in "${!files[@]}"; do
    src="${files[i]}"
    cum=$((cum + delays[i]))

    tile_out="$WORKDIR/tile_${name}_${i}.png"
    cum_ref+=("$cum")
    tiles_ref+=("$tile_out")

    # Combine resize, hotspot circle, and label annotation into 1 magick call
    cmd=(magick -background none "$src" -resize "${CELL}x${CELL}")
    if [[ "$SHOW_HOTSPOT" == "1" ]]; then
      cmd+=(-fill yellow -stroke black -strokewidth 1 -draw "circle $px,$py $((px + 3)),$py")
    fi
    cmd+=(-background "$bg" -gravity south -splice 0x14 -font DejaVu-Sans -pointsize 12 -fill "$textColor" -annotate +0+2 "$name" "$tile_out")

    run_job "${cmd[@]}"
  done

  # Associative arrays CAN handle hyphens, so using the original $name here is fine
  TOTAL_MS[$name]=$cum
done

# Wait for pre-rendering tasks to complete
wait

max_total=0
for name in "${cursors[@]}"; do
  t=${TOTAL_MS[$name]:-0}
  ((t > max_total)) && max_total=$t
done

frame_count=$(((max_total + TICK_MS - 1) / TICK_MS))
echo "Cursors: ${#cursors[@]}  |  Grid frames to render: $frame_count"
echo "=== Assembling grid frames in parallel ==="

render_grid_frame() {
  local f=$1
  local t=$((f * TICK_MS))
  local tiles=()

  for name in "${cursors[@]}"; do
    [[ -n "${TOTAL_MS[$name]:-}" ]] || continue
    local total=${TOTAL_MS[$name]}
    local tm=$((t % total))

    # Retrieve arrays using the sanitized name
    local var_name="${name//[^a-zA-Z0-9]/_}"
    declare -n cum="CUM_${var_name}"
    declare -n tile_list="TILES_${var_name}"

    local selected_tile="${tile_list[-1]}"
    for i in "${!cum[@]}"; do
      if ((tm < cum[i])); then
        selected_tile="${tile_list[i]}"
        break
      fi
    done
    tiles+=("$selected_tile")
  done

  magick montage "${tiles[@]}" \
    -tile "${COLS}x" \
    -geometry +2+2 \
    -background "$bg" \
    -font DejaVu-Sans \
    "$WORKDIR/grid_$(printf '%05d' "$f").png"
}

for ((f = 0; f < frame_count; f++)); do
  run_job render_grid_frame "$f"
done

wait

echo "=== Compiling final GIF ==="
magick -delay $((TICK_MS / 10)) -loop 0 "$WORKDIR"/grid_*.png "$OUT"
echo "Wrote $OUT"
