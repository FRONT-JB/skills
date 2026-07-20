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

**행동 계약 SSOT = `$HOME/.orca/scv/PLAYBOOK.md`.** Engine = `orchestration` skill.  
Live hard list = `LESSONS.md`. Config = `meta.json` (`packVersion` **1.3.3**).

| Role | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK (SSOT) | `$HOME/.orca/scv/PLAYBOOK.md` |
| meta | `$HOME/.orca/scv/meta.json` |
| templates | `$HOME/.orca/scv/templates/` |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| LESSONS | `$HOME/.orca/scv/LESSONS.md` |
| self-check | `$HOME/.orca/scv/scv-selfcheck.sh` |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| Grok mirror | `$HOME/.grok/skills/scv/SKILL.md` (byte-identical) |
| Source tree | `$HOME/Desktop/jb/skills/orca/skills/scv/` |

## 사용자 대면 · 문서 언어

- 진행·질문·FINAL = **한국어**. role/path/task id/CLI = 영문 허용. `scv_line` 인용만 영문 flavor.
- **진행 내레이션 (두 줄, `scv ·` 접두 금지, `【 `·` 】` 앞뒤 공백 1칸):**
  ```text
  【 계획 작성 】 "SCV good to go, sir."
  Claude가 plan.md 작성 중 — worker_done까지 대기합니다.
  ```
  phase 진입·dispatch·gate·blocked·FINAL 만. soft-wait/heartbeat 스팸 금지. 표 = PLAYBOOK.
- **터미널 타이틀 = 한글 고정** (`계획 작성`, `구현`, …). create `--title` / split 직후 `rename`. 표 = PLAYBOOK.
- 커밋 docs 프로즈 기본 **ko** (`resolvedDocsLanguage`). finding P0 아님.

## Intake (prompt-first)

1. 사용자 메시지에서 seed 추출 (트리거 제외).
2. seed 있음 → 요약 후 모호성만. **추정 옵션 메뉴 선제 금지.**
3. bare `/scv` → 자유 서술 1회. orphan RUN_ID 금지.
4. **non-empty seed 후** RUN_ID · state · brief → 워커 dispatch.

## When invoked

1. Read PLAYBOOK, meta, LESSONS (hard list). Optional `scv-selfcheck.sh`.
2. Overlay `.orca/scv.md` / `AGENTS.md`.
3. orchestration skill (single wait owner, JSON-sequence parse, wait·liveness fusion).
4. `orca status --json` · this-run ids only · peer soft-warn.
5. Prompt-first intake → Goal/brief.
6. Pipeline (**steps fixed**):

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

### Hard rules (summary — details in PLAYBOOK)

| Rule | Value |
|------|--------|
| Workers | exact `meta.json` · **7 roles** (no audit meta workers) |
| RPC ids | `result.task.id` / `result.dispatch.id` / create `result.terminal.handle` / split `result.split.handle` · never root `id` |
| Wait | one `check --wait` · types=`worker_done,escalation,decision_gate` · never heartbeat · route unread |
| Hang | max 1 per role×task · never re-inject stuck pane |
| Speed | step-preserving · next-role warm only · no review skip · no same-batch implement∥review |
| Close | **AUDIT → RECLAIM → CLOSING → FINAL** |
| Mid-run reclaim | opt-in · default keep · evidence escrow · no `--tab` (PLAYBOOK §8b) |
| Staging | never `git add -A` · never `.scv/**` |
| P0 | never SUCCESS without human risk accept |
| task-create | `--task-title` + `--spec` (not `--title`) · no `--model` on dispatch |

- Track `terminals[]` (`createdByRun`/`preExisting`), `tasksById[taskId].activeDispatchId`, `completedTaskIds[]`.
- Rolling wait **90000ms**; `waitTimeoutMs` **900000** = overall budget guide.

### FINAL (한글 8절)

요약 · 단계별 결과 · 결정 · 변경 파일 · 게이트 · Git/릴리스 · Docs · 위험/다음 단계 (audit·reclaim·handoff 포함).

## Worker commands (keep in sync with meta)

| role | command |
|------|---------|
| init | `grok -m grok-4.5 --reasoning-effort high` |
| plan | `claude --model opus --dangerously-skip-permissions` |
| plan-review | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| implement | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` |
| code-review | `claude --model opus --dangerously-skip-permissions` |
| review-fix | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| release | `grok -m grok-4.5 --reasoning-effort high` |

## Anti-patterns (see PLAYBOOK for full list)

- Premature option menu; orphan RUN_ID; parallel wait; `reset --all`
- Whole-buffer wait parse; root RPC `id` as taskId; wrong split handle
- Re-inject stuck pane; fixed sleep before wait; empty wait after worker_done
- Audit as evolution; mid-run reclaim as new phase; close `--tab` without escrow
- same-batch implement∥code-review; `git add -A`
