#!/usr/bin/env bash
# Local Agent — M5 (24GB): native Ollama + recommended chat models (no Hermes).
#
# Usage:
#   ./setup-m5-ollama.sh
#   ./setup-m5-ollama.sh --harden-only   # refresh LaunchAgent only

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

HARDEN_ONLY=0
[[ "${1:-}" == "--harden-only" ]] && HARDEN_ONLY=1

PRIMARY_MODEL="${PRIMARY_MODEL:-qwen3.6:27b}"
FAST_MODEL="${FAST_MODEL:-qwen2.5-coder:7b}"
CHAT_ALIAS="${CHAT_ALIAS:-local-chat}"
CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-16384}"
VISION_MODEL="${VISION_MODEL:-qwen2.5vl:7b}"
PULL_VISION="${PULL_VISION:-1}"
# Ollama listens on localhost only unless ALLOW_LAN=1 (see docs/HARDENING.md)
OLLAMA_HOST_BIND="${OLLAMA_HOST_BIND:-127.0.0.1:11434}"
if [[ "${ALLOW_LAN:-0}" == "1" ]]; then
  OLLAMA_HOST_BIND="${OLLAMA_HOST_BIND:-0.0.0.0:11434}"
fi

install_ollama_plist() {
  local webui_port="${WEBUI_PORT:-8080}"
  local ollama_origins
  ollama_origins="$(ollama_origins_for_port "$webui_port")"
  echo "==> Configuring Ollama LaunchAgent (context=${CONTEXT_LENGTH}, host=${OLLAMA_HOST_BIND})..."
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.ollama"
  cat > "$HOME/Library/LaunchAgents/com.localagent.ollama.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.localagent.ollama</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(command -v ollama)</string>
    <string>serve</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OLLAMA_HOST</key>
    <string>${OLLAMA_HOST_BIND}</string>
    <key>OLLAMA_CONTEXT_LENGTH</key>
    <string>${CONTEXT_LENGTH}</string>
    <key>OLLAMA_KV_CACHE_TYPE</key>
    <string>q8_0</string>
    <key>OLLAMA_ORIGINS</key>
    <string>${ollama_origins}</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${HOME}/.ollama/ollama-serve.log</string>
  <key>StandardErrorPath</key>
  <string>${HOME}/.ollama/ollama-serve.err.log</string>
</dict>
</plist>
PLIST

  brew services stop ollama 2>/dev/null || true
  launchctl bootout "gui/$(id -u)/com.localagent.ollama" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.localagent.ollama.plist"
  launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama"
}

if [[ "$HARDEN_ONLY" == "1" ]]; then
  command -v ollama &>/dev/null || { echo "ollama not installed"; exit 1; }
  install_ollama_plist
  echo "Ollama LaunchAgent hardened."
  exit 0
fi

echo "==> Local Agent: Ollama setup (24GB Mac, native)"
echo ""

if ! command -v brew &>/dev/null; then
  echo "Homebrew required. Install from https://brew.sh then re-run."
  exit 1
fi

if ! command -v ollama &>/dev/null; then
  echo "==> Installing Ollama..."
  brew install ollama
fi

install_ollama_plist

echo "==> Waiting for Ollama..."
for _ in {1..45}; do
  if curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
    break
  fi
  sleep 1
done
if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "ERROR: Ollama did not start. See ~/.ollama/ollama-serve.err.log"
  exit 1
fi

echo "==> Pulling ${PRIMARY_MODEL}..."
ollama pull "${PRIMARY_MODEL}"

echo "==> Pulling ${FAST_MODEL}..."
ollama pull "${FAST_MODEL}"

if [[ "${PULL_VISION}" == "1" ]]; then
  echo "==> Pulling vision model ${VISION_MODEL}..."
  ollama pull "${VISION_MODEL}" 2>/dev/null || echo "    (skipped — pull failed or model renamed)"
fi

echo "==> Creating chat alias ${CHAT_ALIAS} (ctx=${CONTEXT_LENGTH})..."
cat > /tmp/Modelfile.localagent <<EOF
FROM ${PRIMARY_MODEL}
PARAMETER num_ctx ${CONTEXT_LENGTH}
PARAMETER temperature 0.7
PARAMETER top_p 0.9
EOF
ollama create "${CHAT_ALIAS}" -f /tmp/Modelfile.localagent --force 2>/dev/null \
  || ollama create "${CHAT_ALIAS}" -f /tmp/Modelfile.localagent
rm -f /tmp/Modelfile.localagent

write_hardened_runtime_env "${WEBUI_PORT:-8080}" 2>/dev/null || true

echo ""
echo "============================================"
echo "  Ollama ready (hardened bind: ${OLLAMA_HOST_BIND})"
echo "============================================"
echo "  Chat alias : ${CHAT_ALIAS}"
echo "  Primary    : ${PRIMARY_MODEL}"
echo "  Fast       : ${FAST_MODEL}"
echo "  API        : http://127.0.0.1:11434"
echo ""
echo "  Next: ./setup-open-webui-native.sh"
echo "       ./harden.sh && ./start.sh"
echo "============================================"
