#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Secret scan (tracked files)"

if git -C "$ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
  files=$(git -C "$ROOT" ls-files)
else
  files=$(find "$ROOT" -type f -not -path '*/.git/*')
fi

bad=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  path="${ROOT}/${f}"
  [[ -f "$path" ]] || continue
  if grep -qE '(gho_|ghp_|sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16})' "$path" 2>/dev/null; then
    fail "possible secret in ${f}"
    bad=1
  fi
done <<< "$files"

[[ "$bad" -eq 0 ]] && pass "no obvious token patterns in tracked files"

grep -qE '^\.env' "${ROOT}/.gitignore" && pass ".gitignore covers .env" || fail ".gitignore missing .env"

summary
