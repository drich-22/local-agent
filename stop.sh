#!/usr/bin/env bash
set -euo pipefail
PID_FILE="${HOME}/.local/share/open-webui/open-webui.pid"
if [[ -f "$PID_FILE" ]]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  rm -f "$PID_FILE"
  echo "Stopped Open WebUI"
else
  pkill -f "open-webui serve" 2>/dev/null || echo "Open WebUI was not running"
fi
