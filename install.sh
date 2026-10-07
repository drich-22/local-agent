#!/usr/bin/env bash
# One-shot install: Ollama + Open WebUI + hardening (native path).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> Local Agent install (native, hardened)"
bash "${ROOT}/setup-m5-ollama.sh"
bash "${ROOT}/setup-open-webui-native.sh"
bash "${ROOT}/harden.sh"
echo ""
echo "Install complete. Start with: ./start.sh"
echo "Verify: ./verify-live.sh"
