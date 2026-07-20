# scv mode pack

Supervised feature-shipping harness for Orca.

| Item | Path |
|------|------|
| **Source tree (repo SSOT)** | `$HOME/Desktop/jb/skills/orca/skills/scv/` |
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.6**) |
| UX (display) | `$HOME/.orca/scv/UX.md` |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| LESSONS | `$HOME/.orca/scv/LESSONS.md` (+ archive) |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| Grok skill mirror | `$HOME/.grok/skills/scv/SKILL.md` |
| Pack doc (pointer) | `$HOME/Desktop/jb/skills/orca/orchestration/scv-orchestration-pack.md` |

**Triggers:** `scv`, `/scv`, `scv-harness`  
**Coordinator:** Grok  

**Pipeline:** preflight → (init?) → plan → plan-review → implement → gate → code-review → release → **AUDIT → RECLAIM → CLOSING → FINAL**

**Behavior contracts:** PLAYBOOK (SSOT) · meta.json · LESSONS hard list.  
Tooling+docs slim does not change pipeline steps or worker roles (orchestration behavior unchanged).

## Install / sync

```bash
# from repo source tree
"$HOME/Desktop/jb/skills/orca/skills/scv/sync-from-source.sh"
# equivalent:
#   rsync -a --delete "$HOME/Desktop/jb/skills/orca/skills/scv/" "$HOME/.orca/scv/"
#   mkdir -p "$HOME/.grok/skills/scv"
#   cp "$HOME/.orca/scv/SKILL.md" "$HOME/.grok/skills/scv/SKILL.md"
#   "$HOME/.orca/scv/scv-selfcheck.sh"
```

Orca Quick Command UI: fully quit Orca, then:

```bash
"$HOME/.orca/scv/sync-quick-command-to-orca.sh"
```

## Self-check

```bash
"$HOME/.orca/scv/scv-selfcheck.sh"
```
