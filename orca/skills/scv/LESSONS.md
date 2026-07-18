# scv LESSONS

Run-notes for the scv orchestration mode. Read at the start of every run. Append short, dated bullets after hang/recovery or user corrections.

## Hard rules (do not erode)

- Worker commands: exact strings from `meta.json` only — no invented models/flags.
- Hang recovery: max 1 retry per role × task, then decision_gate.
- Dispatch only task ids created in **this** run (`task-create` response). No title fuzzy match.
- Late `worker_done` on already-completed tasks: ignore (silent dedupe after close).
- Exactly one `check --wait` owner loop. Recovering a backgrounded waiter kills **waiter only**, never worker/task.
- Wait types: `worker_done,escalation,decision_gate` only — **never** `heartbeat`/`status` in `--types`. Consume one message then act; drain unread if UI stacks. Heartbeat ≠ completion.
- **NDJSON wait parse:** line-wise JSON; skip `_keepalive`/`_heartbeat`; never `json.loads` whole stream.
- **Straggler filter:** accept lifecycle only for this-run taskId + active (or still-dispatched) dispatchId; drop stale/completed.
- **Post-inject liveness 45–90s mandatory.** Shell / update-success / Ready-no-tools = hung. Do **not** re-inject into active-dispatch-stuck pane — fresh terminal + new dispatch.
- **Terminal create idempotent:** reuse alive (title,role); one live handle per role after create.
- **Recovery SSOT:** uncommitted paths listed in resume task spec; single edit owner.
- Never stage or commit `.scv/**`.
- Gate invent forbidden; cmds frozen at plan approval (with scope manifest).
- P0 never becomes success; SUCCESS_WITH_ACCEPTED_RISK requires **human** decision_gate only.
- Plan body change after approve → Codex plan-review again (no user-skip of technical review).
- Scope expansion → user approve + plan patch + Codex re-review (no “minor skip”).
- Docs prose language: strong default **ko** (policy P1, not finding-P0). Override via `.orca/scv.md` `docsLanguage`.
- `task-create` uses `--task-title` + `--spec` (not `--title`).
- **Intake prompt-first:** consume user seed; no premature option menu; free-text once if empty; RUN_ID after non-empty seed.
- **Audit:** time/stability only; keep pipeline; no evolution; no dedicated meta workers; ship status orthogonal.
- **Close order:** AUDIT → RECLAIM → CLOSING → FINAL. Reclaim allowlist only; never `reset --all`.

## Session log

- 2026-07-18 — Empty Goal after Quick Command caused repeated "Goal is empty / pipeline stops" messaging. Fix: empty Goal is normal intake; ask once what to ship; never error-loop on blank Goal.
- 2026-07-18 — **Intake clarified (prompt-first):** do not lead with estimated multi-option AskUser menu. Prefer user message as seed; if bare `/scv`, one free-text ask. RUN_ID only after non-empty seed (no orphan state).
- 2026-07-18 — Coordinator progress narrated in English. Fix: user-facing progress/questions/FINAL must be Korean. **Extended:** committed `docs/**` prose defaults to Korean (`resolvedDocsLanguage`); policy P1 not finding-P0.
- 2026-07-18 — Workers opened as separate tabs. Fix: first create + subsequent `terminal split` + rename.
- 2026-07-18 — Ping-pong sessions: one handle per role; round 2+ re-dispatch only.
- 2026-07-18 — docs-only expanded into 16-file lint fix. Fix: baseline vs acceptance; no auto-expand; scope manifest + re-review on expand.
- 2026-07-18 — Parallel / backgrounded `check --wait`. Fix: single owner; kill **waiter only**.
- 2026-07-18 — Coordinator froze with stacked Orchestration Messages. Fix: wait types exclude heartbeat; consume 1 msg then act; drain unread; heartbeat≠completion; Korean one-line wait status.
- 2026-07-18 — Late mail after SUCCESS. Fix: close rules + silent dedupe; never drop unresolved decision_gate.
- 2026-07-18 — `task-create --title` invalid → `--task-title`.
- 2026-07-18 — `codex exec … -a never` fails; interactive meta keeps `-a never`; exec uses `--dangerously-bypass-approvals-and-sandbox` without `-a`.
- 2026-07-18 — **Post-run audit + reclaim:** after release, inventory + Claude/Codex (1 each) write time/stability improvements under `.scv/state/$RUN_ID/audit/`; then reclaim createdByRun terminals; then close + FINAL. Audit is **not** pack evolution. Order: AUDIT → RECLAIM → CLOSING → FINAL.
- 2026-07-18/19 — **login-persist run audit (pack 1.3.0):** (1) `check --wait` NDJSON keepalive broke whole-buffer `json.loads` — **line-wise parse + skip `_keepalive`**. (2) Dual wait loops stole completions — **one wait owner; kill waiter only**. (3) Heartbeat stacked in UI and confused operators — wait types never include heartbeat; **unread drain**. (4) Codex self-update → shell; re-inject hit **active-dispatch stuck Ready** — post-inject 45–90s liveness; **no re-inject into stuck pane**; fresh terminal + new dispatch; treat update/shell/Ready-no-tools as hung. (5) Late worker_done/heartbeat after completed tasks — **dispatchId + completedTaskIds straggler drop**; no re-open; no spam after FINAL. (6) Duplicate plan terminals + dead pane recreate — **idempotent create**; one live handle. (7) Coordinator partial implement + resume dual ownership — resume task must list **uncommitted SSOT paths**; single edit owner. (8) Prefer `phaseEnteredAt` in run.json for next-run audit timing.

<!-- Append: YYYY-MM-DD — what failed, what fixed, command that worked -->
