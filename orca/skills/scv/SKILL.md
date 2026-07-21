---
name: scv
description: >
  Run the user-defined Orca orchestration mode pack "scv" (supervised feature
  shipping harness). Trigger when user says /scv, scv, scv-harness, or asks to
  run the scv plan→implement→review→release pipeline.
  Coordinator=OpenCode Go GLM-5.2. Cross-review: plan Claude write / Codex review; code Codex
  write / Claude review. Loads $HOME/.orca/scv/PLAYBOOK.md and meta.json.
  Use orchestration skill for all orca orchestration commands.
---

# scv mode

User-owned Orca mode pack for **feature shipping** (plan → implement → quality gate → code-review → release → **audit → reclaim** → FINAL).

**행동 계약 SSOT = `$HOME/.orca/scv/PLAYBOOK.md`.**  
**표시 연출 SSOT = `$HOME/.orca/scv/UX.md`.**  
**Engine = `orchestration` skill** (`worker_done` structured flags only).  
Live hard list = `LESSONS.md`. Config = `meta.json` (`packVersion` **1.3.10**).

| Role | Path |
|------|------|
| Install root | `$HOME/.orca/scv/` |
| PLAYBOOK (behavior) | `$HOME/.orca/scv/PLAYBOOK.md` |
| UX (display) | `$HOME/.orca/scv/UX.md` |
| meta | `$HOME/.orca/scv/meta.json` |
| templates | `$HOME/.orca/scv/templates/` |
| quick-command | `$HOME/.orca/scv/prompts/quick-command.txt` |
| LESSONS | `$HOME/.orca/scv/LESSONS.md` |
| self-check | `$HOME/.orca/scv/scv-selfcheck.sh` |
| Canonical SKILL | `$HOME/.orca/scv/SKILL.md` |
| OpenCode mirror | `$HOME/.config/opencode/skills/scv/SKILL.md` (byte-identical) |
| Source tree | `$HOME/Desktop/project/jb/skills/orca/skills/scv/` |

## 사용자 대면 · 문서 언어

- 진행·질문·FINAL = **한국어**. 상세 표 = **UX.md**.
- 채팅 한 줄: `**【계획 작성 】** "SCV good to go, sir." — … · 다음: 계획 검토` (bare `worker_done` 금지)
- 탭 / `--display-name` 한글 · `--task-title` `[scv:$RUN_ID] 한글 · slug`
- wait description: `계획 작성 완료 대기` · `(worker_done)`/`Rolling wait…` 금지
- 엔진 타입 UI 치환: `worker_done`→작업 완료(대기) · `heartbeat`→생존 신호 (CLI 타입명은 유지)
- docs 프로즈 기본 **ko** (`resolvedDocsLanguage`). finding P0 아님.
- **Human decision gate = AskUser 1회** (plan 승인·범위 확장·P0/P1·push·reclaim…). 본문 선택지 재질문 금지. bare seed는 free-text 1회.

## worker_done (엔진 · 필수)

Structured flags only — see orchestration skill. Spec **top** must include LIFECYCLE block (PLAYBOOK).

```bash
orca orchestration send --to <coord> --type worker_done \
  --subject "…" --body "…" \
  --task-id <task_> --dispatch-id <ctx_> \
  --files-modified "a,b" --json
# NEVER --payload together with --task-id / --dispatch-id / …
```

## Intake (prompt-first)

1. 사용자 메시지에서 seed 추출 (트리거 제외).
2. seed 있음 → 요약 후 모호성만. **추정 옵션 메뉴 선제 금지.**
3. bare `/scv` → 자유 서술 1회. orphan RUN_ID 금지.
4. **non-empty seed 후** RUN_ID · state · brief.
5. Goal·범위 확정 직후 **로드맵 초안** 작성(`brief/roadmap.md`) — 수행 작업 요약 + 수정 영역 후보(파일 경로 목록, quick file-list only). JSX/구조 심층 분석 금지(plan 워커 역할). 이 초안을 plan 워커 handoff 로 전달.

## When invoked

1. Read PLAYBOOK, UX, meta, LESSONS (hard list). Optional `scv-selfcheck.sh`.
2. Overlay `.orca/scv.md` / `AGENTS.md`.
3. orchestration skill (single wait owner, JSON-sequence parse, wait·liveness fusion, **structured worker_done**).
4. `orca status --json` · this-run ids only · peer soft-warn.
5. Prompt-first intake → Goal/brief.
6. Pipeline (**steps fixed**):

```text
preflight → seed/interview → (init?) → Claude plan
  → Codex↔Claude plan review ≤2 → user approve
  → Codex implement → quality gate
  → Claude code-review ↔ Codex fix ≤3
  → release 7a/7b
  → AUDIT (**fresh** Claude∥Codex · inventory only · time/stability · no evolution)
  → RECLAIM (createdByRun only)
  → CLOSING → closed → FINAL
```

### Cross-review (fixed)

| Phase | Write | Review |
|-------|-------|--------|
| plan | Claude | Codex |
| code | Codex | Claude |

### Session reuse (pack 1.3.7)

| | |
|--|--|
| **Resume** | same role + same phase loop (round 2+) only |
| **Fresh** | cross-role · cross-phase · Audit · hang recovery |
| **Close** | phase-end default when role loop terminal |
| **Handoff** | file only (`templates/handoff.md`) — not transcript |
| **Forbid** | idle-pick · command-compatible warm · far warm pool |

### Hard rules (summary — details in PLAYBOOK)

| Rule | Value |
|------|--------|
| Workers | exact `meta.json` · **7 roles** |
| RPC ids | `result.task.id` / `result.dispatch.id` / create `result.terminal.handle` / split `result.split.handle` · never root `id` |
| Wait | one `check --wait` · types=`worker_done,escalation,decision_gate` · never heartbeat |
| worker_done | structured flags only · LIFECYCLE in every `--spec` · success once |
| Hang | max 1 per role×task · never re-inject stuck pane |
| Session | same-role loop resume only · phase-end close · Audit always fresh |
| Close | **AUDIT → RECLAIM → CLOSING → FINAL** |
| Staging | never `git add -A` · never `.scv/**` |
| task-create | `--task-title` + `--display-name`(한글) + `--spec` |
| Human gate | **AskUser 1회** · prose re-ask 금지 · intake empty = free-text |

- Rolling wait **90000ms**; `waitTimeoutMs` **900000** = overall budget guide.

### FINAL (한글 8절)

요약 · 단계별 결과 · 결정 · 변경 파일 · 게이트 · Git/릴리스 · Docs · 위험/다음 단계.

## Worker commands (keep in sync with meta)

| role | command |
|------|---------|
| init | `opencode -m opencode-go/glm-5.2 --auto` |
| plan | `claude --model opus --dangerously-skip-permissions` |
| plan-review | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` |
| implement | `codex -m gpt-5.6-luna -c model_reasoning_effort="xhigh" -a never -s danger-full-access` |
| code-review | `claude --model opus --dangerously-skip-permissions` |
| review-fix | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| release | `opencode -m opencode-go/glm-5.2 --auto` |

## Anti-patterns (see PLAYBOOK)

- Premature option menu; orphan RUN_ID; parallel wait; `reset --all`
- `--payload` + structured flags together; second worker_done after success
- Whole-buffer wait parse; root RPC `id` as taskId; re-inject stuck pane
- Audit as evolution; `git add -A`; same-batch implement∥code-review
- Cross-role/cross-phase session reuse; idle-pick for Audit; plan pane as code-review
