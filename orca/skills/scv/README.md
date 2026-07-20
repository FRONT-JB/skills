# scv mode pack

Supervised feature-shipping harness for Orca.

| Item | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.2**) |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| Grok skill mirror | `$HOME/.grok/skills/scv/SKILL.md` |
| Source tree | `$HOME/Desktop/jb/skills/orca/skills/scv/` |
| Pack doc | `$HOME/Desktop/jb/skills/orca/orchestration/scv-orchestration-pack.md` |

**Triggers:** `scv`, `/scv`, `scv-harness`

**Coordinator:** Grok  

**Pipeline:** preflight → (init?) → plan → plan-review → implement → gate → code-review → release → **AUDIT → RECLAIM → CLOSING → FINAL**

**1.3.2:** mid-run soft reclaim (opt-in, default keep, evidence escrow, two-phase commit, no `--tab`) + 1.3.1 coordination/speed hygiene

See PLAYBOOK.md §8b. Run `./scv-selfcheck.sh` after edits.

## Install / sync

```bash
rsync -a --delete \
  "$HOME/Desktop/jb/skills/orca/skills/scv/" \
  "$HOME/.orca/scv/"
mkdir -p "$HOME/.grok/skills/scv"
cp "$HOME/.orca/scv/SKILL.md" "$HOME/.grok/skills/scv/SKILL.md"
"$HOME/.orca/scv/scv-selfcheck.sh"
```
