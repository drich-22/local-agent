#!/usr/bin/env bash
# Open WebUI via pipx — native on macOS (no Docker). Talks to host Ollama on :11434.
#
# Usage: ./setup-open-webui-native.sh

set -euo pipefail

WEBUI_PORT="${WEBUI_PORT:-8080}"
PYTHON_VERSION="${OPEN_WEBUI_PYTHON:-3.11}"

echo "==> Open WebUI (native pipx)"
echo ""

if ! command -v brew &>/dev/null; then
  echo "Homebrew required."
  exit 1
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "WARNING: Ollama not on :11434. Run ./setup-m5-ollama.sh first."
fi

if ! command -v pipx &>/dev/null; then
  echo "==> Installing pipx..."
  brew install pipx
  pipx ensurepath
fi

echo "==> Installing open-webui (Python ${PYTHON_VERSION})..."
pipx install --fetch-python=missing --python "${PYTHON_VERSION}" open-webui --force

echo "==> System deps for Open WebUI (pandoc, ffmpeg)..."
brew install pandoc ffmpeg 2>/dev/null || true

mkdir -p "$HOME/Library/LaunchAgents"
PLIST="$HOME/Library/LaunchAgents/com.localagent.open-webui.plist"
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.localagent.open-webui</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(command -v pipx)</string>
    <string>run</string>
    <string>open-webui</string>
    <string>serve</string>
    <string>--host</string>
    <string>0.0.0.0</string>
    <string>--port</string>
    <string>${WEBUI_PORT}</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_BASE_URL</key>
    <string>http://127.0.0.1:11434</string>
  </dict>
  <key>RunAtLoad</key>
  <false/>
  <key>KeepAlive</key>
  <false/>
  <key>StandardOutPath</key>
  <string>${HOME}/.local/share/open-webui/open-webui-serve.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.local/share/open-webui/open-webui-serve.err.log</string>
</dict>
</plist>
PLIST

echo ""
echo "============================================"
echo "  Open WebUI installed (native)"
echo "============================================"
echo "  Manual:  open-webui serve --port ${WEBUI_PORT}"
echo "  Or:      ./start.sh"
echo "  URL:     http://localhost:${WEBUI_PORT}"
echo ""
echo "  Enable in Settings: Web Search, Documents, Audio"
echo "  Default Ollama: http://127.0.0.1:11434"
echo "============================================"
