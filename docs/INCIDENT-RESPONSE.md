# Incident response (Local Agent)

Follow playbook: **Detect → Contain → Scope → Patch → Recover → Rotate → Post-mortem**.

## 1. Contain (immediate)

```bash
./kill-switch.sh
STOP_OLLAMA=1 ./kill-switch.sh   # if model exfil or runaway load suspected
```

Disconnect from Tailscale / block port on firewall if exposed.

## 2. Scope

- Logs: `~/.local/share/open-webui/open-webui-serve.log`, `~/.ollama/ollama-serve.err.log`
- Open WebUI admin audit (if enabled)
- Git: `git status` — no unauthorized local changes

## 3. Recover

- Rotate `~/.local/share/open-webui/secrets.env` (forces re-login; re-enter OAuth keys in UI)
- `pipx upgrade open-webui` if supply-chain suspected
- `./harden.sh && ./start.sh`

## 4. Post-mortem

Document: attack vector, which trifecta leg failed, control added, red-team test added to `tests/`.
