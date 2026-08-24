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
  rm -f /tmp/gpu-screen-recorder-stream.pid
}
trap e SIGABRT SIGINT SIGTERM

gpu-screen-recorder \
  -w HDMI-A-1 \
  -f 60 \
  -k hevc_vulkan \
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

gsrpid=$(pgrep -n -f gpu-screen-recorder)
echo "$gsrpid" >/tmp/gpu-screen-recorder-stream.pid

wait
