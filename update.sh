#!/usr/bin/env bash
# Pull latest from origin (this repo). Safe to run from cron.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

BRANCH="${UPDATE_BRANCH:-main}"
REMOTE="${UPDATE_REMOTE:-origin}"
EXPECTED_REMOTE_PREFIX="${EXPECTED_REMOTE_PREFIX:-https://github.com/drich-22/local-agent}"

if [[ ! -d .git ]]; then
  echo "Not a git clone — run: git clone <your-repo-url> && cd local-agent"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  if [[ "${UPDATE_ALLOW_DIRTY:-0}" != "1" ]]; then
    echo "ERROR: working tree dirty. Commit/stash or UPDATE_ALLOW_DIRTY=1"
    exit 1
  fi
fi

url="$(git remote get-url "$REMOTE" 2>/dev/null || true)"
if [[ -n "$url" && "$url" != *"drich-22/local-agent"* && "${UPDATE_SKIP_REMOTE_CHECK:-0}" != "1" ]]; then
  echo "WARNING: remote URL is not drich-22/local-agent: ${url}"
  echo "Set UPDATE_SKIP_REMOTE_CHECK=1 to override"
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
if [[ "${UPDATE_AUTO_YES:-0}" != "1" ]]; then
  git log --oneline "${LOCAL}..${REMOTE_SHA}" | head -15
  echo "(set UPDATE_AUTO_YES=1 for non-interactive cron)"
fi

git pull --ff-only "$REMOTE" "$BRANCH"
echo "Pull complete. Restart: ./kill-switch.sh && ./start.sh"
echo "Re-harden if env templates changed: ./harden.sh"
echo "Open WebUI package: pipx upgrade open-webui"
