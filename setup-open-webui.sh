#!/usr/bin/env bash
# DEPRECATED: Docker-based Open WebUI. Use ./setup-open-webui-native.sh
set -euo pipefail
echo "This script is deprecated (Docker)."
echo "Use: ./setup-open-webui-native.sh"
echo ""
echo "To force Docker anyway, set USE_DOCKER=1"
if [[ "${USE_DOCKER:-0}" != "1" ]]; then
  exit 1
fi

WEBUI_PORT="${WEBUI_PORT:-3000}"
OLLAMA_HOST="${OLLAMA_HOST:-http://host.docker.internal:11434}"

command -v docker &>/dev/null || { echo "Docker required"; exit 1; }
docker info &>/dev/null || { echo "Start Docker Desktop"; exit 1; }

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

echo "Open WebUI (Docker): http://localhost:${WEBUI_PORT}"
