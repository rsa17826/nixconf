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

# Limit display
MAX=20
DISPLAY_COUNT=$((UNREAD>MAX ? MAX : UNREAD))

# Red dot if unread > 0
if [ "$UNREAD" -gt 0 ]; then
  DOT="●"
else
  DOT=""
fi

# Output for Waybar
echo "$DOT $DISPLAY_COUNT"
