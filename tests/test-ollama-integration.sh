#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

echo "==> Ollama integration (live)"

if ! command -v curl &>/dev/null; then fail "curl missing"; summary; exit 1; fi

if ! curl -sf --max-time 3 "http://127.0.0.1:11434/api/tags" &>/dev/null; then
  skip "Ollama not running on :11434 (run ./setup-m5-ollama.sh on M5)"
  summary
  exit 0
fi

pass "Ollama /api/tags responds"

tags=$(curl -sf "http://127.0.0.1:11434/api/tags")
echo "$tags" | grep -q '"models"' && pass "tags JSON shape OK" || fail "unexpected tags JSON"

# Minimal generate (fast model if present)
MODEL=""
for m in qwen2.5-coder:7b local-chat qwen3.6:27b; do
  if echo "$tags" | grep -q "\"name\":\"${m}\""; then MODEL="$m"; break; fi
done

if [[ -z "$MODEL" ]]; then
  skip "no known model pulled — ollama pull qwen2.5-coder:7b"
else
  resp=$(curl -sf --max-time 120 "http://127.0.0.1:11434/api/generate" \
    -d "{\"model\":\"${MODEL}\",\"prompt\":\"Reply with exactly: pong\",\"stream\":false}")
  echo "$resp" | grep -qi 'pong' && pass "generate with ${MODEL}" || fail "generate failed for ${MODEL}"
fi

summary
