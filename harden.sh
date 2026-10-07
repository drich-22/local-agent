#!/usr/bin/env bash
# Apply + verify Local Agent hardening (run after setup or policy change).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

echo "==> Local Agent hardening pass"
echo ""

PORT="${WEBUI_PORT:-8080}"
validate_port "$PORT" || { echo "Invalid WEBUI_PORT"; exit 1; }

write_hardened_runtime_env "$PORT"
export_runtime_env

echo "  Runtime env : ${LA_RUNTIME_ENV} (mode $(stat -f %Lp "${LA_RUNTIME_ENV}" 2>/dev/null || stat -c %a "${LA_RUNTIME_ENV}" 2>/dev/null))"
echo "  Secrets     : ${LA_SECRETS_FILE} (mode $(stat -f %Lp "${LA_SECRETS_FILE}" 2>/dev/null || echo '?'))"

# Re-render Ollama plist with localhost bind if setup script present
if [[ -x "${ROOT}/setup-m5-ollama.sh" ]]; then
  echo "  Re-applying Ollama LaunchAgent (127.0.0.1)..."
  bash "${ROOT}/setup-m5-ollama.sh" --harden-only 2>/dev/null \
    || echo "  (run ./setup-m5-ollama.sh fully if Ollama not installed)"
fi

if [[ -x "${ROOT}/setup-open-webui-native.sh" ]]; then
  echo "  Refreshing Open WebUI hardened env..."
  bash "${ROOT}/setup-open-webui-native.sh" --harden-only 2>/dev/null || true
fi

echo ""
echo "==> Running test suite..."
bash "${ROOT}/tests/run-all.sh"

echo ""
echo "==> Hardening complete. Restart: ./stop.sh && ./start.sh"
