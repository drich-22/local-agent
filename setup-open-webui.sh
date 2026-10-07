#!/usr/bin/env bash
# Local "Infinet" alternative: Open WebUI + Ollama on M5
# ChatGPT-style UI, voice, vision, web search, multi-model — all local.
#
# Prerequisites: Ollama installed and running (qwen3.6:27b recommended)
# Usage: ./setup-open-webui.sh

set -euo pipefail

WEBUI_PORT="${WEBUI_PORT:-3000}"
OLLAMA_HOST="${OLLAMA_HOST:-http://host.docker.internal:11434}"

echo "==> Local chat UI: Open WebUI (Infinet alternative)"
echo ""

if ! command -v docker &>/dev/null; then
  echo "Docker not found. Install Docker Desktop for Mac:"
  echo "  https://www.docker.com/products/docker-desktop/"
  exit 1
fi

if ! docker info &>/dev/null 2>&1; then
  echo "Docker is installed but not running. Start Docker Desktop, then re-run."
  exit 1
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  echo "WARNING: Ollama not responding on :11434. Start Ollama first."
  echo "  ollama serve   (or open the Ollama app)"
fi

# Pull recommended chat + vision models (skip if already present)
if command -v ollama &>/dev/null; then
  echo "==> Ensuring chat models..."
  ollama pull qwen3.6:27b 2>/dev/null || true
  ollama pull qwen2.5-coder:7b 2>/dev/null || true
  echo "==> Pulling vision model (for image analysis like Infinet)..."
  ollama pull qwen2.5vl:7b 2>/dev/null || true
fi

echo "==> Starting Open WebUI..."
docker rm -f open-webui 2>/dev/null || true

docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p "${WEBUI_PORT}:8080" \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL="${OLLAMA_HOST}" \
  -e WEBUI_AUTH=true \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

echo ""
echo "============================================"
echo "  Open WebUI is starting"
echo "============================================"
echo ""
echo "  URL (on M5):     http://localhost:${WEBUI_PORT}"
echo "  URL (phone):     http://<M5-tailscale-ip>:${WEBUI_PORT}  (after Tailscale)"
echo ""
echo "  First visit: create your admin account"
echo ""
echo "  Recommended models in UI:"
echo "    Chat:    qwen3.6-hermes  (or qwen3.6:27b)"
echo "    Fast:    qwen2.5-coder:7b"
echo "    Vision:  qwen2.5vl:7b"
echo ""
echo "  Enable in Settings:"
echo "    • Web Search → DuckDuckGo or SearXNG"
echo "    • Audio → Whisper (local STT) for voice input"
echo "    • Documents → upload PDFs for RAG"
echo ""
echo "  Agent mode (tools/files): use Hermes separately"
echo "    hermes --tui"
echo "============================================"
