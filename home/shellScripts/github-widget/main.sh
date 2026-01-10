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
# Waybar uses the 'tooltip' property if we include it as JSON
jq -n --arg dot "$DOT" \
      --arg unread "$UNREAD" \
      --arg tooltip "$TOOLTIP" \
      '{text: "<span letter_spacing=\"-13000\" color=\"red\" rise=\"-6000\" font_size=\"small\">\($dot)  </span>   \($unread)", tooltip: $tooltip}'
