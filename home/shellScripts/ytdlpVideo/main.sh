#!/usr/bin/env bash

# This function is called by the Quickshell process
#!/usr/bin/env bash
# nyix@nyix:~/nixconf/ > yt-dlp --newline --progress --cookies-from-browser brave \
#     --no-check-certificate --extract-audio "https://www.youtube.com/watch?v=7LkGQTsTXAk" \
#     --output ".\%(title)s.%(ext)s" \
#     --remote-components ejs:github --paths "$HOME/videos/" \
#     --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
#     --write-thumbnail --list-formats                                              
# Extracting cookies from brave
# Extracted 241 cookies from brave
# [youtube] Extracting URL: https://www.youtube.com/watch?v=7LkGQTsTXAk
# [youtube] 7LkGQTsTXAk: Downloading webpage
# [youtube] 7LkGQTsTXAk: Downloading tv downgraded player API JSON
# [youtube] 7LkGQTsTXAk: Downloading web safari player API JSON
# [youtube] 7LkGQTsTXAk: Downloading player 99f55c01-tv
# [youtube] [jsc:deno] Solving JS challenges using deno
# WARNING: [youtube] [jsc] JS Challenge Provider "deno" returned an invalid response:         response = JsChallengeProviderResponse(request=JsChallengeRequest(type=<JsChallengeType.N: 'n'>, input=NChallengeInput(player_url='https://www.youtube.com/s/player/99f55c01/tv-player-ias.vflset/tv-player-ias.js', challenges=['G_59nptcLnS3GULn4FiM', 'QfI9AGvAjS-DLS7l93GG', 'vofFvgY6A_oKmFg7BHoV', '9VIwFjnuOH4ALDOvVkJS', 'xyzFVzD6T7EB3rXtPunE']), video_id='7LkGQTsTXAk'), response=None, error='no solutions')
#          Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
# WARNING: [youtube] 7LkGQTsTXAk: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
# WARNING: Only images are available for download. use --list-formats to see them
# [SponsorBlock] Fetching SponsorBlock segments
# [SponsorBlock] No matching segments were found in the SponsorBlock database
# [info] Available formats for 7LkGQTsTXAk:
# ID  EXT   RESOLUTION FPS │ PROTO │ VCODEC MORE INFO
# ────────────────────────────────────────────────────
# sb3 mhtml 48x27        1 │ mhtml │ images storyboard
# sb2 mhtml 80x45        1 │ mhtml │ images storyboard
# sb1 mhtml 160x90       1 │ mhtml │ images storyboard
# sb0 mhtml 320x180      1 │ mhtml │ images storyboard
# Time: 0h:00m:04s                                                                            
# nyix@nyix:~/nixconf/ > yt-dlp --newline --progress --cookies-from-browser brave \
#     --no-check-certificate --extract-audio "https://www.youtube.com/watch?v=7LkGQTsTXAk" \
#     --output ".\%(title)s.%(ext)s" \
#     --remote-components ejs:github --paths "$HOME/videos/" \
#     --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
#     --write-thumbnail --list-formats -vU
# [debug] Command-line config: ['--newline', '--progress', '--cookies-from-browser', 'brave', '--no-check-certificate', '--extract-audio', 'https://www.youtube.com/watch?v=7LkGQTsTXAk', '--output', '.\\%(title)s.%(ext)s', '--remote-components', 'ejs:github', '--paths', '/home/nyix/videos/', '--audio-format', 'mp3', '--audio-quality', '128k', '--sponsorblock-remove', 'sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic', '--write-thumbnail', '--list-formats', '-vU']
# [debug] Encodings: locale UTF-8, fs utf-8, pref UTF-8, out utf-8, error utf-8, screen utf-8
# [debug] yt-dlp version stable@2026.02.21 from yt-dlp/yt-dlp [646bb31f3]
# [debug] Python 3.13.12 (CPython x86_64 64bit) - Linux-6.18.15-x86_64-with-glibc2.42 (OpenSSL 3.6.1 27 Jan 2026, glibc 2.42)
# [debug] exe versions: ffmpeg 8.0.1 (setts), ffprobe 8.0.1, rtmpdump 2.4
# [debug] Optional libraries: Cryptodome-3.23.0, brotli-1.2.0, certifi-2026.01.04, curl_cffi-0.14.0, mutagen-1.47.0, requests-2.32.5, secretstorage-3.5.0, sqlite3-3.51.2, urllib3-2.6.3, websockets-16.0, yt_dlp_ejs-0.5.0
# [debug] JS runtimes: deno-2.6.10
# [debug] Proxy map: {}
# Extracting cookies from brave
# [debug] Extracting cookies from: "/home/nyix/.config/BraveSoftware/Brave-Browser/Default/Cookies"
# Extracted 241 cookies from brave
# [debug] cookie version breakdown: {'v10': 241, 'v11': 0, 'other': 0, 'unencrypted': 0}
# [debug] Request Handlers: urllib, requests, websockets, curl_cffi
# [debug] Plugin directories: none
# [debug] Loaded 1864 extractors
# [debug] Fetching release info: https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest
# [debug] Downloading _update_spec from https://github.com/yt-dlp/yt-dlp/releases/latest/download/_update_spec
# Current version: stable@2026.02.21 from yt-dlp/yt-dlp
# Latest version: stable@2026.03.03 from yt-dlp/yt-dlp
# ERROR: Nixpkgs/NixOS likely already contain an updated version.
#        To get it run nix-channel --update or nix flake update in your config directory.
# [debug] [youtube] Found YouTube account cookies
# [debug] [youtube] [pot] PO Token Providers: none
# [debug] [youtube] [pot] PO Token Cache Providers: memory
# [debug] [youtube] [pot] PO Token Cache Spec Providers: webpo
# [debug] [youtube] [jsc] JS Challenge Providers: bun (unavailable), deno, node (unavailable), quickjs (unavailable)
# [youtube] Extracting URL: https://www.youtube.com/watch?v=7LkGQTsTXAk
# [youtube] 7LkGQTsTXAk: Downloading webpage
# [debug] [youtube] Forcing "tv" player JS variant for player 99f55c01
#         original url = /s/player/99f55c01/player_es6.vflset/en_US/base.js
# [youtube] 7LkGQTsTXAk: Downloading tv downgraded player API JSON
# [debug] [youtube] 7LkGQTsTXAk: Detected a 15s ad for web
# [youtube] 7LkGQTsTXAk: Downloading web safari player API JSON
# [debug] [youtube] 7LkGQTsTXAk: Detected a 15s ad skippable after 5s for web_safari
# [youtube] 7LkGQTsTXAk: Downloading player 99f55c01-tv
# [youtube] [jsc:deno] Solving JS challenges using deno
# [debug] [youtube] [jsc:deno] Using challenge solver lib script v0.5.0 (source: python package, variant: minified)
# [debug] [youtube] [jsc:deno] Using challenge solver core script v0.5.0 (source: python package, variant: minified)
# [debug] [youtube] [jsc:deno] Running deno: /nix/store/qx6qwzhfxqskg87zl9igij2nbk0kclmk-deno-2.6.10/bin/deno run --ext=js --no-code-cache --no-prompt --no-remote --no-lock --node-modules-dir=none --no-config --no-npm --cached-only --unsafely-ignore-certificate-errors -
# WARNING: [youtube] [jsc] JS Challenge Provider "deno" returned an invalid response:         response = JsChallengeProviderResponse(request=JsChallengeRequest(type=<JsChallengeType.N: 'n'>, input=NChallengeInput(player_url='https://www.youtube.com/s/player/99f55c01/tv-player-ias.vflset/tv-player-ias.js', challenges=['4XFk9bMo5GB0PRc_uO1i', 'rsQABGewK9QaJ8AC_G0I', 'jvRTw_qSdLJDgjGns7Sp', 'MSecZXGd-jMqili34QjY', 'Cj_pHq3F633Xrdfhasye']), video_id='7LkGQTsTXAk'), response=None, error='no solutions')
#          Please report this issue on  https://github.com/yt-dlp/yt-dlp/issues?q= , filling out the appropriate issue template. Confirm you are on the latest version using  yt-dlp -U
# WARNING: [youtube] 7LkGQTsTXAk: n challenge solving failed: Some formats may be missing. Ensure you have a supported JavaScript runtime and challenge solver script distribution installed. Review any warnings presented before this message. For more details, refer to  https://github.com/yt-dlp/yt-dlp/wiki/EJS
# [debug] [youtube] 7LkGQTsTXAk: Detected experiment to bind GVS PO Token to video ID for web client
# [debug] [youtube] 7LkGQTsTXAk: Some web client https formats have been skipped as they are missing a URL. YouTube is forcing SABR streaming for this client. See  https://github.com/yt-dlp/yt-dlp/issues/12482  for more details
# [debug] [youtube] 7LkGQTsTXAk: Some web_safari client https formats have been skipped as they are missing a URL. YouTube is forcing SABR streaming for this client. See  https://github.com/yt-dlp/yt-dlp/issues/12482  for more details
# WARNING: Only images are available for download. use --list-formats to see them
# [debug] Sort order given by extractor: quality, res, fps, hdr:12, source, vcodec, channels, acodec, lang, proto
# [debug] Formats sorted by: hasvid, ie_pref, quality, res, fps, hdr:12(7), source, vcodec, channels, acodec, lang, proto, size, br, asr, vext, aext, hasaud, id
# [SponsorBlock] Fetching SponsorBlock segments
# [debug] SponsorBlock query: https://sponsor.ajay.app/api/skipSegments/6a9e?service=YouTube&categories=%5B%22sponsor%22%2C+%22selfpromo%22%2C+%22filler%22%2C+%22preview%22%2C+%22intro%22%2C+%22interaction%22%2C+%22outro%22%2C+%22music_offtopic%22%5D&actionTypes=%5B%22skip%22%2C+%22poi%22%2C+%22chapter%22%5D
# [SponsorBlock] No matching segments were found in the SponsorBlock database
# [info] Available formats for 7LkGQTsTXAk:
# ID  EXT   RESOLUTION FPS │ PROTO │ VCODEC MORE INFO
# ────────────────────────────────────────────────────
# sb3 mhtml 48x27        1 │ mhtml │ images storyboard
# sb2 mhtml 80x45        1 │ mhtml │ images storyboard
# sb1 mhtml 160x90       1 │ mhtml │ images storyboard
# sb0 mhtml 320x180      1 │ mhtml │ images storyboard
# Time: 0h:00m:05s                                                                            
# nyix@nyix:~/nixconf/ > yt-dlp --update-to nightly

