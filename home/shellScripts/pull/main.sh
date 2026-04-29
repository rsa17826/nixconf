#!/usr/bin/env bash
# git-preview-pull: Show incoming diff before pulling

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Make sure we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}Error: Not inside a git repository.${RESET}"
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE=$(git config "branch.${BRANCH}.remote" 2>/dev/null || echo "origin")
REMOTE_BRANCH=$(git config "branch.${BRANCH}.merge" 2>/dev/null | sed 's|refs/heads/||' || echo "$BRANCH")
REMOTE_REF="${REMOTE}/${REMOTE_BRANCH}"

echo -e "${CYAN}${BOLD}Fetching from ${REMOTE}...${RESET}"
git fetch "$REMOTE"

LOCAL=$(git rev-parse HEAD)
REMOTE_SHA=$(git rev-parse "$REMOTE_REF" 2>/dev/null || true)

if [[ -z "$REMOTE_SHA" ]]; then
  echo -e "${RED}Could not find remote ref: ${REMOTE_REF}${RESET}"
  exit 1
fi

if [[ "$LOCAL" == "$REMOTE_SHA" ]]; then
  echo -e "${GREEN}Already up to date. Nothing to pull.${RESET}"
  exit 0
fi

# Stats summary
AHEAD=$(git rev-list --count "$REMOTE_REF".."$LOCAL")
BEHIND=$(git rev-list --count "$LOCAL".."$REMOTE_REF")

echo ""
echo -e "${BOLD}Branch:${RESET}  ${BRANCH}"
echo -e "${BOLD}Remote:${RESET}  ${REMOTE_REF}"
echo -e "${GREEN}${BOLD}▲ Ahead:${RESET}  ${AHEAD} commit(s)"
echo -e "${YELLOW}${BOLD}▼ Behind:${RESET} ${BEHIND} commit(s) (incoming)"
echo ""

# Incoming commits
echo -e "${BOLD}─── Incoming Commits ───────────────────────────────${RESET}"
git log --oneline --graph --decorate "$LOCAL".."$REMOTE_REF"
echo ""

# Diff stat
echo -e "${BOLD}─── Changed Files ──────────────────────────────────${RESET}"
git diff --stat "$LOCAL".."$REMOTE_REF"
echo ""

# Optional: full diff (paginated)
read -rp "$(echo -e "${CYAN}Show full diff? [y/N]:${RESET} ")" SHOW_DIFF
if [[ "${SHOW_DIFF,,}" == "y" ]]; then
  git diff "$LOCAL".."$REMOTE_REF" | ${PAGER:-less -R}
  echo ""
fi

# Decision
read -rp "$(echo -e "${BOLD}Continue with git pull? [y/N]:${RESET} ")" CONFIRM

if [[ "${CONFIRM,,}" == "y" ]]; then
  echo ""
  echo -e "${GREEN}Pulling...${RESET}"
  git pull "$REMOTE" "$REMOTE_BRANCH" --rebase
  echo -e "${GREEN}${BOLD}Done.${RESET}"
else
  echo -e "${YELLOW}Aborted. No changes made.${RESET}"
  exit 0
fi
