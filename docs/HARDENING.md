# Hardening runbook

Apply after every setup, upgrade, or exposure change (LAN/Tailscale/public).

## One command

```bash
./harden.sh
```

Writes `~/.local/share/open-webui/secrets.env` (600) and `local-agent.env` (600), re-applies Ollama localhost bind, runs `./tests/run-all.sh`.

## Defaults (secure baseline)

| Control | Default | Override |
|---------|---------|----------|
| Open WebUI bind | `127.0.0.1` | `ALLOW_LAN=1` + `BIND_HOST=0.0.0.0` |
| Ollama bind | `127.0.0.1:11434` | `ALLOW_LAN=1` → `0.0.0.0:11434` |
| Auth | `WEBUI_AUTH=true` | never disable on exposed hosts |
| Signup | `ENABLE_SIGNUP=false` | first admin only via initial signup window |
| Community sharing | `false` | |
| Session crypto | persistent `WEBUI_SECRET_KEY` | auto-generated once |
| HTTP redirects (SSRF) | `AIOHTTP_CLIENT_SESSION_REDIRECT=false` | Open WebUI ≥ 0.9.6 |
| Git updates | ff-only, dirty tree blocked | `UPDATE_ALLOW_DIRTY=1` |

## Tailscale / LAN

1. Set in `.env`: `ALLOW_LAN=1`, `BIND_HOST=0.0.0.0`
2. Re-run `./setup-m5-ollama.sh --harden-only` and `./setup-open-webui-native.sh --harden-only`
3. macOS Firewall: allow only Tailscale interface or block WAN to `${WEBUI_PORT}`
4. Keep signup disabled; use strong admin password

## Lethal trifecta (web + RAG + egress)

If all three are on, you are in **high-impact** territory (playbook). Mitigations:

- Disable unused Open WebUI tools, pipelines, and outbound integrations
- Do not expose port to the public internet
- Treat search/RAG as **T3** — never promote to system memory without review
- Run `./kill-switch.sh` monthly as a drill

## Open WebUI admin checklist

After first login:

- [ ] Confirm only one admin account
- [ ] Web Search: enable only if needed; prefer local SearXNG for control
- [ ] Disable code interpreter / external tool servers until sandboxed in your fork
- [ ] Review Admin → Settings → Documents / RAG scope
- [ ] No API keys in chat or system prompts

## Supply chain

- `pipx upgrade open-webui` after reading release notes
- `./update.sh` for this repo only — verify remote is `drich-22/local-agent`
- Never run `legacy/hermes` curl installers on production M5

## Kill switch

```bash
./kill-switch.sh           # stop WebUI
STOP_OLLAMA=1 ./kill-switch.sh   # also stop Ollama
```

Verify WebUI no longer responds on `http://127.0.0.1:${WEBUI_PORT}/`.
