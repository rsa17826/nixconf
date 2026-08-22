#!/usr/bin/env bash
port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
xdg-open "http://127.0.0.1:${port}"
python -m http.server "$port" "$@"

if [[ ! -f start ]]; then
  # Use printf %q to safely shell-escape every argument, including spaces
  printf '#!/usr/bin/env sh\npython -m http.server %q' "$port" >./start
  if [ "$#" -gt 0 ]; then
    printf ' %q' "$@" >>./start
  fi
  printf '\n' >>./start
  chmod +x ./start
fi
