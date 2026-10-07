#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Hardening enforcement (static)"

grep -q 'resolve_bind_host' "${ROOT}/start.sh" && pass "start.sh uses resolve_bind_host" || fail "start.sh missing bind guard"
grep -q 'assert_secure_runtime' "${ROOT}/start.sh" && pass "start.sh enforces secure runtime" || fail "start.sh missing assert_secure_runtime"
grep -q 'ALLOW_LAN' "${ROOT}/lib/security.sh" && pass "ALLOW_LAN gate in lib/security.sh" || fail "missing ALLOW_LAN"
grep -q 'ALLOW_INSECURE' "${ROOT}/lib/security.sh" && pass "ALLOW_INSECURE gate for auth" || fail "missing ALLOW_INSECURE"
grep -q 'OLLAMA_ORIGINS' "${ROOT}/setup-m5-ollama.sh" && pass "OLLAMA_ORIGINS in plist" || fail "missing OLLAMA_ORIGINS"

grep -q 'WEBUI_AUTH=true' "${ROOT}/config/open-webui-hardened.env.example" && pass "hardened env example auth" || fail
grep -q 'ENABLE_SIGNUP=false' "${ROOT}/config/open-webui-hardened.env.example" && pass "hardened env signup off" || fail
grep -q 'AIOHTTP_CLIENT_SESSION_REDIRECT=false' "${ROOT}/lib/security.sh" && pass "redirect SSRF flag in security lib" || fail

assert_file "lib/security.sh"
assert_file "kill-switch.sh"
assert_file "harden.sh"
assert_file "verify-live.sh"
assert_file "install.sh"
assert_file "docs/HARDENING.md"
assert_file "docs/INCIDENT-RESPONSE.md"
assert_executable "kill-switch.sh"
assert_executable "harden.sh"
assert_executable "verify-live.sh"
assert_executable "install.sh"

grep -q '127.0.0.1' "${ROOT}/setup-open-webui.sh" && pass "docker publish localhost by default" || fail "docker bind"
grep -q 'ENABLE_SIGNUP=false' "${ROOT}/setup-open-webui.sh" && pass "docker signup off" || fail
grep -q 'WEBUI_SECRET_KEY' "${ROOT}/setup-open-webui.sh" && pass "docker secret key" || fail

grep -q 'LEGACY_HERMES' "${ROOT}/legacy/hermes/_guard.sh" && pass "legacy hermes guard" || fail "legacy guard"

grep -q 'ff-only' "${ROOT}/update.sh" && pass "update ff-only" || fail
grep -q 'UPDATE_ALLOW_DIRTY' "${ROOT}/update.sh" && pass "update dirty guard" || fail
grep -q 'local-agent' "${ROOT}/update.sh" && pass "update remote check" || fail
grep -q 'USE_DOCKER' "${ROOT}/setup-open-webui.sh" && pass "docker deprecated gate" || fail

if [[ -f "${ROOT}/setup-m5-hermes.sh" ]]; then
  fail "Hermes setup should not be at repo root"
else
  pass "Hermes not at root"
fi

summary
