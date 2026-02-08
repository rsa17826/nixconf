#!/usr/bin/env sh
set -e

MESSAGE="${1:-NO MESSAGE SET}"

git add -A
git commit -m "$MESSAGE"
git push