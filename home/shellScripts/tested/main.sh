#!/usr/bin/env bash
set -e

# Define your environments
REMOTE="origin"
TARGET_BRANCH="stable" # You can name this 'tested' or 'prod' if you prefer

# Get the current branch or commit hash
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)

echo "🚀 Marking current state as tested..."
echo "Pushing $CURRENT_BRANCH to $REMOTE/$TARGET_BRANCH..."

# Push the local branch state directly to the remote target branch
if git push "$REMOTE" "$CURRENT_BRANCH:$TARGET_BRANCH"; then
  echo "✅ Success! Code has been promoted to the '$TARGET_BRANCH' branch."
else
  echo "❌ Failed to promote to $TARGET_BRANCH."
  exit 1
fi
