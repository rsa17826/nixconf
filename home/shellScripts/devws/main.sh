#!/usr/bin/env bash
port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
xdg-open "http://127.0.0.1:${port}"
python -m http.server "$port" "$@"
