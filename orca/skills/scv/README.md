# scv mode pack

Supervised feature-shipping harness for Orca.

| Item | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.0**) |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| Grok skill | `$HOME/.grok/skills/scv/SKILL.md` |
| Source pack | `$HOME/Desktop/orchestration/scv-orchestration-pack.md` |
| Engine skill | `$HOME/.agents/skills/orchestration/SKILL.md` |

**Triggers:** `scv`, `/scv`, `scv-harness`

**Coordinator:** Grok  

**Pipeline:** preflight → (init?) → plan interview → Claude plan → Codex↔Claude plan review → implement batches → gate → Claude code-review ↔ Codex fix → release → **AUDIT → RECLAIM → CLOSING → FINAL**

**1.3.0 hygiene:** NDJSON wait parse · straggler drop · Codex stuck recovery · terminal idempotent · recovery SSOT

See PLAYBOOK.md for full rules. Run `./scv-selfcheck.sh` after edits.
