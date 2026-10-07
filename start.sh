#!/usr/bin/env bash
# Start Ollama (LaunchAgent) and Open WebUI (foreground or background).
set -euo pipefail

WEBUI_PORT="${WEBUI_PORT:-8080}"
FG="${FG:-0}"

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "Starting Ollama LaunchAgent..."
  launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama" 2>/dev/null \
    || (ollama serve & sleep 3)
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
  echo "Open WebUI not installed. Run: ./setup-open-webui-native.sh"
  exit 1
fi

echo "Ollama OK. Starting Open WebUI on :${WEBUI_PORT}..."
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434}"

if [[ "$FG" == "1" ]]; then
  exec open-webui serve --host 0.0.0.0 --port "${WEBUI_PORT}"
fi

nohup open-webui serve --host 0.0.0.0 --port "${WEBUI_PORT}" \
  >> "${HOME}/.local/share/open-webui/open-webui-serve.log" 2>&1 &
echo $! > "${HOME}/.local/share/open-webui/open-webui.pid"
sleep 2
echo "Open WebUI: http://localhost:${WEBUI_PORT} (pid $(cat "${HOME}/.local/share/open-webui/open-webui.pid"))"
