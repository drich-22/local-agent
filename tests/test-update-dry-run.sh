#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> update.sh dry run"

cd "$ROOT"
git fetch origin main 2>/dev/null && pass "git fetch origin main" || skip "fetch failed (offline or no remote)"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "")
if [[ -n "$REMOTE" ]]; then
  if [[ "$LOCAL" == "$REMOTE" ]]; then pass "main matches origin/main"; else pass "updates available (expected during dev)"; fi
fi

summary
