# letsgo (lets-go) Orca mode pack

Installed orchestration mode for code-understanding explainers.

| File | Role |
|------|------|
| `PLAYBOOK.md` | Full coordinator + worker rules (**authoritative**) |
| `meta.json` | Worker commands, dual-verify flags, hang caps |
| `LESSONS.md` | Session learnings — skim every run |
| `DESIGN.md` | **Revolut** HTML design tokens ([source](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/revolut/DESIGN.md)) |
| `templates/explainer.shell.html` | Design worker shell (CSS + landmarks + SLOT markers) |
| `templates/README.md` | Template usage |
| `prompts/quick-command.txt` | Orca Quick Command text |

**Pipeline:** research (Codex) → **dual verify Claude∥Codex** → docs → design/html (shell + DESIGN) → review → human → FINAL (Korean).

**Design flow:** copy shell → fill slots from `explainer.md` → do **not** rewrite `<style>`.

Invoke via Grok skill `/letsgo` or Orca Quick Command **lets-go**.

After edit, keep `$HOME/.grok/skills/letsgo/SKILL.md` in sync with the install root.

## Path policy (public package)

This folder is the **shared** skill package. Paths must stay portable:

| OK | Not OK |
|----|--------|
| `$HOME/.orca/letsgo/...` | `<absolute-home>/.orca/...` |
| `$HOME/Desktop/letsgo/<branch>/` | hard-coded home absolute paths |
| `skills/orca/skills/letsgo/` (repo-relative) | hard-coded monorepo absolute paths |

When mirroring from a local install, rewrite absolute paths before commit.
