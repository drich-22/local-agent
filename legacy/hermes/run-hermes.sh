#!/usr/bin/env bash
# Launch Hermes Agent against local Ollama (qwen3.6-hermes).
# Run on the M5 after setup-m5-hermes.sh

set -euo pipefail
# shellcheck source=_guard.sh
source "$(dirname "$0")/_guard.sh"

export PATH="$HOME/.local/bin:$PATH"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-32768}"

HERMES_MODEL="${HERMES_MODEL:-qwen3.6-hermes}"

# Ensure Ollama is reachable
if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "Ollama is not running. Starting..."
  launchctl kickstart -k "gui/$(id -u)/com.localagent.ollama" 2>/dev/null \
    || ollama serve &
  sleep 3
fi

if ! command -v hermes &>/dev/null; then
  echo "Hermes not found. Run ./setup-m5-hermes.sh first."
  exit 1
fi

# Pre-warm the model so first Hermes response isn't slow
echo "Loading ${HERMES_MODEL}..."
ollama run "${HERMES_MODEL}" "ping" --verbose 2>/dev/null | head -1 || true

echo ""
echo "Starting Hermes (local model: ${HERMES_MODEL})..."
echo "Press Ctrl+C to exit."
echo ""

# Default: TUI. Pass any hermes flags through, e.g. ./run-hermes.sh --help
if [[ $# -eq 0 ]]; then
  exec hermes --tui
else
  exec hermes "$@"
fi
