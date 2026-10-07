# Local Agent

Local-first AI stack for a 24GB Mac (M5 hub): **Ollama** for inference, **Open WebUI** for chat/voice/RAG/web search, and **Hermes Agent** for tool use and coding tasks.

Built to clone once, run on your machine, and **pull updates from GitHub** when you ship improvements from Cursor.

## What you get today

| Layer | Role | How you start it |
| --- | --- | --- |
| Ollama | Model server (Qwen, Hermes-tuned, vision) | LaunchAgent via `setup-m5-hermes.sh` |
| Open WebUI | ChatGPT-style UI, web search, docs, voice | `./setup-open-webui.sh` |
| Hermes | Agentic TUI (files, shell, tools) | `./run-hermes.sh` |

Recommended models (see scripts): `qwen3.6:27b`, `qwen3.6-hermes`, `qwen2.5-coder:7b`, `qwen2.5vl:7b`.

## Quick start (M5)

```bash
chmod +x *.sh
./setup-m5-hermes.sh      # Ollama + Hermes + models (first time)
./configure-hermes-local.sh # Re-config only (if already installed)
./setup-open-webui.sh     # Docker Open WebUI → http://localhost:3000
./run-hermes.sh           # Agent TUI
```

**Open WebUI (first visit):** create admin account → Settings → enable Web Search (DuckDuckGo/SearXNG), Audio, Documents as needed.

**Hermes:** uses `~/.hermes/.env` (written by setup scripts). Never commit that file.

## Updates from GitHub

After the initial clone:

```bash
./update.sh              # fetch, pull if behind, optional rebuild hooks
```

Schedule checks (macOS example):

```bash
crontab -e
# 0 2 * * * cd /path/to/local-agent && ./update.sh >> update.log 2>&1
```

`update.sh` only updates **this repo** (scripts and future custom code). Open WebUI container image updates separately: `docker pull ghcr.io/open-webui/open-webui:main` and recreate the container.

## Roadmap: custom agent UI (Open WebUI fork)

The long-term plan is a **your-repo fork** of [Open WebUI](https://github.com/open-webui/open-webui) (SvelteKit + FastAPI), not a greenfield React app:

- Keep upstream as `upstream` remote; your GitHub repo as `origin`
- Add agent orchestration, Primagery-branded UI, and API hooks (e.g. `/api/agents/execute`) on top of existing Ollama + search plumbing
- Local install remains: `git clone` → `./install.sh` (future) → Ollama on host, app in Docker or dev mode

Until that fork lives in this repo, use Open WebUI + Hermes as the split UI/agent pair.

## Scripts

| Script | Purpose |
| --- | --- |
| `setup-m5-hermes.sh` | Full M5 bootstrap: Homebrew, Ollama LaunchAgent, models, Hermes |
| `configure-hermes-local.sh` | Models + `~/.hermes/.env` only |
| `setup-open-webui.sh` | Run Open WebUI in Docker against host Ollama |
| `run-hermes.sh` | Start Hermes TUI against `qwen3.6-hermes` |
| `switch-hermes-model.sh` | Point Hermes at another Ollama model |
| `update.sh` | Pull latest from `origin/main` |

## Requirements

- macOS on Apple Silicon (24GB RAM target)
- Docker Desktop (Open WebUI)
- Network for model pulls and web search

## License

MIT (scripts in this repo). Open WebUI and Hermes follow their respective upstream licenses when you fork or install them.
