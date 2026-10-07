#!/usr/bin/env bash
# Start Ollama (LaunchAgent) and Open WebUI (foreground or background).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

WEBUI_PORT="${WEBUI_PORT:-8080}"
FG="${FG:-0}"
validate_port "$WEBUI_PORT" || exit 1
BIND_HOST="$(resolve_bind_host)"
export_runtime_env

if [[ ! -f "${LA_RUNTIME_ENV}" ]]; then
  echo "Missing ${LA_RUNTIME_ENV}. Run: ./setup-open-webui-native.sh"
  exit 1
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "Starting Ollama LaunchAgent..."
  launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama" 2>/dev/null \
    || (OLLAMA_HOST=127.0.0.1:11434 ollama serve & sleep 3)
fi

for _ in {1..30}; do
  curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null && break
  sleep 1
done

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "ERROR: Ollama not available on :11434"
  exit 1
fi

if ! command -v open-webui &>/dev/null && ! pipx list 2>/dev/null | grep -q open-webui; then
  echo "Open WebUI not installed. Run ./setup-open-webui-native.sh"
  exit 1
fi

echo "Ollama OK. Open WebUI ${BIND_HOST}:${WEBUI_PORT} (auth=${WEBUI_AUTH})"

if [[ "$FG" == "1" ]]; then
  exec open-webui serve --host "${BIND_HOST}" --port "${WEBUI_PORT}"
fi

mkdir -p "${LA_DATA_DIR}"
nohup open-webui serve --host "${BIND_HOST}" --port "${WEBUI_PORT}" \
  >> "${LA_DATA_DIR}/open-webui-serve.log" 2>&1 &
echo $! > "${LA_DATA_DIR}/open-webui.pid"
sleep 2
echo "Open WebUI: http://127.0.0.1:${WEBUI_PORT} (pid $(cat "${LA_DATA_DIR}/open-webui.pid"))"
