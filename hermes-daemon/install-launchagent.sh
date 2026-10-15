#!/usr/bin/env bash
# macOS LaunchAgent: Hermes gateway (KeepAlive).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATEWAY_SCRIPT="${ROOT}/hermes-daemon/run-gateway.sh"
LABEL="com.localagent.hermes-gateway"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

[[ -x "$GATEWAY_SCRIPT" ]] || chmod +x "$GATEWAY_SCRIPT"

if ! command -v hermes &>/dev/null && [[ ! -x "${HOME}/.local/bin/hermes" ]]; then
  echo "Install Hermes first: LEGACY_HERMES=1 ${ROOT}/legacy/hermes/setup-m5-hermes.sh"
  exit 1
fi

mkdir -p "${HOME}/.local/share/hermes-gateway" "${HOME}/Library/LaunchAgents"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${GATEWAY_SCRIPT}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_CONTEXT_LENGTH</key>
    <string>${OLLAMA_CONTEXT_LENGTH:-16384}</string>
    <key>PATH</key>
    <string>${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/.local/share/hermes-gateway/gateway.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.local/share/hermes-gateway/gateway.err.log</string>
  <key>ThrottleInterval</key>
  <integer>10</integer>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/${LABEL}"

echo "Installed ${LABEL}"
echo "Logs: ~/.local/share/hermes-gateway/gateway.log"
echo "Status: ${ROOT}/hermes-daemon/status.sh"
