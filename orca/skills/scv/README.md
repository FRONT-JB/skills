# scv mode pack

Supervised feature-shipping harness for Orca.

| File | Role |
|------|------|
| `PLAYBOOK.md` | Full coordinator + worker rules (**authoritative**) |
| `meta.json` | Worker commands, hang caps, packVersion |
| `LESSONS.md` | Session learnings — skim every run |
| `prompts/quick-command.txt` | Orca Quick Command text |
| `templates/` | Plan / architecture Korean templates |
| `SKILL.md` | Grok skill entry (`/scv`) |

| Install path (runtime) | Role |
|------------------------|------|
| `$HOME/.orca/scv/` | Active install root |
| `$HOME/.grok/skills/scv/SKILL.md` | Grok skill mirror |
| `orca/orchestration/scv-orchestration-pack.md` | Single-file pack source (this repo) |

**Triggers:** `scv`, `/scv`, `scv-harness`

**Coordinator:** Grok  
**Pipeline:** preflight → seed/interview → Claude plan → Codex↔Claude plan review → implement → gate → Claude code-review ↔ Codex fix → release → **AUDIT → RECLAIM** → CLOSING → FINAL

See PLAYBOOK.md for full rules.

After edit, keep `$HOME/.orca/scv/` and `$HOME/.grok/skills/scv/SKILL.md` in sync with this package.

## Path policy (public package)

This folder is the **shared** skill package. Paths must stay portable:

| OK | Not OK |
|----|--------|
| `$HOME/.orca/scv/...` | hard-coded home absolute paths |
| `orca/skills/scv/` (repo-relative) | hard-coded monorepo absolute paths |

When mirroring from a local install, rewrite absolute paths before commit.
