#!/usr/bin/env bash
# First admin only: temporarily allow signup, then re-harden.
# Use once on a fresh Open WebUI DB if you cannot create the admin account.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/security.sh
source "${ROOT}/lib/security.sh"
load_repo_env "$ROOT"

echo "==> Bootstrap: enabling signup for first admin (FG=1)"
echo "Create your admin account in the browser, then Ctrl+C and run: ./harden.sh && ./start.sh"
echo ""

export ALLOW_SIGNUP=1
FG=1 exec "${ROOT}/start.sh"
