# Local Agent hardening checklist

Map to **agent-security-playbook** (+ subset of Section 5.6). Run `./tests/test-playbook-audit.sh` and `./tests/test-hardening.sh`.

## Pre-deploy (repo + host)

- [ ] `./harden.sh` passes
- [ ] `./kill-switch.sh` tested
- [ ] Ollama on `127.0.0.1` (or LAN plan documented)
- [ ] Open WebUI on `127.0.0.1` (or `ALLOW_LAN=1` + firewall)
- [ ] `WEBUI_AUTH=true`, `ENABLE_SIGNUP=false`
- [ ] `secrets.env` mode `600`, not in git
- [ ] No secrets in tracked files (`test-secrets.sh`)
- [ ] Default install avoids `curl | bash`
- [ ] `update.sh` ff-only; remote verified

## Runtime (Open WebUI)

- [ ] Single admin; strong password
- [ ] Web search / RAG understood as **T3**
- [ ] Unused tools, pipelines, outbound plugins disabled
- [ ] No production API keys in prompts or memory
- [ ] Redirect / fetch SSRF settings reviewed (see hardened env)

## Lethal trifecta

- [ ] Assessed: private data ∧ untrusted ingest ∧ external send
- [ ] At least one leg removed or sandboxed

## Agent fork (when shipped)

- [ ] Tool allowlist; no dynamic tools from T3
- [ ] Arg validation in code, not model
- [ ] SSRF blocklist on fetch tools
- [ ] Loop / cost caps
- [ ] Human confirm for irreversible actions
- [ ] Red-team battery updated in `tests/`

## Incident readiness

- [ ] `docs/INCIDENT-RESPONSE.md` read
- [ ] Log paths known
- [ ] Secret rotation path tested
