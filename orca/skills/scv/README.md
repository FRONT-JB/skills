# scv mode pack

Supervised feature-shipping harness for Orca.

| Item | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.1**) |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| Grok skill mirror | `$HOME/.grok/skills/scv/SKILL.md` |
| Source tree | `$HOME/Desktop/jb/skills/orca/skills/scv/` |
| Pack doc | `$HOME/Desktop/jb/skills/orca/orchestration/scv-orchestration-pack.md` |
| Engine skill | orchestration skill (`orca orchestration …`) |

**Triggers:** `scv`, `/scv`, `scv-harness`

**Coordinator:** Grok  

**Pipeline:** preflight → (init?) → plan interview → Claude plan → Codex↔Claude plan review → implement batches → gate → Claude code-review ↔ Codex fix → release → **AUDIT → RECLAIM → CLOSING → FINAL**

**1.3.1:** RPC id verb paths · wait JSON-sequence parse · per-task dispatch · peer soft-warn · wait·liveness fusion · handoff latency · terminal next-role reuse · SKILL SSOT · run.json schema · step-preserving speed rules

See PLAYBOOK.md for full rules. Run `./scv-selfcheck.sh` after edits.

## Install / sync

```bash
# from source tree
rsync -a --delete \
  "$HOME/Desktop/jb/skills/orca/skills/scv/" \
  "$HOME/.orca/scv/"
cp "$HOME/.orca/scv/SKILL.md" "$HOME/.grok/skills/scv/SKILL.md"
"$HOME/.orca/scv/scv-selfcheck.sh"
```
