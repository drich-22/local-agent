#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PORT="${WEBUI_PORT:-8080}"
echo "==> Open WebUI smoke (port ${PORT})"

if command -v open-webui &>/dev/null; then
  pass "open-webui CLI on PATH"
elif pipx list 2>/dev/null | grep -q open-webui; then
  pass "open-webui installed via pipx"
else
  skip "open-webui not installed (./setup-open-webui-native.sh)"
  summary
  exit 0
fi

if curl -sf --max-time 5 "http://127.0.0.1:${PORT}/" &>/dev/null; then
  pass "HTTP responds on :${PORT}"
elif curl -sf --max-time 5 "http://127.0.0.1:${PORT}/health" &>/dev/null; then
  pass "health endpoint on :${PORT}"
else
  skip "Open WebUI not running — start with ./start.sh"
fi

summary