# Current version: stable@2026.02.21 from yt-dlp/yt-dlp
# Latest version: nightly@2026.03.03.162408 from yt-dlp/yt-dlp-nightly-builds
# ERROR: Nixpkgs/NixOS likely already contain an updated version.
#        To get it run nix-channel --update or nix flake update in your config directory.
# nyix@nyix:~/nixconf/ > yt-dlp --newline --progress --cookies-from-browser brave \
#     --no-check-certificate --extract-audio "https://www.youtube.com/watch?v=7LkGQTsTXAk" \
#     --output ".\%(title)s.%(ext)s" \
#     --remote-components ejs:github --paths "$HOME/videos/" \
#     --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
#     --write-thumbnail --list-formats -vU --extractor-args "youtube:player_js_variant=tv;player_js_version=20514@9f4cc5e4"

# [debug] Command-line config: ['--newline', '--progress', '--cookies-from-browser', 'brave', '--no-check-certificate', '--extract-audio', 'https://www.youtube.com/watch?v=7LkGQTsTXAk', '--output', '.\\%(title)s.%(ext)s', '--remote-components', 'ejs:github', '--paths', '/home/nyix/videos/', '--audio-format', 'mp3', '--audio-quality', '128k', '--sponsorblock-remove', 'sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic', '--write-thumbnail', '--list-formats', '-vU', '--extractor-args', 'youtube:player_js_variant=tv;player_js_version=20514@9f4cc5e4']
# [debug] Encodings: locale UTF-8, fs utf-8, pref UTF-8, out utf-8, error utf-8, screen utf-8
# [debug] yt-dlp version stable@2026.02.21 from yt-dlp/yt-dlp [646bb31f3]
# [debug] Python 3.13.12 (CPython x86_64 64bit) - Linux-6.18.15-x86_64-with-glibc2.42 (OpenSSL 3.6.1 27 Jan 2026, glibc 2.42)
# [debug] exe versions: ffmpeg 8.0.1 (setts), ffprobe 8.0.1, rtmpdump 2.4
# [debug] Optional libraries: Cryptodome-3.23.0, brotli-1.2.0, certifi-2026.01.04, curl_cffi-0.14.0, mutagen-1.47.0, requests-2.32.5, secretstorage-3.5.0, sqlite3-3.51.2, urllib3-2.6.3, websockets-16.0, yt_dlp_ejs-0.5.0
# [debug] JS runtimes: deno-2.6.10
# [debug] Proxy map: {}
# Extracting cookies from brave
# [debug] Extracting cookies from: "/home/nyix/.config/BraveSoftware/Brave-Browser/Default/Cookies"
# Extracted 241 cookies from brave
# [debug] cookie version breakdown: {'v10': 241, 'v11': 0, 'other': 0, 'unencrypted': 0}
# [debug] Request Handlers: urllib, requests, websockets, curl_cffi
# [debug] Plugin directories: none
# [debug] Loaded 1864 extractors
# [debug] Fetching release info: https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest
# [debug] Downloading _update_spec from https://github.com/yt-dlp/yt-dlp/releases/latest/download/_update_spec
# Current version: stable@2026.02.21 from yt-dlp/yt-dlp
# Latest version: stable@2026.03.03 from yt-dlp/yt-dlp
# ERROR: Nixpkgs/NixOS likely already contain an updated version.
#        To get it run nix-channel --update or nix flake update in your config directory.
# [debug] [youtube] Found YouTube account cookies
# [debug] [youtube] [pot] PO Token Providers: none
# [debug] [youtube] [pot] PO Token Cache Providers: memory
# [debug] [youtube] [pot] PO Token Cache Spec Providers: webpo
# [debug] [youtube] [jsc] JS Challenge Providers: bun (unavailable), deno, node (unavailable), quickjs (unavailable)
# [youtube] Extracting URL: https://www.youtube.com/watch?v=7LkGQTsTXAk
# [youtube] 7LkGQTsTXAk: Downloading webpage
# [debug] [youtube] Forcing player 9f4cc5e4 in place of player 99f55c01
#         Forcing "tv" player JS variant for player 9f4cc5e4
#         original url = /s/player/99f55c01/player_es6.vflset/en_US/base.js
# [youtube] 7LkGQTsTXAk: Downloading tv downgraded player API JSON
# [debug] [youtube] 7LkGQTsTXAk: Detected a 32s ad skippable after 5s for web
# [youtube] 7LkGQTsTXAk: Downloading web safari player API JSON
# [debug] [youtube] 7LkGQTsTXAk: Detected a 6s ad skippable after 5s for web_safari
# [youtube] 7LkGQTsTXAk: Downloading player 9f4cc5e4-tv
# [youtube] [jsc:deno] Solving JS challenges using deno
# [debug] [youtube] [jsc:deno] Using challenge solver lib script v0.5.0 (source: python package, variant: minified)
# [debug] [youtube] [jsc:deno] Using challenge solver core script v0.5.0 (source: python package, variant: minified)
# [debug] [youtube] [jsc:deno] Running deno: /nix/store/qx6qwzhfxqskg87zl9igij2nbk0kclmk-deno-2.6.10/bin/deno run --ext=js --no-code-cache --no-prompt --no-remote --no-lock --node-modules-dir=none --no-config --no-npm --cached-only --unsafely-ignore-certificate-errors -
# [youtube] 7LkGQTsTXAk: Downloading m3u8 information
# [debug] Sort order given by extractor: quality, res, fps, hdr:12, source, vcodec, channels, acodec, lang, proto
# [debug] Formats sorted by: hasvid, ie_pref, quality, res, fps, hdr:12(7), source, vcodec, channels, acodec, lang, proto, size, br, asr, vext, aext, hasaud, id
# [SponsorBlock] Fetching SponsorBlock segments
# [debug] SponsorBlock query: https://sponsor.ajay.app/api/skipSegments/6a9e?service=YouTube&categories=%5B%22music_offtopic%22%2C+%22sponsor%22%2C+%22intro%22%2C+%22interaction%22%2C+%22selfpromo%22%2C+%22preview%22%2C+%22filler%22%2C+%22outro%22%5D&actionTypes=%5B%22skip%22%2C+%22poi%22%2C+%22chapter%22%5D
# [SponsorBlock] No matching segments were found in the SponsorBlock database
# [info] Available formats for 7LkGQTsTXAk:
# ID      EXT   RESOLUTION FPS CH │   FILESIZE   TBR PROTO │ VCODEC        VBR ACODEC      ABR ASR MORE INFO
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# sb3     mhtml 48x27        1    │                  mhtml │ images                                storyboard
# sb2     mhtml 80x45        1    │                  mhtml │ images                                storyboard
# sb1     mhtml 160x90       1    │                  mhtml │ images                                storyboard
# sb0     mhtml 320x180      1    │                  mhtml │ images                                storyboard
# 249-drc webm  audio only      2 │  740.75KiB   53k https │ audio only        opus        53k 48k [en] low, DRC, TV-D, webm_dash
# 250-drc webm  audio only      2 │  962.74KiB   69k https │ audio only        opus        69k 48k [en] low, DRC, TV-D, webm_dash
# 249     webm  audio only      2 │  737.39KiB   53k https │ audio only        opus        53k 48k [en] low, TV-D, webm_dash
# 250     webm  audio only      2 │  956.63KiB   68k https │ audio only        opus        68k 48k [en] low, TV-D, webm_dash
# 140-drc m4a   audio only      2 │    1.78MiB  130k https │ audio only        mp4a.40.2  130k 44k [en] medium, DRC, TV-D, m4a_dash
# 251-drc webm  audio only      2 │    1.80MiB  131k https │ audio only        opus       131k 48k [en] medium, DRC, TV-D, webm_dash
# 140     m4a   audio only      2 │    1.78MiB  130k https │ audio only        mp4a.40.2  130k 44k [en] medium, TV-D, m4a_dash
# 251     webm  audio only      2 │    1.79MiB  131k https │ audio only        opus       131k 48k [en] medium, TV-D, webm_dash
# 91      mp4   256x144     30    │ ~  2.75MiB  201k m3u8  │ avc1.4D400C       mp4a.40.5           [en] WEB-S
# 160     mp4   256x144     30    │    1.31MiB   96k https │ avc1.4d400c   96k video only          144p, TV-D, mp4_dash
# 278     webm  256x144     30    │    1.18MiB   86k https │ vp9           86k video only          144p, TV-D, webm_dash
# 92      mp4   426x240     30    │ ~  4.85MiB  354k m3u8  │ avc1.4D4015       mp4a.40.5           [en] WEB-S
# 133     mp4   426x240     30    │    2.75MiB  201k https │ avc1.4d4015  201k video only          240p, TV-D, mp4_dash
# 242     webm  426x240     30    │    2.16MiB  158k https │ vp9          158k video only          240p, TV-D, webm_dash
# 93      mp4   640x360     30    │ ~ 10.82MiB  789k m3u8  │ avc1.4D401E       mp4a.40.2           [en] WEB-S
# 134     mp4   640x360     30    │    4.81MiB  351k https │ avc1.4d401e  351k video only          360p, TV-D, mp4_dash
# 18      mp4   640x360     30  2 │ ≈  6.57MiB  479k https │ avc1.42001E       mp4a.40.2       44k [en] 360p, TV-D
# 243     webm  640x360     30    │    3.28MiB  239k https │ vp9          239k video only          360p, TV-D, webm_dash
# 94      mp4   854x480     30    │ ~ 18.59MiB 1356k m3u8  │ avc1.4D401F       mp4a.40.2           [en] WEB-S
# 135     mp4   854x480     30    │    7.52MiB  549k https │ avc1.4d401f  549k video only          480p, TV-D, mp4_dash
# 244     webm  854x480     30    │    4.96MiB  362k https │ vp9          362k video only          480p, TV-D, webm_dash
# 95      mp4   1280x720    30    │ ~ 30.75MiB 2243k m3u8  │ avc1.64001F       mp4a.40.2           [en] WEB-S
# 136     mp4   1280x720    30    │   11.03MiB  805k https │ avc1.64001f  805k video only          720p, TV-D, mp4_dash
# 247     webm  1280x720    30    │    8.27MiB  603k https │ vp9          603k video only          720p, TV-D, webm_dash
# 96      mp4   1920x1080   30    │ ~ 57.54MiB 4197k m3u8  │ avc1.640028       mp4a.40.2           [en] WEB-S
# 137     mp4   1920x1080   30    │   18.16MiB 1325k https │ avc1.640028 1325k video only          1080p, TV-D, mp4_dash
# 248     webm  1920x1080   30    │   11.22MiB  819k https │ vp9          819k video only          1080p, TV-D, webm_dash
# Time: 0h:00m:14s                                                                            
# nyix@nyix:~/nixconf/ > 
download_logic() {
  local mode=$1
  local url=$2
  local pid=$$ # Use the current subshell PID for the bar ID
  # local output_tmpl="%(fulltitle)s - %(uploader)s.%(ext)s"

  # Initial message to create the bar
  echo "{\"progress\": 0, \"name\": \"$mode: $url\", \"color\": \"#3498db\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock
  # --extractor-args "youtube:player_js_variant=tv;player_js_version=20514@9f4cc5e4"

  # Run yt-dlp and pipe progress to a loop that sends updates to the socket
  # https://www.youtube.com/watch?v=7LkGQTsTXAk&t=115&startTime=0
  yt-dlp --newline --progress --cookies-from-browser brave \
    --no-check-certificate --extract-audio "$url" \
    --output ".\%(title)s.%(ext)s" \
    --remote-components ejs:github --paths "$HOME/videos/" \
    --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
    --write-thumbnail --list-formats 2>~/ass
  # yt-dlp --newline --progress --cookies-from-browser brave \
  #   --no-check-certificate --extract-audio "$url" \
  #   --output ".\%(title)s.%(ext)s" \
  #   --remote-components ejs:github --paths "$HOME/videos/" \
  #   --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
  #   --write-thumbnail 2>~/ass
  #    while read -r line; do
  #   if [[ $line =~ \[download\]\ +([0-9.]+)% ]]; then
  #     local percent="${BASH_REMATCH[1]}"
  #     # Send update to socket
  #     echo "{\"progress\": $percent, \"name\": \"$HOME/videos/$output_tmpl\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock
  #   fi
  # done

  # Close the bar after 5 seconds (using the max_idle logic we built)
  echo "{\"action\": \"close\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock
}
export -f download_logic

# Get the absolute path of the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

echo "Clipboard Monitor Active..."

LAST_CLIP=""

#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_CLIP=""

while true; do
  # 1. Grab clipboard content, strip newlines and surrounding whitespace
  RAW_CLIP=$(wl-paste --type text --no-newline 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # 2. Check if clipboard changed and isn't empty
  if [[ "$RAW_CLIP" != "$LAST_CLIP" && -n "$RAW_CLIP" ]]; then

    # 3. Extract URLs and clean them using sed (removing time stamps and quotes)
    # We use a process substitution to loop through each found URL
    while read -r URL; do
      if [[ -n "$URL" ]]; then
        # 4. Launch Quickshell with the environment variable
        # Standard Quickshell usually takes the path to the main.qml or the directory
        TARGET_URL="$URL" qs -p "$SCRIPT_DIR/MediaPopup.qml" &
      fi
    done < <(echo "$RAW_CLIP" | grep -Eo 'https?://[^[:space:]"]+' |
      sed -E "s/(&t|&startTime)=[0-9]+//g" |
      tr -d "'\"" | sort -u)

    LAST_CLIP="$RAW_CLIP"
  fi

  sleep 1
done
