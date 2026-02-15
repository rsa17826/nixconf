#!/usr/bin/env bash
# source admin && admin "$@"

# The standard sops-nix path for Home Manager secrets
TOKEN_PATH="$SECRETS/GITHUB_TOKEN"

# 1. Check if the decrypted secret exists
if [ -f "$TOKEN_PATH" ]; then
  # 2. Use $() to capture the output of cat into the variable
  GITHUB_TOKEN=$(cat "$TOKEN_PATH")
else
  echo "Token missing at $TOKEN_PATH" >&2
  exit 1
fi

# 3. Fetch notifications
# Note: GitHub recommends the 'Bearer' prefix for modern tokens
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/notifications?all=false" | \
  jq 'map({ updated_at: .updated_at, title: .subject.title, url: .subject.url })'