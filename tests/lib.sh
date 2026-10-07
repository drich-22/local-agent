#!/usr/bin/env bash
# Shared test helpers
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $*"; SKIP=$((SKIP + 1)); }

assert_file() {
  local f="$1"
  if [[ -f "${ROOT}/${f}" ]]; then pass "file exists: ${f}"; else fail "missing file: ${f}"; fi
}

assert_executable() {
  local f="$1"
  if [[ -x "${ROOT}/${f}" ]]; then pass "executable: ${f}"; else fail "not executable: ${f}"; fi
}

assert_grep_absent() {
  local pattern="$1" file="$2"
  if grep -qE "$pattern" "${ROOT}/${file}" 2>/dev/null; then
    fail "${file} contains forbidden pattern: ${pattern}"
  else
    pass "${file} clean of: ${pattern}"
  fi
}

summary() {
  echo ""
  echo "========== Summary =========="
  echo "PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"
  if [[ "${FAIL}" -gt 0 ]]; then return 1; fi
  return 0
}
