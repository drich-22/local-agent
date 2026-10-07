#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Shell syntax (bash -n)"

while IFS= read -r -d '' script; do
  rel="${script#${ROOT}/}"
  if bash -n "$script"; then pass "bash -n ${rel}"; else fail "bash -n ${rel}"; fi
done < <(find "$ROOT" -name '*.sh' -not -path '*/legacy/*' -print0)

if command -v shellcheck &>/dev/null; then
  echo "==> shellcheck (optional)"
  while IFS= read -r -d '' script; do
    rel="${script#${ROOT}/}"
    if shellcheck -x "$script" 2>/dev/null; then pass "shellcheck ${rel}"; else fail "shellcheck ${rel}"; fi
  done < <(find "$ROOT" -maxdepth 1 -name '*.sh' -print0)
else
  skip "shellcheck not installed (brew install shellcheck)"
fi

summary
