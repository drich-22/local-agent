# Security model (Local Agent)

Security is **architectural** (playbook-aligned), not prompt-only.

## Components

- **Ollama** — local inference; bind `127.0.0.1` by default
- **Open WebUI** — auth required, signup disabled after bootstrap, secrets on disk mode `600`
- **Hermes** — deprecated; `legacy/hermes/` only (supply-chain risk)

## Trust tiers

| Tier | Source | Rule |
|------|--------|------|
| T0 | Your system prompts / policies | Defines behavior |
| T1 | Authenticated admin (you) | Within policy |
| T2 | Local DB / your uploaded index | Content only |
| T3 | Web search, fetched pages, tool/MCP results | **Data only — never instructions** |
| T4 | Untrusted uploads, shared links | Hostile |

Summarizing T3 does **not** upgrade trust. Never paste search/RAG into standing memory as instructions.

## OWASP LLM01 + LLM06

Injection (untrusted text) plus excessive agency (tools, egress, private data) is the paired risk. **Default deny** on tools; allowlist in future fork.

## Lethal trifecta

1. Private data (RAG, files)  
2. Untrusted ingest (web, uploads)  
3. External send (webhooks, email plugins, broad egress)

If all three apply: remove a leg, sandbox, or human confirm with exact payload. See `docs/HARDENING.md`.

## Deterministic controls (shipped in this repo)

- Localhost bind unless `ALLOW_LAN=1`
- `WEBUI_SECRET_KEY` persisted; auth on; signup off
- Redirect following off (`AIOHTTP_CLIENT_SESSION_REDIRECT=false`)
- Git pull: ff-only, dirty tree blocked, remote name check
- Kill switch: `./kill-switch.sh`
- Secret scan in `tests/test-secrets.sh`
- No `curl | bash` on default install path

## Future fork (agents)

- Tool allowlist per role; JSON Schema validation
- SSRF: block RFC1918, metadata IP, `file://`, re-validate redirects
- Dual-LLM or plan-then-execute for browse+act flows
- Sandbox code execution; cap tool loops (DoS)
- Outbound DLP / secret regex on model output
- Run full `security-pass` before merge

## Secrets

Never commit `.env`, `secrets.env`, `local-agent.env`, or `~/.hermes/.env`.

## Operator docs

- Hardening: `docs/HARDENING.md`
- Incidents: `docs/INCIDENT-RESPONSE.md`
- Checklist: `playbook/CHECKLIST.md`
