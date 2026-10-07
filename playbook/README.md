# Local Agent security playbook

Audits in this repo align with the **Primagery agent security playbook** skill:

`~/.cursor/skills/agent-security-playbook/SKILL.md`

That skill is the source of truth for trust tiers, lethal trifecta, tool hardening, and red-team categories. This folder maps those controls to **what we can enforce in this repository and bootstrap scripts** before you ship a custom Open WebUI fork.

## Run the audit

```bash
./tests/run-all.sh
# or only playbook checks:
./tests/test-playbook-audit.sh
```

## Scope

| Playbook area | Local Agent enforcement |
|---------------|-------------------------|
| Secrets not in repo | `test-secrets.sh`, `.gitignore` |
| Supply chain | pinned install paths, no curl \| bash in default path |
| Web search = T3 | documented in `docs/SECURITY.md` |
| Tool allowlist / agency | Open WebUI settings + future fork |
| Lethal trifecta | checklist in audit script |

Full T4 deploy checklist (64 items) lives in upstream wolfie docs; run `security-pass` before any public agent with tools + egress.
