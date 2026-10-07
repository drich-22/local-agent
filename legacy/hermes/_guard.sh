#!/usr/bin/env bash
if [[ "${LEGACY_HERMES:-0}" != "1" ]]; then
  echo "ERROR: Hermes scripts are deprecated (supply-chain + performance)."
  echo "Use: ./install.sh  (Ollama + Open WebUI native)"
  echo "To run anyway: LEGACY_HERMES=1 $0"
  exit 1
fi
