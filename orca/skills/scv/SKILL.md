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
| meta | `$HOME/.orca/scv/meta.json` (`packVersion`) |
| templates | `$HOME/.orca/scv/templates/` |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| LESSONS | `$HOME/.orca/scv/LESSONS.md` |
| Source pack | `$HOME/Desktop/orchestration/scv-orchestration-pack.md` |

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

1. Read PLAYBOOK, meta, LESSONS.
2. Overlay `.orca/scv.md` / `AGENTS.md`.
3. orchestration skill (one wait owner, liveness, hung recovery).
4. `orca status --json` ready · residual tasks · **this-run ids only**.
5. **Prompt-first intake** (위) → Goal/brief.
6. Pipeline:

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
| Worker commands | exact `meta.json` only · **still 7 workers** (no audit meta roles) |
| Hang recovery | max 1 per role×task |
| Task selection | this-run ids only · `--task-title` + `--spec` |
| Wait | **exactly one** `check --wait` owner · types=`worker_done,escalation,decision_gate` only · **never** put `heartbeat` in wait types · consume 1 msg then act · drain unread if UI stacks · timeout=soft recheck not failure · waiter kill ≠ worker kill |
| Staging | never `git add -A` · never `.scv/**` |
| Scope expand | user + plan-review re-pass · no skip |
| Intake | prompt-first · no premature option menu |
| Audit | time/stability only · keep ops · 1 review each · ship orthogonal |
| Reclaim | after audit, before close · allowlist · never `reset --all` |
| Close order | **AUDIT → RECLAIM → CLOSING → FINAL** |
| P0 | never SUCCESS · human risk accept only |
| dispatch | no `--model` |

- Terminal: first `create`; later `split`+`rename`. Ping-pong: same handle re-dispatch.
- Track `terminals[]` with `createdByRun` / `preExisting` for reclaim.
- Codex terminal: `-a never -s danger-full-access`. `codex exec`: no `-a`.

### Audit artifacts

`.scv/state/$RUN_ID/audit/{inventory,claude,codex,improvements,reclaim-log}.md` (gitignore).

### FINAL (한글 8절)

요약 · 단계별 결과 · 결정 · 변경 파일 · 게이트 · Git/릴리스 · Docs · 위험/다음 단계(**audit·reclaim 상태 포함**).

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
- **Stacking Orchestration Messages on coordinator** (heartbeat in wait types, dual wait loops, unread not drained)
- Treating heartbeat as completion; re-reading stacked mail without advancing
- Audit as redesign/evolution; dedicated audit meta workers; audit ping-pong
- Audit fail → force BLOCKED ship status
- English-only user progress; plan-review skip; `git add -A`
