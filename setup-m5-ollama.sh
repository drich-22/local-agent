#!/usr/bin/env bash
# Local Agent — M5 (24GB): native Ollama + recommended chat models (no Hermes).
#
# Usage: ./setup-m5-ollama.sh

set -euo pipefail

PRIMARY_MODEL="${PRIMARY_MODEL:-qwen3.6:27b}"
FAST_MODEL="${FAST_MODEL:-qwen2.5-coder:7b}"
CHAT_ALIAS="${CHAT_ALIAS:-local-chat}"
CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-16384}"
VISION_MODEL="${VISION_MODEL:-qwen2.5vl:7b}"
PULL_VISION="${PULL_VISION:-1}"

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

echo "==> Configuring Ollama LaunchAgent (context=${CONTEXT_LENGTH})..."
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
    <key>OLLAMA_CONTEXT_LENGTH</key>
    <string>${CONTEXT_LENGTH}</string>
    <key>OLLAMA_KV_CACHE_TYPE</key>
    <string>q8_0</string>
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

echo ""
echo "============================================"
echo "  Ollama ready"
echo "============================================"
echo "  Chat alias : ${CHAT_ALIAS}"
echo "  Primary    : ${PRIMARY_MODEL}"
echo "  Fast       : ${FAST_MODEL}"
echo "  API        : http://127.0.0.1:11434"
echo ""
echo "  Next: ./setup-open-webui-native.sh"
echo "       ./start.sh"
echo "============================================"
