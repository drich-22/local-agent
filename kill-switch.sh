#!/usr/bin/env bash
# Emergency stop: Open WebUI + optional Ollama. Test regularly (playbook: kill switch).
set -euo pipefail

STOP_OLLAMA="${STOP_OLLAMA:-0}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"

echo "==> Kill switch: stopping Local Agent services"

"${ROOT}/stop.sh" 2>/dev/null || true

pkill -f "open-webui serve" 2>/dev/null || true
pkill -f "uvicorn open_webui" 2>/dev/null || true

if [[ "$STOP_OLLAMA" == "1" ]]; then
  launchctl bootout "gui/$(id -u)/com.localagent.ollama" 2>/dev/null || true
  pkill -x ollama 2>/dev/null || true
  echo "Ollama stopped (STOP_OLLAMA=1)"
fi

if curl -sf --max-time 2 "http://127.0.0.1:${WEBUI_PORT:-8080}/" &>/dev/null; then
  echo "WARNING: WebUI still responding — check processes manually"
  exit 1
fi

echo "Kill switch OK — WebUI down, Ollama ${STOP_OLLAMA:+stopped}${STOP_OLLAMA:-left running}"
