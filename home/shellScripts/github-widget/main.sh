#!/usr/bin/env bash

# Load token safely via root helper
if ! source <(sudo /usr/local/bin/github-token-helper); then
    echo "Token missing"
    exit 1
fi

# Fetch unread notifications
UNREAD=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/notifications?all=false | jq '. | length')

MAX=20
DISPLAY_COUNT=$((UNREAD>MAX ? MAX : UNREAD))

DOT=$([ "$UNREAD" -gt 0 ] && echo "●" || echo "")

# Output for Waybar
echo "$DOT $DISPLAY_COUNT"
