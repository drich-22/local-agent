#!/usr/bin/env bash
# Rotate WEBUI_SECRET_KEY — forces re-login; re-enter stored API keys in Open WebUI UI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"

echo "This will invalidate sessions and encrypted stored keys in Open WebUI."
read -r -p "Continue? [y/N] " ans
[[ "${ans:-}" == [yY] ]] || exit 0

"${ROOT}/stop.sh" 2>/dev/null || true

if [[ -f "${LA_SECRETS_FILE}" ]]; then
  cp "${LA_SECRETS_FILE}" "${LA_SECRETS_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
fi
rm -f "${LA_SECRETS_FILE}"
write_hardened_runtime_env "${WEBUI_PORT:-8080}"
chmod 600 "${LA_SECRETS_FILE}" "${LA_RUNTIME_ENV}"
echo "Rotated. Run: ./start.sh"
