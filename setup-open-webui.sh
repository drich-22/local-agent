#!/usr/bin/env bash
# DEPRECATED: Docker-based Open WebUI. Use ./setup-open-webui-native.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

echo "This script is deprecated (Docker)."
echo "Use: ./setup-open-webui-native.sh"
echo ""
echo "To force Docker anyway, set USE_DOCKER=1"
if [[ "${USE_DOCKER:-0}" != "1" ]]; then
  exit 1
fi

WEBUI_PORT="${WEBUI_PORT:-3000}"
validate_port "$WEBUI_PORT" || exit 1
write_hardened_runtime_env "$WEBUI_PORT"
export_runtime_env
read_secret_key

# Publish on localhost only unless LAN explicitly allowed
DOCKER_BIND="127.0.0.1"
if [[ "${ALLOW_LAN:-0}" == "1" ]]; then
  DOCKER_BIND="0.0.0.0"
  echo "WARNING: Docker publishing on all interfaces (ALLOW_LAN=1)"
fi

OLLAMA_HOST="${OLLAMA_HOST:-http://host.docker.internal:11434}"

command -v docker &>/dev/null || { echo "Docker required"; exit 1; }
docker info &>/dev/null || { echo "Start Docker Desktop"; exit 1; }

docker rm -f open-webui 2>/dev/null || true
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p "${DOCKER_BIND}:${WEBUI_PORT}:8080" \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL="${OLLAMA_HOST}" \
  -e WEBUI_AUTH=true \
  -e ENABLE_SIGNUP=false \
  -e ENABLE_COMMUNITY_SHARING=false \
  -e WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY}" \
  -e AIOHTTP_CLIENT_SESSION_REDIRECT=false \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

echo "Open WebUI (Docker): http://127.0.0.1:${WEBUI_PORT}"
