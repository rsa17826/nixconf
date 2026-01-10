#!/usr/bin/env bash

# Load token
if [ -f /etc/mysecrets/github_token.env ]; then
  source /etc/mysecrets/github_token.env
else
  echo "Token missing"
  exit 1
fi

# Fetch unread notifications
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/notifications?all=false|jq '.[0] | {
        updated_at: .updated_at,
        title: .subject.title,
        url: .subject.url
    }'
