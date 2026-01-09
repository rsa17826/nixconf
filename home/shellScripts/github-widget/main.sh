#!/usr/bin/env bash

# Load token
if [ -f /etc/mysecrets/github_token.env ]; then
    source /etc/mysecrets/github_token.env
else
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
