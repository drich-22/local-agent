# Local Agent pre-ship checklist (subset)

Synced with agent-security-playbook themes. Full skill: `~/.cursor/skills/agent-security-playbook/SKILL.md`.

- [ ] Secrets not in git (`.env`, tokens, `~/.hermes/.env`)
- [ ] Default install avoids `curl | bash` (Hermes quarantined in `legacy/`)
- [ ] Web search / RAG treated as **T3** (data only)
- [ ] Lethal trifecta reviewed if web + private docs + outbound enabled
- [ ] `update.sh` uses fast-forward only (no force push)
- [ ] Open WebUI auth enabled on any network-exposed host
- [ ] Tool routes (future fork): allowlist, SSRF block, sandbox execution
