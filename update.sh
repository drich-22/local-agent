#!/usr/bin/env bash
# Pull latest from origin (this repo). Safe to run from cron.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

BRANCH="${UPDATE_BRANCH:-main}"
REMOTE="${UPDATE_REMOTE:-origin}"

if [[ ! -d .git ]]; then
  echo "Not a git clone — run: git clone <your-repo-url> && cd local-agent"
  exit 1
fi

echo "Checking ${REMOTE}/${BRANCH}..."
git fetch "$REMOTE" "$BRANCH"

LOCAL="$(git rev-parse HEAD)"
REMOTE_SHA="$(git rev-parse "${REMOTE}/${BRANCH}")"

if [[ "$LOCAL" == "$REMOTE_SHA" ]]; then
  echo "Already up to date ($(git rev-parse --short HEAD))."
  exit 0
fi

echo "Updates available $(git rev-parse --short HEAD) → $(git rev-parse --short "$REMOTE_SHA")"
git pull --ff-only "$REMOTE" "$BRANCH"
echo "Pull complete. Restart Open WebUI/Hermes if you changed scripts they depend on."
