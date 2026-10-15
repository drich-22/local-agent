# Hermes always-on (M5 + local Ollama)

Open WebUI = chat UI. **Hermes gateway** = the process that keeps running, fires cron jobs, and can talk to Telegram/Discord/etc. if you enable them.

The TUI (`hermes --tui`) is **not** always-on — it dies with the terminal.

## Three ways to “never stop”

| Mode | Survives terminal close? | Survives reboot? | Use for |
|------|-------------------------|------------------|---------|
| **`hermes gateway`** + LaunchAgent | Yes | Yes (if KeepAlive) | Cron, messaging bridges, background sessions |
| **`/loop` or `/goal` in TUI** | No | No | Interactive “keep going” while you watch |
| **Hermes cron jobs** | Yes (if gateway/cron daemon running) | Yes | “Every 10m check X”, nightly reports |

Official docs: [Recurring Loops](https://hermes-agent.nousresearch.com/docs/user-guide/features/loops), [Hermes Agent repo](https://github.com/NousResearch/Hermes-Agent).

## Recommended M5 stack

```
LaunchAgent: com.localagent.ollama          (already from setup-m5-ollama.sh)
LaunchAgent: com.localagent.hermes-gateway  (this folder)
Open WebUI                                  (optional chat UI — ./start.sh)
```

## Install (once)

```bash
# Hermes binary + ~/.hermes/.env (local Ollama)
LEGACY_HERMES=1 ./legacy/hermes/configure-hermes-local.sh

# Always-on gateway
./hermes-daemon/install-launchagent.sh
./hermes-daemon/status.sh
```

## Define work that runs forever

**Inside a TUI session** (one-time setup):

1. Start TUI: `LEGACY_HERMES=1 ./legacy/hermes/run-hermes.sh`
2. Create schedules in natural language, e.g. “Create a cron job every 15 minutes to …”
3. Or use `/loop 5m` for session polling, `/goal` for “until done”
4. Verify: `hermes cron status` (with gateway running)

Cron jobs persist on disk; **gateway must stay up** for them to fire (or use `hermes cron daemon` on newer builds if gateway is off).

## Speed (why it felt slow last week)

| Knob | Suggestion |
|------|------------|
| Model | Use `qwen2.5-coder:7b` for tight cron loops; reserve `qwen3.6-hermes` for hard tasks |
| Context | Daemon jobs: `OLLAMA_CONTEXT_LENGTH=8192`–16384, not 32k |
| Warmth | Gateway install script pre-warms; avoid cold `ollama run` on every tick |
| Parallelism | One gateway; don’t run TUI + heavy Open WebUI chat on same 27B at once |

Switch model: `LEGACY_HERMES=1 ./legacy/hermes/switch-hermes-model.sh fast`

## Security (24/7 = high agency)

Always-on agents hit **LLM06 excessive agency** fast. Minimum:

- Run gateway bound to localhost; no public ingress
- Kill switch: `./kill-switch.sh` + stop Hermes LaunchAgent
- Narrow cron prompts (read-only vs write paths)
- No broad web + private repo + outbound hooks without playbook review (`docs/SECURITY.md`)
- Cap cost: cron interval floors, `--times` on `/loop`, remove jobs when done

## Operations

```bash
./hermes-daemon/status.sh
./hermes-daemon/stop-gateway.sh
./hermes-daemon/start-gateway.sh
tail -f ~/.local/share/hermes-gateway/gateway.log
```

Stop everything: `STOP_HERMES=1` in `kill-switch.sh` (see root `kill-switch.sh`).
