#!/nix/store/zh1ijdhb6gng1509b1zrilb6xlzx60j6-bash-5.3p9/bin/bash

export PATH="$PATH"

#!/usr/bin/env bash

# Accept URLs as arguments, or fall back to clipboard
if [[ $# -gt 0 ]]; then
  readarray -t url_list < <(printf '%s\n' "$@")
else
  # Get clipboard content using wl-paste
  # -n avoids appending a trailing newline if one is already present
  raw_clipboard=$(wl-paste -n)

  # Extract and clean URLs
  # - grep: extracts anything starting with http(s)
  # - sed: removes time parameters (&t or &startTime)
  # - tr: removes single and double quotes
  readarray -t url_list < <(echo "$raw_clipboard" | grep -oE "https?://[^[:space:]\"]+" |
    sed -E 's/(&t=|&startTime=)[0-9]+//g' |
    tr -d "'\"")
fi

if [[ ${#url_list[@]} -eq 0 ]]; then
  echo "Error: No valid URLs found."
  exit 1
fi

SELF="$(realpath "$0")"

# Build a resume command string from an array of URLs
build_resume_cmd() {
  local quoted=()
  for u in "$@"; do
    quoted+=("$(printf '%q' "$u")")
  done
  printf '"%s" %s' "$SELF" "${quoted[*]}"
}

# Register one job covering all URLs upfront
remaining=("${url_list[@]}")
job_id=$(job-save \
  --name "yt-dlp: ${#remaining[@]} URL(s)" \
  --cmd "$(build_resume_cmd "${remaining[@]}")")

er=0

for url in "${url_list[@]}"; do
  echo "--- Downloading: $url ---"

  if yt-dlp --progress -vU \
    --no-check-certificate \
    -f "bestvideo[height=720]+bestaudio/bestvideo[height>720]+bestaudio/bestvideo+bestaudio/best" \
    --merge-output-format mp4 \
    --no-mtime --add-metadata \
    --remote-components ejs:github --paths "$HOME/videos/" \
    --audio-format wav --audio-quality 128k \
    --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
    -o "%(fulltitle)s - by %(channel)s.%(ext)s" \
    "$url" || yt-dlp --progress \
    --cookies-from-browser chromium:"$HOME/.config/net.imput.helium" \
    --no-check-certificate \
    -f "bestvideo[height=720]+bestaudio/bestvideo[height>720]+bestaudio/bestvideo+bestaudio/best" \
    --merge-output-format mp4 \
    --no-mtime --add-metadata \
    --remote-components ejs:github --paths "$HOME/videos/" \
    --audio-format wav --audio-quality 128k \
    --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
    -o "%(fulltitle)s - by %(channel)s.%(ext)s" \
    "$url"; then

    # Drop the successful URL from the remaining list
    new_remaining=()
    for u in "${remaining[@]}"; do
      [[ "$u" != "$url" ]] && new_remaining+=("$u")
    done
    remaining=("${new_remaining[@]}")

    if [[ ${#remaining[@]} -eq 0 ]]; then
      job-done "$job_id"
      echo "--- All downloads complete, job cleared ---"
    else
      # Overwrite the job in place with the updated URL list
      job-save \
        --id "$job_id" \
        --name "yt-dlp: ${#remaining[@]} URL(s) remaining" \
        --cmd "$(build_resume_cmd "${remaining[@]}")" >/dev/null
      echo "--- Done; ${#remaining[@]} URL(s) still pending ---"
    fi

  else
    echo "--- Download failed; $url kept in job ---"
    er=1
  fi

done

echo "Finished processing all links."

exit "$er"
