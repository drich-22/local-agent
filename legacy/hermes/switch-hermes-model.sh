#!/usr/bin/env bash
# Switch Hermes between local models without re-running full setup.
#
# Usage:
#   ./switch-hermes-model.sh              # show current + options
#   ./switch-hermes-model.sh primary      # qwen3.6-hermes (agentic, recommended)
#   ./switch-hermes-model.sh fast         # qwen2.5-coder:7b (quick tasks)
#   ./switch-hermes-model.sh raw          # qwen3.6:27b (no custom ctx Modelfile)

set -euo pipefail

ENV_FILE="$HOME/.hermes/.env"
MODE="${1:-}"

show_status() {
  echo "Current Hermes model:"
  grep '^CUSTOM_MODEL=' "$ENV_FILE" 2>/dev/null || echo "  (not configured — run setup-m5-hermes.sh)"
  echo ""
  echo "Available modes:"
  echo "  primary  → qwen3.6-hermes     (32k ctx, best for agent work)"
  echo "  fast     → qwen2.5-coder:7b  (low RAM, quick edits)"
  echo "  raw      → qwen3.6:27b       (base model, default Ollama ctx)"
}

set_model() {
  local model="$1"
  mkdir -p "$HOME/.hermes"
  if [[ -f "$ENV_FILE" ]]; then
    if grep -q '^CUSTOM_MODEL=' "$ENV_FILE"; then
      sed -i.bak "s|^CUSTOM_MODEL=.*|CUSTOM_MODEL=${model}|" "$ENV_FILE"
    else
      echo "CUSTOM_MODEL=${model}" >> "$ENV_FILE"
    fi
  else
    cat > "$ENV_FILE" <<EOF
CUSTOM_API_KEY=ollama
CUSTOM_BASE_URL=http://127.0.0.1:11434/v1
CUSTOM_MODEL=${model}
EOF
  fi
  echo "Switched to: ${model}"
  echo "Run: ./run-hermes.sh"
}

case "$MODE" in
  primary) set_model "qwen3.6-hermes" ;;
  fast)    set_model "qwen2.5-coder:7b" ;;
  raw)     set_model "qwen3.6:27b" ;;
  "")      show_status ;;
  *)
    echo "Unknown mode: $MODE"
    show_status
    exit 1
    ;;
esac
