#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Repository layout"

for f in README.md .gitignore .env.example setup-m5-ollama.sh setup-open-webui-native.sh start.sh stop.sh update.sh playbook/README.md docs/SECURITY.md; do
  assert_file "$f"
done

for f in setup-m5-ollama.sh setup-open-webui-native.sh start.sh stop.sh update.sh tests/run-all.sh; do
  assert_executable "$f"
done

if [[ -d "${ROOT}/.git" ]]; then pass "git repository initialized"; else fail "not a git repo"; fi

if grep -q 'Hermes' "${ROOT}/README.md" && grep -q 'legacy' "${ROOT}/README.md"; then
  pass "README documents Hermes as legacy"
else
  fail "README should mark Hermes legacy and point to native stack"
fi

summary
