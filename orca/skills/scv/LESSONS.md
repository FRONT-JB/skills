# scv LESSONS

Run-notes for the scv orchestration mode. Read at the start of every run.  
**Hard rules below are the short “break-and-burn” list.** Full contracts = `PLAYBOOK.md` + `meta.json`.  
Append short, dated bullets after hang/recovery or user corrections. Older detail → `LESSONS-archive.md`.

## Hard rules (do not erode)

1. Worker commands: exact `meta.json` only — no invented models/flags.
2. Hang recovery: max 1 per role×task → then decision_gate. Never re-inject active-dispatch-stuck pane (fresh terminal + new dispatch).
3. Dispatch only this-run task ids (`result.task.id`). Never root envelope `id`. Split handle = `result.split.handle`.
4. Exactly one `check --wait` owner. Wait types: `worker_done,escalation,decision_gate` only (never heartbeat). Consume 1 msg then act; route unread; never drop open decision_gate.
5. Wait parse: JSON sequence / line-wise; skip keepalive; complete only `ok===true` + `result.messages`. No whole-buffer `json.loads`. No empty wait after consumed worker_done. No fixed sleep before wait (wait·liveness fusion).
6. Per-task `activeDispatchId` for straggler filter. Terminal create idempotent; one live handle per role; warm next role only.
7. Recovery SSOT: uncommitted paths in resume spec; single edit owner. Never stage `.scv/**` or `git add -A`.
8. Intake prompt-first; P0 never SUCCESS without human risk accept; scope expand = user + plan-review re-pass.
9. Close order: AUDIT → RECLAIM → CLOSING → FINAL. Audit = time/stability only (no evolution). Reclaim allowlist only; never `reset --all`.
10. Mid-run soft reclaim (1.3.2): opt-in in-phase only; default keep; evidence escrow; no `--tab`; two-phase commit. Final RECLAIM unchanged.
11. UX (1.3.4): 채팅 한 줄 `**【 한글 】** "scv_line" — 요약 · 다음: …`. display-name/탭 한글 필수. task-title=`[scv:…] 한글 · slug`. wait description=`계획 작성 완료 대기 (worker_done)` (`Rolling wait…` 금지). 표=PLAYBOOK.

## Session log (recent)

- 2026-07-20 — pack 1.3.4 UX: one-line narration + Korean task/display + wait shell descriptions.
- 2026-07-20 — pack 1.3.3 UX: SCV dialogue lines + Korean terminal titles (display-only; orchestration unchanged).
- 2026-07-20 — pack 1.3.2 mid-run soft reclaim (opt-in, default keep, escrow, no `--tab`).
- 2026-07-20 — pack 1.3.1 RPC id paths, JSON-sequence wait parse, wait·liveness fusion, per-task dispatch, step-preserving speed.
- 2026-07-18/19 — pack 1.3.0 coordination hygiene (NDJSON parse, straggler drop, Codex stuck recovery, terminal idempotent, recovery SSOT).
- 2026-07-18 — prompt-first intake; Korean user-facing; split panes; single wait owner; audit→reclaim order; `--task-title`.

Older bullets and full incident write-ups: **`LESSONS-archive.md`**.

<!-- Append: YYYY-MM-DD — what failed, what fixed, command that worked -->
