#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"

echo "==> Hermes gateway LaunchAgent"
launchctl print "gui/$(id -u)/com.localagent.hermes-gateway" 2>/dev/null | head -20 || echo "  (not loaded)"

echo ""
echo "==> Ollama"
curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null && echo "  OK :11434" || echo "  down"

echo ""
if command -v hermes &>/dev/null; then
  echo "==> Hermes cron (if supported)"
  hermes cron status 2>/dev/null || echo "  (run gateway first or check hermes version)"
else
  echo "hermes CLI not in PATH"
fi
