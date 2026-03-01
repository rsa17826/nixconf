#!/usr/bin/env sh
set -e

# Join all the arguments into a single string, separated by spaces
MESSAGE="$*"

git add -A
git commit -m "$MESSAGE"
git push
