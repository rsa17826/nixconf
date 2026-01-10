#!/usr/bin/env bash

# Fetch notifications JSON
NOTIFS_JSON=$(sudo -n githubNotifications 2>/dev/null) || NOTIFS_JSON="[]"

# Count unread notifications
UNREAD=$(echo "$NOTIFS_JSON" | jq 'length')

# Prepare red dot if any unread
DOT=""
if [ "$UNREAD" -gt 0 ]; then
    DOT="●"
fi

# Prepare tooltip with latest 5 notification titles
TOOLTIP=$(echo "$NOTIFS_JSON" | jq -r '.[0:5] | map(.title) | join("\n")')

# Output for Waybar
echo "<span letter_spacing='-13000' color='red' rise='-9000' font_size='small'>$DOT  </span>   <span rise='-3000' margin-right='-20px'>$UNREAD</span>"
