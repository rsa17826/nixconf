if [ -z "$1" ]; then
  sudo /run/current-system/sw/bin/shutdown 0
else
  # shellcheck disable=SC2048,SC2086
  sudo /run/current-system/sw/bin/shutdown $@
fi
