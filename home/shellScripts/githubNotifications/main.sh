#!/usr/bin/env bash

# Load token
if [ -f /etc/mysecrets/github_token.env ]; then
  source /etc/mysecrets/github_token.env
else
  echo "Token missing"
  exit 1
fi

# Fetch unread notifications
NOTIFICATIONS = curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/notifications?all=false
echo $NOTIFICATIONS
