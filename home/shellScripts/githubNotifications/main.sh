#!/usr/bin/env bash

# Load token
if [ -f /etc/mysecrets/github_token.env ]; then
  source /etc/mysecrets/github_token.env
else
  echo "Token missing" >&2
  exit 1
fi

# Fetch unread notifications from GitHub
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/notifications?all=false" | \
  jq 'map({ updated_at: .updated_at, title: .subject.title, url: .subject.url })'
