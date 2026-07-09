#!/usr/bin/env sh
exec unshare --user --map-current-user --net --fork "$@"
