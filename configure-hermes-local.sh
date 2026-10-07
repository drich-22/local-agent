#!/usr/bin/env bash
# Configure existing Ollama + Hermes for local agent coding (24GB Mac).
# Skips install — only pulls models, creates Modelfile, updates ~/.hermes/.env
#
# Usage: ./configure-hermes-local.sh

set -euo pipefail

PRIMARY_MODEL="qwen3.6:27b"
FAST_MODEL="qwen2.5-coder:7b"
HERMES_MODEL="qwen3.6-hermes"
CONTEXT_LENGTH=32768
OLLAMA_URL="http://127.0.0.1:11434/v1"

echo "==> Configure local Hermes + Ollama (existing install)"

if ! command -v ollama &>/dev/null; then
  echo "ERROR: ollama not found"
  exit 1
fi

if ! command -v hermes &>/dev/null && [[ ! -f "$HOME/.local/bin/hermes" ]]; then
  echo "ERROR: hermes not found (expected in PATH or ~/.local/bin/hermes)"
  exit 1
fi

# Ensure Ollama is up
if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "==> Starting Ollama with OLLAMA_CONTEXT_LENGTH=${CONTEXT_LENGTH}..."
  OLLAMA_CONTEXT_LENGTH="${CONTEXT_LENGTH}" OLLAMA_KV_CACHE_TYPE=q8_0 ollama serve &
  sleep 4
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "ERROR: Ollama not responding on :11434. Start it manually:"
  echo "  OLLAMA_CONTEXT_LENGTH=${CONTEXT_LENGTH} ollama serve"
  exit 1
fi

echo "==> Current Ollama models:"
ollama list

echo ""
echo "==> Pulling ${PRIMARY_MODEL} (skip if already present)..."
ollama pull "${PRIMARY_MODEL}"

echo "==> Pulling ${FAST_MODEL} (skip if already present)..."
ollama pull "${FAST_MODEL}"

echo "==> Creating ${HERMES_MODEL} (${CONTEXT_LENGTH} context)..."
cat > /tmp/Modelfile.localagent <<EOF
FROM ${PRIMARY_MODEL}
PARAMETER num_ctx ${CONTEXT_LENGTH}
PARAMETER temperature 0.7
PARAMETER top_p 0.9
EOF
ollama create "${HERMES_MODEL}" -f /tmp/Modelfile.localagent --force 2>/dev/null \
  || ollama create "${HERMES_MODEL}" -f /tmp/Modelfile.localagent
rm /tmp/Modelfile.localagent

mkdir -p "$HOME/.hermes"
ENV_FILE="$HOME/.hermes/.env"

if [[ -f "$ENV_FILE" ]]; then
  cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  grep -v -E '^(CUSTOM_|OLLAMA_)' "$ENV_FILE" > "${ENV_FILE}.tmp" 2>/dev/null || true
  mv "${ENV_FILE}.tmp" "$ENV_FILE"
fi

cat >> "$ENV_FILE" <<EOF

# --- Local Agent (Ollama) — $(date) ---
CUSTOM_API_KEY=ollama
CUSTOM_BASE_URL=${OLLAMA_URL}
CUSTOM_MODEL=${HERMES_MODEL}
OLLAMA_HOST=127.0.0.1:11434
EOF

echo ""
echo "============================================"
echo "  Done"
echo "============================================"
echo "  Model : ${HERMES_MODEL}"
echo "  Config: ~/.hermes/.env"
echo ""
echo "  Test  : ollama run ${HERMES_MODEL} 'hello'"
echo "  Run   : hermes --tui"
echo "  Or    : ./run-hermes.sh"
echo "============================================"
