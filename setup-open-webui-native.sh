#!/usr/bin/env bash
# Open WebUI via pipx — native on macOS (no Docker). Talks to host Ollama on :11434.
#
# Usage:
#   ./setup-open-webui-native.sh
#   ./setup-open-webui-native.sh --harden-only

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

HARDEN_ONLY=0
[[ "${1:-}" == "--harden-only" ]] && HARDEN_ONLY=1

WEBUI_PORT="${WEBUI_PORT:-8080}"
validate_port "$WEBUI_PORT" || exit 1
PYTHON_VERSION="${OPEN_WEBUI_PYTHON:-3.11}"
BIND_HOST="$(resolve_bind_host)"

write_hardened_runtime_env "$WEBUI_PORT"
export_runtime_env

if [[ "$HARDEN_ONLY" == "1" ]]; then
  echo "Hardened env written to ${LA_RUNTIME_ENV}"
  exit 0
fi

echo "==> Open WebUI (native pipx, bind=${BIND_HOST})"
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
    <string>${ROOT}/start.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>FG</key>
    <string>1</string>
    <key>BIND_HOST</key>
    <string>${BIND_HOST}</string>
    <key>WEBUI_PORT</key>
    <string>${WEBUI_PORT}</string>
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
echo "  Open WebUI installed (native, hardened)"
echo "============================================"
echo "  Auth/signup : WEBUI_AUTH=true, ENABLE_SIGNUP=false"
echo "  Secrets     : ${LA_SECRETS_FILE}"
echo "  Runtime env : ${LA_RUNTIME_ENV}"
echo "  Bind        : ${BIND_HOST}:${WEBUI_PORT}"
echo "  Start       : ./start.sh"
echo "  URL         : http://127.0.0.1:${WEBUI_PORT}"
echo "============================================"
