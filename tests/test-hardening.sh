#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Hardening enforcement (static)"

# No wide bind without ALLOW_LAN gate in start.sh
grep -q 'resolve_bind_host' "${ROOT}/start.sh" && pass "start.sh uses resolve_bind_host" || fail "start.sh missing bind guard"
grep -q 'ALLOW_LAN' "${ROOT}/lib/security.sh" && pass "ALLOW_LAN gate in lib/security.sh" || fail "missing ALLOW_LAN"

# Ollama localhost
grep -q 'OLLAMA_HOST' "${ROOT}/setup-m5-ollama.sh" && pass "Ollama OLLAMA_HOST in plist" || fail "Ollama bind missing"

# Hardened env template
grep -q 'WEBUI_AUTH=true' "${ROOT}/config/open-webui-hardened.env.example" && pass "hardened env example auth" || fail
grep -q 'ENABLE_SIGNUP=false' "${ROOT}/config/open-webui-hardened.env.example" && pass "hardened env signup off" || fail
grep -q 'AIOHTTP_CLIENT_SESSION_REDIRECT=false' "${ROOT}/lib/security.sh" && pass "redirect SSRF flag in security lib" || fail

assert_file "lib/security.sh"
assert_file "kill-switch.sh"
assert_file "harden.sh"
assert_file "docs/HARDENING.md"
assert_file "docs/INCIDENT-RESPONSE.md"
assert_executable "kill-switch.sh"
assert_executable "harden.sh"

# start.sh must not hardcode 0.0.0.0 without guard
if grep -q '0\.0\.0\.0' "${ROOT}/start.sh" && ! grep -q 'resolve_bind_host' "${ROOT}/start.sh"; then
  fail "start.sh binds 0.0.0.0 without guard"
else
  pass "start.sh bind pattern OK"
fi

# update.sh protections
grep -q 'ff-only' "${ROOT}/update.sh" && pass "update ff-only" || fail
grep -q 'UPDATE_ALLOW_DIRTY' "${ROOT}/update.sh" && pass "update dirty guard" || fail
grep -q 'local-agent' "${ROOT}/update.sh" && pass "update remote check" || fail

# Docker path requires explicit opt-in
grep -q 'USE_DOCKER' "${ROOT}/setup-open-webui.sh" && pass "docker deprecated gate" || fail

# Legacy hermes not on default path
if [[ -f "${ROOT}/setup-m5-hermes.sh" ]]; then
  fail "Hermes setup should not be at repo root"
else
  pass "Hermes not at root"
fi

summary
