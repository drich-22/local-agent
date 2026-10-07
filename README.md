# Local Agent

Native **Ollama + Open WebUI** on a 24GB Mac (M5 hub): chat, web search, RAG, voice, vision — no Docker, no Hermes in the default path.

Clone from GitHub, run setup scripts, pull updates with `./update.sh`.

**Repo:** https://github.com/drich-22/local-agent

## Quick start (M5)

```bash
git clone https://github.com/drich-22/local-agent.git
cd local-agent
chmod +x *.sh tests/*.sh
./setup-m5-ollama.sh
./setup-open-webui-native.sh
./start.sh
```

Open **http://localhost:8080** → create admin → Settings → enable **Web Search**, **Documents**, **Audio** as needed.

Models (defaults): `local-chat` (alias), `qwen3.6:27b`, `qwen2.5-coder:7b`, optional `qwen2.5vl:7b`.

## Daily use

```bash
./start.sh          # Ollama + Open WebUI (background)
./stop.sh           # stop WebUI
./update.sh         # git pull from origin/main
```

Foreground WebUI: `FG=1 ./start.sh`

## Tests & playbook audit

```bash
./tests/run-all.sh
```

Includes shell syntax, secret scan, repo layout, **agent-security-playbook** alignment (`playbook/README.md`, `docs/SECURITY.md`), and live checks for Ollama/Open WebUI when running.

## Configuration

Copy `.env.example` → `.env` (local only, never commit).

| Variable | Default |
|----------|---------|
| `WEBUI_PORT` | 8080 |
| `OLLAMA_CONTEXT_LENGTH` | 16384 |
| `PRIMARY_MODEL` | qwen3.6:27b |

## Legacy

| Path | Notes |
|------|--------|
| `legacy/hermes/` | Old Hermes agent scripts (deprecated) |
| `setup-open-webui.sh` | Docker UI; use `USE_DOCKER=1` to force |

## Roadmap

Fork [Open WebUI](https://github.com/open-webui/open-webui) in-repo for custom agent orchestration and Primagery branding; keep Ollama on the host.

## License

MIT (this repo). Upstream Open WebUI / Ollama under their licenses.
