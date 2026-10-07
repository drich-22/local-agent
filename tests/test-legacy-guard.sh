#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Legacy Hermes guard"

out="$(LEGACY_HERMES=0 bash "${ROOT}/legacy/hermes/run-hermes.sh" 2>&1)" || true
if echo "$out" | grep -qi 'deprecated'; then
  pass "run-hermes blocked without LEGACY_HERMES"
else
  fail "run-hermes should refuse without LEGACY_HERMES"
fi

summary
