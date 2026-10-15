#!/usr/bin/env bash
# Daily Local Agent run: update repo, audit tests, live verify, optional Hermes status.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================="
echo " Local Agent — daily run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "=============================================="

echo ""
echo "==> Git update (ff-only)"
UPDATE_AUTO_YES=1 ./update.sh || echo "  (update skipped or failed — check git status)"

echo ""
echo "==> Test suite"
./tests/run-all.sh

echo ""
echo "==> Hardened env refresh"
if [[ -f "${ROOT}/lib/security.sh" ]]; then
  # shellcheck source=lib/security.sh
  source "${ROOT}/lib/security.sh"
  load_repo_env "$ROOT"
  write_hardened_runtime_env "${WEBUI_PORT:-8080}" 2>/dev/null || echo "  (harden env skip — run setup first)"
fi

echo ""
echo "==> Live verification"
./verify-live.sh || echo "  (live verify warnings — expected if stack not running on this host)"

if [[ -x "${ROOT}/hermes-daemon/status.sh" ]]; then
  echo ""
  echo "==> Hermes gateway"
  "${ROOT}/hermes-daemon/status.sh" || true
fi

echo ""
echo "Daily run complete."
