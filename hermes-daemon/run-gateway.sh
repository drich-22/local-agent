#!/usr/bin/env bash
# Foreground Hermes gateway (Ollama via ~/.hermes/.env).
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-16384}"

HERMES_BIN="$(command -v hermes || true)"
if [[ -z "$HERMES_BIN" ]]; then
  echo "hermes not found. LEGACY_HERMES=1 ./legacy/hermes/setup-m5-hermes.sh"
  exit 1
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama" 2>/dev/null || true
  sleep 2
fi

LOG_DIR="${HOME}/.local/share/hermes-gateway"
mkdir -p "$LOG_DIR"
cd "$LOG_DIR"

echo "Starting Hermes gateway ($(date -u +%FT%TZ))"
exec "$HERMES_BIN" gateway
