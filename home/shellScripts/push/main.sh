#!/usr/bin/env sh
set -e

# Get current branch
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)

# Join all arguments into a single string as the commit message
MESSAGE="$*"
MESSAGE="${MESSAGE:-NO MESSAGE SET}"

# Stage all changes
git add -A

# Only commit if there are changes
if ! git diff --cached --quiet; then
  git commit -m "$MESSAGE"
else
  echo "No changes to commit."
fi

# Get all remotes
REMOTES=$(git remote)

if [ -z "$REMOTES" ]; then
  echo "No remotes configured."
  exit 0
fi

# Loop through each remote
for remote in $REMOTES; do
  # Get all push URLs for this remote
  PUSH_URLS=$(git remote get-url --push "$remote" 2>/dev/null || echo "")

  if [ -z "$PUSH_URLS" ]; then
    echo "No push URL for remote $remote, skipping."
    continue
  fi

  # Push to each URL for this remote
  echo "$PUSH_URLS" | while read -r url; do
    echo "Pushing to $remote ($url) on branch $BRANCH..."
    git push "$url" "$BRANCH" || echo "Failed to push to $url, continuing..."
  done
done
