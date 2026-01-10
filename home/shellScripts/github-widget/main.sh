#!/usr/bin/env bash

# Fetch unread notifications
NOTIFICATIONS = sudo -n githubNotifications
echo $NOTIFICATIONS
UNREAD=$($NOTIFICATIONS | jq '. | length')

DOT=$([ "$UNREAD" -gt 0 ] && echo "●" || echo "")

# Output for Waybar
echo "<span letter_spacing='-13000' color='red' rise='-6000' font_size='small'>$DOT  </span>   $UNREAD"
