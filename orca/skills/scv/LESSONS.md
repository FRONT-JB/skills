# scv LESSONS

Run-notes for the scv orchestration mode. Read at the start of every run.  
**Hard rules below are the short “break-and-burn” list.** Full contracts = `PLAYBOOK.md` + `meta.json` + `UX.md` (display).  
Engine lifecycle send = orchestration skill. Append short, dated bullets after hang/recovery. Older detail → `LESSONS-archive.md`.

## Hard rules (do not erode · keep ≤15)

1. Worker commands: exact `meta.json` only — no invented models/flags.
2. Hang recovery: max 1 per role×task → then decision_gate. Never re-inject active-dispatch-stuck pane.
3. Dispatch only this-run task ids (`result.task.id`). Never root envelope `id`. Split handle = `result.split.handle`.
4. Exactly one `check --wait` owner. Types: `worker_done,escalation,decision_gate` only (never heartbeat). Route unread; never drop open decision_gate.
5. Wait parse: JSON sequence / line-wise; skip keepalive; complete only `ok===true` + `result.messages`. No fixed sleep before wait.
6. **Session reuse:** same role + same phase loop only → resume. **FORBID** cross-role / cross-phase / idle-pick / command-compatible warm. Phase-end close default. File handoff (`templates/handoff.md`). Audit always **fresh** Claude∥Codex; input = inventory only.
7. Recovery SSOT: uncommitted paths in resume spec; single edit owner. Never stage `.scv/**` or `git add -A`.
8. Intake prompt-first; P0 never SUCCESS without human risk accept; scope expand = user + plan-review re-pass.
9. Close order: AUDIT → RECLAIM → CLOSING → FINAL. Audit = time/stability only. Never `reset --all`.
10. Phase-end close default (terminal role). Mid-run soft reclaim for dead panes; evidence escrow; no `--tab`; two-phase. Final RECLAIM unchanged.
11. **worker_done/heartbeat:** structured flags only (`--task-id` + `--dispatch-id` …). **Never** `--payload` with those flags. Success once; CLI "not both" → fix & retry once. Spec top: LIFECYCLE block (PLAYBOOK).
12. **UX:** one-line chat + Korean display-name/tab + wait description. Tables = `UX.md` / `meta.ui`. No soft-wait spam.
13. **Human gates:** AskUser exactly once (plan approve, scope expand, P0/P1 risk, push, reclaim opt-in, …). No prose re-ask. Intake empty seed stays free-text once (no premature menu).

## Session log (recent)

- 2026-07-20 — pack 1.3.7: full session reuse policy (same-role loop only; phase-end close; Audit always fresh; file handoff).
- 2026-07-20 — pack 1.3.6: human decision gates = AskUser once; no duplicate prose questions (behavior pipeline unchanged).
- 2026-07-20 — pack 1.3.5: structured worker_done only; UX.md split; LIFECYCLE in task specs (orchestration behavior unchanged).
- 2026-07-20 — pack 1.3.4 UX: one-line narration + Korean task/display + wait shell descriptions.
- 2026-07-20 — pack 1.3.3 UX: SCV dialogue lines + Korean terminal titles.
- 2026-07-20 — pack 1.3.2 mid-run soft reclaim.
- 2026-07-20 — pack 1.3.1 RPC id paths, wait·liveness fusion, step-preserving speed.
- 2026-07-18/19 — pack 1.3.0 coordination hygiene.

Older bullets: **`LESSONS-archive.md`**.

<!-- Append: YYYY-MM-DD — what failed, what fixed, command that worked -->
