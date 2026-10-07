# Security model (Local Agent)

## Architecture

- **Ollama** — local inference only; no cloud LLM required.
- **Open WebUI** — chat, RAG, web search, optional tools (version-dependent).
- **No Hermes** in the default path (legacy scripts under `legacy/hermes/`).

## Trust tiers (runtime)

| Tier | Source | Rule |
|------|--------|------|
| T0 | Your system prompts / policies in Open WebUI | Defines behavior |
| T1 | You (authenticated admin) | Within policy |
| T3 | Web search results, fetched pages, uploaded docs | **Data only — never instructions** |

When web search is enabled, treat every snippet as T3. Do not paste search results into standing “memory” or custom system prompts without review.

## Lethal trifecta

Open WebUI with web search + documents + outbound network can approach:

1. Private data (RAG, local files)
2. Untrusted content (web, uploads)
3. External communication (if plugins/webhooks enabled)

**Mitigations:** disable unused outbound features, keep auth on (`WEBUI_AUTH`), run on Tailscale not public internet, egress allowlist at network layer if exposed.

## Secrets

- Never commit `.env`, `~/.hermes/.env`, or API keys.
- `CUSTOM_API_KEY=ollama` in legacy Hermes config is a placeholder, not a secret.

## Supply chain

- Prefer `brew`, `pipx`, and `git pull` over `curl | bash` for default install.
- Legacy Hermes installer used upstream curl script — deprecated.

## Before agentic fork ships

Run `./tests/test-playbook-audit.sh` and a full `security-pass` review on new tool routes (SSRF on fetch, shell execution sandbox, allowlisted tools only).
