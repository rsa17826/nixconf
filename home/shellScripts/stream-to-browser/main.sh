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
  python -m http.server -d "$SCRIPT_DATA_DIR" 46049
) &
pypid=$!
e() {
  kill "$pypid" "$mtx_pid" "$pid" 2>/dev/null
}
trap e SIGABRT SIGINT SIGTERM

gpu-screen-recorder \
  -w HDMI-A-1 \
  -f 60 \
  -k h264 \
  -c mpegts \
  -o /dev/stdout |
  ffmpeg \
    -f mpegts \
    -i pipe:0 \
    -c:v copy \
    -an \
    -f rtsp \
    -rtsp_transport tcp \
    rtsp://127.0.0.1:8554/stream &
pid=$!
wait
