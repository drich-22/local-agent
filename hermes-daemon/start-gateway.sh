#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
launchctl kickstart -k "gui/$(id -u)/com.localagent.hermes-gateway" 2>/dev/null \
  || exec "${ROOT}/run-gateway.sh"
