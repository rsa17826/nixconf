#!/usr/bin/env bash
(
  mediamtx <(
    cat <<'E'
paths:
  stream:
    source: publisher
E
  )
) &
mtx_pid=$!
(
  python -m http.server -d "${SCRIPT_DATA_DIR:-.}" 46049
) &
pypid=$!
e() {
  kill "$gsrpid" "$pypid" "$mtx_pid" "$pid" 2>/dev/null
  rm -f /tmp/gpu-screen-recorder-stream.pid /tmp/gpu-screen-recorder-stream.state
}
trap e SIGABRT SIGINT SIGTERM

state_file=/tmp/gpu-screen-recorder-stream.state
echo Unpaused >"$state_file"

gpu-screen-recorder \
  -w HDMI-A-1 \
  -f 60 \
  -k h264_vulkan \
  -c mpegts \
  -o /dev/stdout \
  2> >(
    stdbuf -oL grep --line-buffered -oE '(Un)?Paused' | while IFS= read -r state; do
      tmp="${state_file}.tmp"
      printf '%s\n' "$state" >"$tmp" && mv "$tmp" "$state_file"
    done
  ) |
  ffmpeg \
    -f mpegts \
    -i pipe:0 \
    -c:v copy \
    -an \
    -f rtsp \
    -rtsp_transport tcp \
    rtsp://127.0.0.1:8554/stream &
pid=$!

gsrpid=$(pgrep -n -f gpu-screen-recorder)
echo "$gsrpid" >/tmp/gpu-screen-recorder-stream.pid

wait
