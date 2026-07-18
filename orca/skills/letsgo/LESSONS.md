# letsgo LESSONS

Session learnings for this mode. Coordinator **must skim before every run**.

## 2026-07-18 — M5 launcher run (previs main)

### What went wrong

1. **Claude model hang:** `claude --model claude-sonnet-5` often showed only spinner / no tools after inject. Alias `sonnet` responded. Meta was updated to `sonnet` + `--dangerously-skip-permissions`.
2. **Over-recovery:** Hung recovery spawned many Claude terminals for the same phase (verify×3, docs×2, design×3). Late `worker_done` floods confused the coordinator.
3. **Wrong-task dispatch:** Heuristic “pick any ready task with design in the title” selected residual PiLastDigit task `task_e93522d7c11f` instead of the run’s design task. **Never fuzzy-match task titles.**
4. **Missing dual-verify:** User intent was Claude∥Codex parallel verification of research notes; pack only had Claude. Now required dual-parallel.
5. **Parallel `check --wait`:** Backgrounded wait shells stole messages. Keep **one** wait owner; kill duplicates.
6. **Re-dispatch while dispatched:** Same `taskId` got multiple assignees. Forbidden.
7. **Silent Codex design fallback:** After Claude hang, Codex was assigned design without user OK. Pack now forbids this unless user confirms.
8. **Late worker_done on completed tasks:** Must ignore; do not reopen phase.

### What worked

- Goal gate when change range missing.
- `$OUT` under `~/Desktop/letsgo/<branch>/`.
- Codex research with `-a never -s danger-full-access` (Desktop write).
- Separate `claude-docs` vs `claude-html` terminals (conceptually correct).
- No app production source edits.
- M5 `explainer.html` (Revolut dark shell) is now the design template at
  `$HOME/.orca/letsgo/templates/explainer.shell.html` — copy shell, fill content only.

### 2026-07-18 — DESIGN + shell template

- DESIGN.md switched Vercel → **Revolut** (VoltAgent awesome-design-md).
- Design inputs are now **3**: `explainer.md` + DESIGN.md + shell HTML.
- Do not regenerate CSS; PLAYBOOK DoD is Revolut (no mesh gradient).

### Hard caps (enforce)

| Item | Cap |
|------|-----|
| hang retry / role / task | **1** then ask user |
| concurrent verify workers | **2** (claude + codex) |
| `check --wait` owners | **1** |
| invent models outside meta | **0** |
| dispatch without this-run task id | **0** |

### Residual runtime hygiene

Before starting a new letsgo run:

```bash
orca orchestration task-list --brief --json
# Note foreign ready/dispatched tasks — do not dispatch them.
# Only task-create → store ids → dispatch those ids.
```
