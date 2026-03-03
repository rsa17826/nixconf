if [ -z "$1" ]; then
  sudo /run/current-system/sw/bin/shutdown 0
else
  sudo /run/current-system/sw/bin/shutdown $*
fi
