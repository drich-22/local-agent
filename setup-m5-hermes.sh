#!/usr/bin/env bash
# Local Agent — M5 (24GB) setup: Ollama + Qwen 3.6 + Hermes Agent
# Run on the M5 Mac (the compute hub), not the 8GB Air.
#
# Usage:
#   chmod +x setup-m5-hermes.sh
#   ./setup-m5-hermes.sh
#
# After setup:
#   ./run-hermes.sh          # interactive TUI
#   ./run-hermes.sh --help   # other modes

set -euo pipefail

PRIMARY_MODEL="qwen3.6:27b"
FAST_MODEL="qwen2.5-coder:7b"
HERMES_MODEL="qwen3.6-hermes"
CONTEXT_LENGTH=32768
OLLAMA_URL="http://127.0.0.1:11434/v1"

echo "==> Local Agent: Ollama + Hermes setup (24GB Mac)"
echo ""

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# --- Ollama ---
if ! command -v ollama &>/dev/null; then
  echo "==> Installing Ollama..."
  brew install ollama
fi

echo "==> Starting Ollama (context=${CONTEXT_LENGTH})..."
# LaunchAgent so Ollama survives reboots with enough context for Hermes tool calls
mkdir -p "$HOME/Library/LaunchAgents"
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

# Stop brew service if running (avoid duplicate ollama processes)
brew services stop ollama 2>/dev/null || true
launchctl bootout "gui/$(id -u)/com.localagent.ollama" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.localagent.ollama.plist"
launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama"

echo "==> Waiting for Ollama..."
for i in {1..30}; do
  if curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
    break
  fi
  sleep 1
done
if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "ERROR: Ollama did not start. Check ~/.ollama/ollama-serve.err.log"
  exit 1
fi

# --- Pull models (primary + fast fallback) ---
echo "==> Pulling primary model: ${PRIMARY_MODEL} (~17GB, may take a while)..."
ollama pull "${PRIMARY_MODEL}"

echo "==> Pulling fast model: ${FAST_MODEL} (~5GB)..."
ollama pull "${FAST_MODEL}"

# --- Hermes-optimized Modelfile (32k context baked in) ---
echo "==> Creating ${HERMES_MODEL} (32k context for agent tool calls)..."
cat > /tmp/Modelfile.localagent <<EOF
FROM ${PRIMARY_MODEL}
PARAMETER num_ctx ${CONTEXT_LENGTH}
PARAMETER temperature 0.7
PARAMETER top_p 0.9
EOF
ollama create "${HERMES_MODEL}" -f /tmp/Modelfile.localagent
rm /tmp/Modelfile.localagent

# --- Hermes Agent ---
if ! command -v hermes &>/dev/null; then
  echo "==> Installing Hermes Agent..."
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
fi

# Ensure hermes is on PATH for this session
if [[ -f "$HOME/.local/bin/hermes" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

mkdir -p "$HOME/.hermes"
ENV_FILE="$HOME/.hermes/.env"

# Preserve existing keys; update local provider settings
if [[ -f "$ENV_FILE" ]]; then
  cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  grep -v -E '^(CUSTOM_|OLLAMA_)' "$ENV_FILE" > "${ENV_FILE}.tmp" 2>/dev/null || true
  mv "${ENV_FILE}.tmp" "$ENV_FILE"
fi

cat >> "$ENV_FILE" <<EOF

# --- Local Agent (Ollama) — added $(date) ---
CUSTOM_API_KEY=ollama
CUSTOM_BASE_URL=${OLLAMA_URL}
CUSTOM_MODEL=${HERMES_MODEL}
OLLAMA_HOST=127.0.0.1:11434
EOF

echo ""
echo "============================================"
echo "  Setup complete"
echo "============================================"
echo ""
echo "  Primary model : ${HERMES_MODEL}  (from ${PRIMARY_MODEL})"
echo "  Fast model    : ${FAST_MODEL}"
echo "  Ollama API    : ${OLLAMA_URL}"
echo "  Context       : ${CONTEXT_LENGTH} tokens"
echo ""
echo "  Verify Ollama : ollama ps"
echo "  Test model    : ollama run ${HERMES_MODEL} 'write a hello world in python'"
echo "  Run Hermes    : hermes --tui"
echo "  Or use        : ./run-hermes.sh"
echo ""
echo "  Hermes config : ~/.hermes/.env"
echo "============================================"
