---
name: scv
description: >
  Run the user-defined Orca orchestration mode pack "scv" (supervised feature
  shipping harness). Trigger when user says /scv, scv, scv-harness, or asks to
  run the scv plan→implement→review→release pipeline.
  Coordinator=Grok. Cross-review: plan Claude write / Codex review; code Codex
  write / Claude review. Loads $HOME/.orca/scv/PLAYBOOK.md and meta.json.
  Use orchestration skill for all orca orchestration commands.
---

# scv mode

User-owned Orca mode pack for **feature shipping** (plan → implement → quality gate → code-review → release → **audit → reclaim** → FINAL).

| Role | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK (SSOT) | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.2**) |
| templates | `$HOME/.orca/scv/templates/` |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| LESSONS | `$HOME/.orca/scv/LESSONS.md` |
| self-check | `$HOME/.orca/scv/scv-selfcheck.sh` |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| Grok mirror | `$HOME/.grok/skills/scv/SKILL.md` (keep byte-identical) |
| Source tree | `$HOME/Desktop/jb/skills/orca/skills/scv/` |
| Source pack doc | `$HOME/Desktop/jb/skills/orca/orchestration/scv-orchestration-pack.md` |

Engine = `orchestration` skill. **행동 계약 SSOT = PLAYBOOK.**

## 사용자 대면 언어 (필수 · 한글)

진행·질문·FINAL = **한국어**. role/path/task id/CLI = 영문 허용.

## 문서 언어

기본 **ko** (`resolvedDocsLanguage`). finding P0 아님. Hangul 비율만으로 gate 금지.

## Intake (prompt-first)

1. 사용자 메시지에서 seed 추출 (트리거 문구 제외).
2. seed 있음 → 요약 후 모호성만 인터뷰. **추정 옵션 메뉴 선제 금지.**
3. bare `/scv` → 자유 서술 1회 또는 다음 메시지 대기. orphan RUN_ID 금지.
4. **non-empty seed 후** RUN_ID · state · brief → 그다음만 워커 dispatch.

## When invoked

1. Read PLAYBOOK, meta, LESSONS. Optional `scv-selfcheck.sh`.
2. Overlay `.orca/scv.md` / `AGENTS.md`.
3. orchestration skill (one wait owner, JSON-sequence parse, wait·liveness fusion, hung recovery).
4. `orca status --json` ready · residual tasks · **this-run ids only** · peer soft-warn.
5. **Prompt-first intake** (위) → Goal/brief.
6. Pipeline (steps unchanged):

```text
preflight → seed/interview → (init?) → Claude plan
  → Codex↔Claude plan review ≤2 → user approve
  → Codex implement → quality gate
  → Claude code-review ↔ Codex fix ≤3
  → release 7a/7b
  → AUDIT (inventory + Claude∥Codex time/stability · no evolution)
  → RECLAIM (createdByRun only)
  → CLOSING → closed → FINAL
```

### Cross-review (fixed)

| Phase | Write | Review |
|-------|-------|--------|
| plan | Claude | Codex |
| code | Codex | Claude |

### Hard rules

| Rule | Value |
|------|--------|
| Worker commands | exact `meta.json` only · **7 workers** (no audit meta roles) |
| Hang recovery | max 1 per role×task · **never re-inject active-dispatch-stuck pane** |
| Task selection | this-run ids only · `--task-title` + `--spec` |
| RPC ids | `result.task.id` / `result.dispatch.id` / create `result.terminal.handle` / split `result.split.handle` · **never root `id`** |
| Wait | **exactly one** `check --wait` · types=`worker_done,escalation,decision_gate` only · **never** heartbeat · consume 1 msg then act · drain **with routing** · timeout=soft · waiter kill ≠ worker kill |
| Wait parse | JSON sequence / line-wise; skip `_keepalive`/`_heartbeat`; complete only `ok===true` + `result.messages` array; no whole-buffer `json.loads` |
| Straggler | drop unless taskId this-run **and** dispatchId matches **per-task** active; completedTaskIds silent dedupe |
| Post-inject | **wait·liveness fusion** (no fixed sleep); inject-delta healthy≠done; Ready-no-tools ≥90s = hung; no early-hung |
| Terminal | first create then split+rename · **idempotent** reuse alive (title,role) · one live handle per role · **next role only** warm |
| Recovery SSOT | resume task lists uncommitted paths; **single edit owner** |
| Staging | never `git add -A` · never `.scv/**` |
| Scope expand | user + plan-review re-pass · no skip |
| Intake | prompt-first · no premature option menu |
| Audit | time/stability only · keep ops · 1 review each · prefer parallel · ship orthogonal |
| Reclaim | after audit, before close · allowlist · never `reset --all` |
| Close order | **AUDIT → RECLAIM → CLOSING → FINAL** |
| Speed | step-preserving; kill coord overhead only; no review skip; no same-batch implement∥review |
| Mid-run reclaim | opt-in in-phase only; default keep; exact createdByRun; evidence escrow; no `--tab`; two-phase commit; plan-review until first impl gate; keep audit Claude1+Codex1; final RECLAIM unchanged |
| P0 | never SUCCESS · human risk accept only |
| dispatch | no `--model` |

- Track `terminals[]` with `createdByRun` / `preExisting`; `tasksById[taskId].activeDispatchId`; `completedTaskIds[]`; `phaseEnteredAt`; handoff timestamps when possible.
- Codex terminal: `-a never -s danger-full-access`. `codex exec`: no `-a`.
- Rolling wait window **90000ms**; `meta.waitTimeoutMs` **900000** = overall budget guide (not one 15m block).

### Audit artifacts

`.scv/state/$RUN_ID/audit/{inventory,claude,codex,improvements,reclaim-log}.md` (gitignore).

### FINAL (한글 8절)

요약 · 단계별 결과 · 결정 · 변경 파일 · 게이트 · Git/릴리스 · Docs · 위험/다음 단계(**audit·reclaim·handoff 요약 포함**).

## Worker commands (meta — keep in sync)

| role | command |
|------|---------|
| init | `grok -m grok-4.5 --reasoning-effort high` |
| plan | `claude --model opus --dangerously-skip-permissions` |
| plan-review | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| implement | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` |
| code-review | `claude --model opus --dangerously-skip-permissions` |
| review-fix | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| release | `grok -m grok-4.5 --reasoning-effort high` |

## Anti-patterns

- Premature ship option menu; ignore seed prompt
- Empty Goal error-loop; orphan state on bare `/scv`
- Parallel wait; reset --all; fuzzy terminal close
- **Stacking Orchestration Messages** (heartbeat in wait types, dual wait, unread not routed)
- Whole-buffer parse of `check --wait`; treating keepalive as failure
- Root RPC `id` as taskId; wrong split handle path
- Re-inject into active-dispatch-stuck / Codex update-shell pane
- Treating heartbeat or late completed worker_done as current completion
- Fixed sleep 60 before wait; empty wait windows after consumed worker_done
- Dual edit owners on recovery (coordinator partial + resume without SSOT list)
- Audit as redesign/evolution; dedicated audit meta workers; audit ping-pong
- Audit fail → force BLOCKED ship status
- English-only user progress; plan-review skip; `git add -A`
- same-batch implement∥code-review; plan∥plan-review; maxConcurrent unlimited
- mid-run reclaim as new phase; plan-review kill right after approve; close `--tab`; escrow skip
