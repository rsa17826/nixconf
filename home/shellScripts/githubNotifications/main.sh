#!/usr/bin/env bash

TOKEN_PATH="/run/secrets/GITHUB_TOKEN"

if [ -f "$TOKEN_PATH" ]; then
  GITHUB_TOKEN=$(cat "$TOKEN_PATH")
else
  echo "Token missing at $TOKEN_PATH" >&2
  exit 1
fi

# Use a case statement to handle arguments
case "$1" in
"read")
  # $2 will be the URL passed from QML
  THREAD_URL="$2"
  if [ -z "$THREAD_URL" ]; then
    echo "No URL provided to mark as read" >&2
    exit 1
  fi
  # Perform the PUT request
  curl -s -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" "$THREAD_URL"
  ;;

*)
  # Default behavior: Fetch notifications
  # Fetch: We now also grab the repository HTML URL
  curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/notifications?all=false" |
    jq 'map({
        updated_at: .updated_at,
        title: .subject.title,
        url: .subject.latest_comment_url // .subject.url
      })'
  ;;
esac
