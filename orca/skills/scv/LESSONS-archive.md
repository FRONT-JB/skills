# scv LESSONS archive

Historical session notes. **Not required** at every run start — see `LESSONS.md` for the live hard list.  
Kept for audit trail and pack evolution evidence (time/stability only; not a redesign backlog).

## 2026-07-18

- Empty Goal after Quick Command caused repeated "Goal is empty / pipeline stops" messaging. Fix: empty Goal is normal intake; ask once what to ship; never error-loop on blank Goal.
- **Intake clarified (prompt-first):** do not lead with estimated multi-option AskUser menu. Prefer user message as seed; if bare `/scv`, one free-text ask. RUN_ID only after non-empty seed (no orphan state).
- Coordinator progress narrated in English. Fix: user-facing progress/questions/FINAL must be Korean. **Extended:** committed `docs/**` prose defaults to Korean (`resolvedDocsLanguage`); policy P1 not finding-P0.
- Workers opened as separate tabs. Fix: first create + subsequent `terminal split` + rename.
- Ping-pong sessions: one handle per role; round 2+ re-dispatch only.
- docs-only expanded into 16-file lint fix. Fix: baseline vs acceptance; no auto-expand; scope manifest + re-review on expand.
- Parallel / backgrounded `check --wait`. Fix: single owner; kill **waiter only**.
- Coordinator froze with stacked Orchestration Messages. Fix: wait types exclude heartbeat; consume 1 msg then act; drain unread; heartbeat≠completion; Korean one-line wait status.
- Late mail after SUCCESS. Fix: close rules + silent dedupe; never drop unresolved decision_gate.
- `task-create --title` invalid → `--task-title`.
- `codex exec … -a never` fails; interactive meta keeps `-a never`; exec uses `--dangerously-bypass-approvals-and-sandbox` without `-a`.
- **Post-run audit + reclaim:** after release, inventory + Claude/Codex (1 each) write time/stability improvements under `.scv/state/$RUN_ID/audit/`; then reclaim createdByRun terminals; then close + FINAL. Audit is **not** pack evolution. Order: AUDIT → RECLAIM → CLOSING → FINAL.

## 2026-07-18/19 — login-persist (pack 1.3.0)

1. `check --wait` NDJSON keepalive broke whole-buffer `json.loads` — **line-wise parse + skip `_keepalive`**.
2. Dual wait loops stole completions — **one wait owner; kill waiter only**.
3. Heartbeat stacked in UI — wait types never include heartbeat; **unread drain**.
4. Codex self-update → shell; re-inject hit **active-dispatch stuck Ready** — post-inject 45–90s liveness; **no re-inject into stuck pane**; fresh terminal + new dispatch.
5. Late worker_done/heartbeat after completed tasks — **dispatchId + completedTaskIds straggler drop**.
6. Duplicate plan terminals + dead pane recreate — **idempotent create**; one live handle.
7. Coordinator partial implement + resume dual ownership — resume task must list **uncommitted SSOT paths**; single edit owner.
8. Prefer `phaseEnteredAt` in run.json for next-run audit timing.

## 2026-07-20 — pack 1.3.1 (logic+speed, step-preserving)

1. task-create root UUID mistaken for task id → `result.task.id` only.
2. `terminal split` returns `result.split.handle` not `result.terminal.handle`.
3. init wait-1 keepalive+pretty mixed → whole-buffer parse miss → empty waits after complete — JSON-sequence parse + stop opening wait after consumed worker_done.
4. fixed sleep 55–60 before wait → wait·liveness fusion.
5. multi-run same branch confuses UI — peer soft-warn; task-list has no worktree.
6. untyped unread can consume other-run lifecycle/gates — route messages.
7. maxConcurrent=2 needs per-task activeDispatchId.
8. speed: no review skip / no same-batch implement∥review; warm next role only; handoff latency fields.

## 2026-07-20 — pack 1.3.2 mid-run soft reclaim

Dual Claude∥Codex review. Adopt opt-in in-phase reclaim with evidence escrow, two-phase commit, forbid `--tab`, plan-review hold until first implement gate, default keep, audit handle reserve. Reject early plan-review kill and pre-close mid_reclaimed mark.
