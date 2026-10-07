#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "############################################"
echo "# Local Agent — full test suite"
echo "# $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "############################################"
echo ""

FAILED=0
for t in test-shell-syntax.sh test-repo-layout.sh test-secrets.sh test-playbook-audit.sh test-update-dry-run.sh test-ollama-integration.sh test-open-webui-smoke.sh; do
  echo ""
  if bash "${ROOT}/tests/${t}"; then
    echo ">>> ${t}: OK"
  else
    echo ">>> ${t}: FAILED" >&2
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "############################################"
if [[ "$FAILED" -eq 0 ]]; then
  echo "# ALL SUITES PASSED (or skipped live deps)"
  exit 0
else
  echo "# ${FAILED} SUITE(S) FAILED"
  exit 1
fi
