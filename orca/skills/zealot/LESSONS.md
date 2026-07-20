# zealot LESSONS

Run-notes for the zealot orchestration mode. Read at the start of every run.  
**Hard rules below are the short “break-and-burn” list.** Full contracts = `PLAYBOOK.md` + `meta.json` + `UX.md` (display).  
Engine lifecycle send = the dedicated vendored zealot-orchestration skill. Append short, dated bullets after hang/recovery.

## Hard rules (do not erode · keep ≤15)

1. Worker commands: exact `meta.json` only — no invented models/flags.
2. Hang recovery: max 1 per role×task → then decision_gate. Never re-inject active-dispatch-stuck pane.
3. Dispatch only this-run task ids (`result.task.id`). Never root envelope `id`. Split handle = `result.split.handle`.
4. Exactly one `check --wait` owner. Types: `worker_done,escalation,decision_gate` only (never heartbeat). Route unread; never drop open decision_gate.
5. Wait parse: JSON sequence / line-wise; skip keepalive; complete only `ok===true` + `result.messages`. No fixed sleep before wait.
6. **Session reuse:** same role + same phase loop only → resume. **FORBID** cross-role / cross-phase / idle-pick / command-compatible warm. Coordinator handle is never a worker handle. Phase-end close default. File handoff (`templates/handoff.md`). Audit always **fresh** Claude∥Codex; input = inventory only.
7. Recovery SSOT: uncommitted paths in resume spec; single edit owner. Never stage `.zealot/**` or `git add -A`.
8. Intake prompt-first; P0 never SUCCESS without human risk accept; scope expand = user + plan-review re-pass.
9. Close order: AUDIT → RECLAIM → CLOSING → FINAL. Audit = time/stability only. Never `reset --all`.
10. Phase-end close default (terminal role). Mid-run soft reclaim for dead panes; evidence escrow; no `--tab`; two-phase. Final RECLAIM unchanged.
11. **worker_done/heartbeat:** structured flags only (`--task-id` + `--dispatch-id` …). **Never** `--payload` with those flags. Success once; CLI "not both" → fix & retry once. Spec top: LIFECYCLE block (PLAYBOOK).
12. **UX:** one-line chat + Korean display-name/tab + wait description. Bracket = `【라벨 】`. User chat: never bare `worker_done`/`heartbeat` → `작업 완료 대기`/`생존 신호`. Tables = `UX.md` / `meta.ui`.
13. **Human gates:** AskUser exactly once (plan approve, scope expand, P0/P1 risk, push, reclaim opt-in, …). No prose re-ask. Intake empty seed stays free-text once (no premature menu).
14. **Trigger:** operative standalone `/zealot` only. Bare, substring, quote, fence, and URL occurrences never start a run.
15. **Gates:** use fixture `optionId`/`resultCode` exactly; unresolved means no dispatch.

## Session log (recent)

- 2026-07-20 — pack 1.0.0: resolved sibling snapshot from the 1.3.9 base contract; Claude coordinator, dedicated orchestration pin, Zealot UX, and isolated paths.
- 2026-07-20 — pack 1.3.8: UX bracket padding — `【대기 】` (space before 】 only; both-sides / open-only forbidden).
- 2026-07-20 — pack 1.3.7: full session reuse policy (same-role loop only; phase-end close; Audit always fresh; file handoff).
- 2026-07-20 — pack 1.3.6: human decision gates = AskUser once; no duplicate prose questions (behavior pipeline unchanged).
- 2026-07-20 — pack 1.3.5: structured worker_done only; UX.md split; LIFECYCLE in task specs (orchestration behavior unchanged).
- 2026-07-20 — pack 1.3.4 UX: one-line narration + Korean task/display + wait shell descriptions.
- 2026-07-20 — pack 1.3.3 UX: Zealot dialogue lines + Korean terminal titles.
- 2026-07-20 — pack 1.3.2 mid-run soft reclaim.
- 2026-07-20 — pack 1.3.1 RPC id paths, wait·liveness fusion, step-preserving speed.
- 2026-07-18/19 — pack 1.3.0 coordination hygiene.

<!-- Append: YYYY-MM-DD — what failed, what fixed, command that worked -->
