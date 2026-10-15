#!/usr/bin/env bash
launchctl bootout "gui/$(id -u)/com.localagent.hermes-gateway" 2>/dev/null || true
pkill -f "hermes gateway" 2>/dev/null || true
echo "Hermes gateway stopped"
