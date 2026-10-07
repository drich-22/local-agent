#!/usr/bin/env bash
# Live hardening verification (run on M5 with stack up or after start).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

WEBUI_PORT="${WEBUI_PORT:-8080}"
FAIL=0

warn() { echo "WARN: $*" >&2; FAIL=$((FAIL + 1)); }
ok() { echo "OK: $*"; }

echo "==> Live hardening verification"

[[ -f "${LA_RUNTIME_ENV}" ]] && ok "runtime env present" || warn "missing ${LA_RUNTIME_ENV}"
[[ -f "${LA_SECRETS_FILE}" ]] && ok "secrets file present" || warn "missing secrets"
check_path_permissions

if command -v lsof &>/dev/null; then
  if lsof -nP -iTCP:11434 -sTCP:LISTEN 2>/dev/null | grep -q .; then
    if lsof -nP -iTCP:11434 -sTCP:LISTEN 2>/dev/null | grep -qE '127\.0\.0\.1:11434|\*:11434|0\.0\.0\.0:11434'; then
      if [[ "${ALLOW_LAN:-0}" != "1" ]] && lsof -nP -iTCP:11434 -sTCP:LISTEN 2>/dev/null | grep -qE '\*:11434|0\.0\.0\.0:11434'; then
        warn "Ollama listening on all interfaces with ALLOW_LAN=0"
      else
        ok "Ollama listen check"
      fi
    fi
  else
    warn "Ollama not listening on 11434"
  fi

  if lsof -nP -iTCP:"${WEBUI_PORT}" -sTCP:LISTEN 2>/dev/null | grep -q .; then
    if [[ "${ALLOW_LAN:-0}" != "1" ]] && lsof -nP -iTCP:"${WEBUI_PORT}" -sTCP:LISTEN 2>/dev/null | grep -qE '\*:|\[::\]'; then
      warn "WebUI on ${WEBUI_PORT} is LAN-visible but ALLOW_LAN=0"
    else
      ok "WebUI listen on ${WEBUI_PORT}"
    fi
  else
    warn "WebUI not listening on ${WEBUI_PORT} (start with ./start.sh)"
  fi
else
  warn "lsof not available — skip port bind checks"
fi

if curl -sf --max-time 3 "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  ok "Ollama HTTP"
else
  warn "Ollama HTTP unreachable"
fi

PLIST="${HOME}/Library/LaunchAgents/com.localagent.ollama.plist"
if [[ -f "$PLIST" ]]; then
  if grep -q '127.0.0.1:11434' "$PLIST" || [[ "${ALLOW_LAN:-0}" == "1" ]]; then
    ok "Ollama plist bind policy"
  else
    warn "Ollama plist may not bind localhost"
  fi
  if grep -q 'OLLAMA_ORIGINS' "$PLIST"; then
    ok "OLLAMA_ORIGINS set"
  else
    warn "OLLAMA_ORIGINS missing from plist — re-run ./setup-m5-ollama.sh --harden-only"
  fi
else
  warn "Ollama LaunchAgent plist missing"
fi

export_runtime_env
auth="$(echo "${WEBUI_AUTH:-}" | tr '[:upper:]' '[:lower:]')"
[[ "$auth" == "true" || "$auth" == "1" ]] && ok "WEBUI_AUTH enabled" || warn "WEBUI_AUTH not true"

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "Live verification: PASS"
  exit 0
fi
echo "Live verification: ${FAIL} warning(s)"
exit 1
