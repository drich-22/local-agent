#!/usr/bin/env bash
# Agent security playbook — repo-level controls (see playbook/README.md)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PLAYBOOK="${AGENT_SECURITY_PLAYBOOK:-${HOME}/.cursor/skills/agent-security-playbook/SKILL.md}"
echo "==> Playbook audit (agent-security-playbook)"

if [[ -f "$PLAYBOOK" ]]; then
  pass "playbook skill present"
elif [[ -f "${ROOT}/playbook/CHECKLIST.md" ]]; then
  pass "embedded playbook/CHECKLIST.md (CI / no Cursor skill)"
else
  fail "no playbook source (skill or playbook/CHECKLIST.md)"
fi

assert_file "docs/SECURITY.md"
assert_file "playbook/README.md"

grep -q 'T3' "${ROOT}/docs/SECURITY.md" && pass "SECURITY.md defines T3 for web/RAG" || fail "SECURITY.md missing T3 guidance"
grep -qi 'lethal trifecta' "${ROOT}/docs/SECURITY.md" && pass "SECURITY.md lethal trifecta" || fail "SECURITY.md missing trifecta"
grep -q 'Never commit' "${ROOT}/docs/SECURITY.md" && pass "SECURITY.md secrets rule" || fail "SECURITY.md secrets"

# Default path must not use curl|bash installer (supply chain / playbook §5.5.14)
if grep -qE 'curl.*install\.sh.*bash' "${ROOT}/setup-m5-ollama.sh" "${ROOT}/setup-open-webui-native.sh" "${ROOT}/start.sh" 2>/dev/null; then
  fail "default setup scripts use curl|bash"
else
  pass "default scripts avoid curl|bash install"
fi

# Hermes curl installer only in legacy
if [[ -f "${ROOT}/legacy/hermes/setup-m5-hermes.sh" ]]; then
  if grep -q 'curl.*hermes.*install' "${ROOT}/legacy/hermes/setup-m5-hermes.sh"; then
    pass "Hermes curl install quarantined under legacy/"
  fi
else
  skip "legacy/hermes not present"
fi

# Web search documented as untrusted
grep -qi 'web search' "${ROOT}/docs/SECURITY.md" && pass "web search risk documented" || fail "document web search"
assert_file "docs/HARDENING.md"
assert_file "docs/INCIDENT-RESPONSE.md"
assert_file "kill-switch.sh"
grep -q 'kill-switch' "${ROOT}/docs/HARDENING.md" && pass "kill switch documented" || fail "kill switch doc"
grep -qi 'T4' "${ROOT}/docs/SECURITY.md" && pass "T4 tier documented" || fail "T4 missing"
grep -qi 'OWASP' "${ROOT}/docs/SECURITY.md" && pass "OWASP pair documented" || fail "OWASP doc"

# .env.example must not contain assignment values that look like real tokens
if grep -vE '^\s*#' "${ROOT}/.env.example" | grep -qE '(gho_|ghp_|sk-[a-zA-Z0-9]{10,})'; then
  fail ".env.example contains token-like values"
else
  pass ".env.example has no token-like values"
fi

# update.sh must not force push or destructive git
assert_grep_absent 'push.*--force' 'update.sh'
grep -q 'ff-only' "${ROOT}/update.sh" && pass "update.sh uses ff-only pull" || fail "update.sh should use --ff-only"

summary
