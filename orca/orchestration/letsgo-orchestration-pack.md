# letsgo 조율 모드 팩 (사용자 맞춤)

> Orca 조율 스튜디오에서 **이 사용자가 만든** 설정입니다.
> 원클릭 설치 파일이 아닙니다. 아래를 **설치 대상 머신**의 `$HOME/.orca/letsgo/` 와
> `$HOME/.grok/skills/letsgo/` 에 저장하세요.
>
> **버전:** 2026-07-18 (dual-verify + hang-cap + Revolut DESIGN + HTML shell template)
> **테마:** Geoffrey Litt — *Understanding is the new bottleneck* (인지 부채 · 참여를 위한 이해)  
> **최종 산출:** `$HOME/Desktop/letsgo/<branch>/explainer.html` (Revolut DESIGN.md + shell template)
>
> **Path policy (공용 문서):** `$HOME/...` 또는 **레포 상대경로**만 사용.  
> 절대 금지: 머신 홈 절대경로(`<absolute-home>/...`), 특정 monorepo 절대경로, 개인 Desktop 고정 경로.
>
> **정본 경로:**
> - 런타임 install: `$HOME/.orca/letsgo/`
> - Grok 스킬: `$HOME/.grok/skills/letsgo/SKILL.md`
> - 공용 패키지 (이 레포): `skills/orca/skills/letsgo/`
> - 이 팩 문서: `skills/orca/orchestration/letsgo-orchestration-pack.md`

---

## 이 팩 요약

| 항목 | 값 |
|------|-----|
| 표시 이름 | lets-go |
| 폴더 | `$HOME/.orca/letsgo/` |
| 팀장 | Grok |
| 조율 유형 | supervised |
| 실무 팀 | Codex/research + **Claude∥Codex dual-verify** + Claude/docs + Claude/design + Grok/review |
| 실무 목록 | **codex/research**: `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access`<br/>**claude/test-claude**: `claude --model sonnet --dangerously-skip-permissions`<br/>**codex/test-codex**: (research와 동일 Codex 커맨드)<br/>**claude/docs**: `claude --model sonnet --dangerously-skip-permissions`<br/>**claude/design**: `claude --model sonnet --dangerously-skip-permissions`<br/>**grok/review**: `grok -m grok-4.5 --reasoning-effort high` |
| 동시 | 3명 상한 · dual-verify 구간 **의도적 2** · 그 외 보통 1 |
| verify | `dual-parallel` · pass = **양쪽** P0+P1==0 |
| hang 재시도 | **role×task 당 1회** 후 사용자 확인 |
| 폴더 정책 | 상황에 맞게 자동 (변경 이해는 active 우선) |
| DESIGN | `$HOME/.orca/letsgo/DESIGN.md` (**Revolut**) |
| HTML 셸 | `$HOME/.orca/letsgo/templates/explainer.shell.html` |
| HTML 출력 | `$HOME/Desktop/letsgo/<branch>/explainer.html` |
| 폐기 모델 | `claude --model claude-sonnet-5` (hang) — 사용 금지 |

### 파이프라인

```text
research (Codex)
  → (parallel) test-claude ∥ test-codex
       ⇄ research fix          # maxRounds=3
  → merge verify-report.md     # BOTH P0+P1==0
  → docs (Claude) → design/html (Claude, separate terminal; **copy shell then fill**)
  → review gate (Grok) → human confirm → FINAL (Korean 6 sections)
```

### 산출물

```text
$HOME/Desktop/letsgo/<branch>/
  research-notes.md
  verify-claude.md
  verify-codex.md
  verify-report.md      # merge
  explainer.md
  explainer.html        # shell + content
  gate-report.md        # optional
```

---

## 설치 순서

1. `mkdir -p "$HOME/.orca/letsgo/prompts" "$HOME/.orca/letsgo/templates" "$HOME/Desktop/letsgo" "$HOME/.grok/skills/letsgo"`
2. 아래 **PLAYBOOK.md** → `$HOME/.orca/letsgo/PLAYBOOK.md`
3. 아래 **LESSONS.md** → `$HOME/.orca/letsgo/LESSONS.md`
4. 아래 **meta.json** → `$HOME/.orca/letsgo/meta.json`
5. 아래 **quick-command.txt** → `$HOME/.orca/letsgo/prompts/quick-command.txt`
6. 아래 **SKILL.md** → `$HOME/.grok/skills/letsgo/SKILL.md`
7. 공용 패키지가 있으면 한 번에 설치:
   ```bash
   # REPO = 이 monorepo 루트 (clone 위치 — 절대경로를 문서에 박지 말 것)
   REPO="${LETSGO_SKILLS_REPO:-$PWD}"
   rsync -a "$REPO/skills/orca/skills/letsgo/" "$HOME/.orca/letsgo/"
   cp "$REPO/skills/orca/skills/letsgo/SKILL.md" "$HOME/.grok/skills/letsgo/SKILL.md"
   ```
8. DESIGN.md (Revolut · 패키지에 없으면 curl):
   ```bash
   curl -fsSL "https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/revolut/DESIGN.md" \
     -o "$HOME/.orca/letsgo/DESIGN.md"
   ```
9. HTML 셸: `$HOME/.orca/letsgo/templates/explainer.shell.html` 존재 확인  
   (`skills/orca/skills/letsgo/templates/` 에서 복사됨)
10. (PC당 1회) orchestration / orca-cli 스킬 설치
11. Orca Quick Command: Label **lets-go**, Scope Global, Text = quick-command 전체
12. Experimental → Orchestration ON
13. **Grok** 탭에서 **lets-go** / `/letsgo` → Goal에 **변경 범위** 입력

### Design 워커 한 줄

```bash
cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
# SLOT + sections only from explainer.md — do not rewrite <style>
```

---

## quick-command.txt

```
letsgo mode (user mode). Read and follow $HOME/.orca/letsgo/PLAYBOOK.md, $HOME/.orca/letsgo/DESIGN.md, $HOME/.orca/letsgo/LESSONS.md, and the orchestration skill. If this project has .orca/letsgo.md or .orca/PLAYBOOK.md, also follow it as project overlay. You are Grok coordinator: supervised DAG for code-understanding (research → dual verify Claude∥Codex ↔ fix max3 → docs → design/html → review gate → human confirm → FINAL in Korean). Max concurrent: 3 (dual-verify uses 2). Coordination=supervised: inject lifecycle; single check --wait; hang retry max 1 per role; dispatch only this-run task ids. Workers: codex/research:{codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access} ; claude/test-claude:{claude --model sonnet --dangerously-skip-permissions} ; codex/test-codex:{codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access} ; claude/docs:{claude --model sonnet --dangerously-skip-permissions} ; claude/design:{claude --model sonnet --dangerously-skip-permissions} ; grok/review:{grok -m grok-4.5 --reasoning-effort high}. Output: $HOME/Desktop/letsgo/<branch>/explainer.html (+ verify-claude.md, verify-codex.md, verify-report.md). Goal must include change range (base..HEAD | PR | commits). Goal:
```

---

## meta.json

```json
{
  "modeName": "letsgo",
  "displayName": "lets-go",
  "coordination": "supervised",
  "coordinator": {
    "agent": "grok"
  },
  "maxConcurrent": 3,
  "worktreePolicy": "auto",
  "waitTimeoutMs": 900000,
  "verifyMaxRounds": 3,
  "verifyPass": "both:P0+P1==0",
  "verifyMode": "dual-parallel",
  "hangRetryMaxPerRole": 1,
  "taskTitlePrefix": "[letsgo:$RUN_ID]",
  "outputRoot": "$HOME/Desktop/letsgo/<branch>/",
  "designPath": "$HOME/.orca/letsgo/DESIGN.md",
  "htmlShellPath": "$HOME/.orca/letsgo/templates/explainer.shell.html",
  "htmlShellSample": "$HOME/Desktop/letsgo/<branch>/explainer.html",
  "finalSections": [
    "요약",
    "이해 (5축)",
    "파이프라인 결과",
    "퀴즈 커버리지",
    "HTML 경로",
    "잔여 리스크와 다음 질문"
  ],
  "triggers": [
    "lets-go",
    "letsgo",
    "/letsgo",
    "이해 리뷰",
    "explain-diff"
  ],
  "workers": [
    {
      "role": "research",
      "agent": "codex",
      "command": "codex -m gpt-5.6-sol -c model_reasoning_effort=\"xhigh\" -a never -s danger-full-access",
      "ownership": "edit"
    },
    {
      "role": "test-claude",
      "agent": "claude",
      "command": "claude --model sonnet --dangerously-skip-permissions",
      "ownership": "review-only",
      "output": "verify-claude.md"
    },
    {
      "role": "test-codex",
      "agent": "codex",
      "command": "codex -m gpt-5.6-sol -c model_reasoning_effort=\"xhigh\" -a never -s danger-full-access",
      "ownership": "review-only",
      "output": "verify-codex.md"
    },
    {
      "role": "docs",
      "agent": "claude",
      "command": "claude --model sonnet --dangerously-skip-permissions",
      "ownership": "edit"
    },
    {
      "role": "design",
      "agent": "claude",
      "command": "claude --model sonnet --dangerously-skip-permissions",
      "ownership": "edit"
    },
    {
      "role": "review",
      "agent": "grok",
      "command": "grok -m grok-4.5 --reasoning-effort high",
      "ownership": "review-only"
    }
  ],
  "notes": {
    "claudeModel": "Use alias sonnet (verified). Do not use claude-sonnet-5 — hung/no tools in 2026-07 session.",
    "dualVerify": "Spawn test-claude and test-codex in parallel after research. Both must PASS before docs.",
    "paths": "All paths use $HOME or repo-relative forms. Never commit absolute machine home paths."
  },
  "sourcePack": "skills/orca/orchestration/letsgo-orchestration-pack.md"
}
```

---

## LESSONS.md

```markdown
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
```

---

## PLAYBOOK.md

```markdown
# letsgo Orchestration Mode (Orca) — Global

Grok = **coordinator**. Workers = **Codex/research + Claude∥Codex dual-verify + Claude/docs + Claude/design + Grok/review**.  
When the pipeline finishes (and the human confirms quiz/understanding), the coordinator produces a **FINAL** synthesis **in Korean**.

Mode type: **supervised orchestration** (coordinator waits for `worker_done`). Not a fire-and-forget handoff.

- 엔진: orchestration 스킬 (`orca orchestration …`) — 효율·hung 복구·승인 UI 규칙 포함
- 이 파일: 그 엔진 위에 얹는 **MyMode 규칙** (Understanding-as-bottleneck / 인지 부채 방지)
- 홈 경로: `$HOME/.orca/letsgo/`
- DESIGN: `$HOME/.orca/letsgo/DESIGN.md` (Revolut · 필수)
- HTML 셸: `$HOME/.orca/letsgo/templates/explainer.shell.html` (design 정본 템플릿)
- LESSONS: `$HOME/.orca/letsgo/LESSONS.md` (**매 런 필독**)
- 스킬: `$HOME/.grok/skills/letsgo/SKILL.md`

---

## 언제 쓰나

사용자가 이렇게 말하면 이 파일을 따릅니다: `lets-go`, `letsgo`, `이해 리뷰`, `explain-diff`, `/letsgo`.

**목적:** 에이전트/인간이 만든 코드 변경을 **검증만이 아니라 참여(participate)** 할 수 있는 수준까지 이해한다.  
최종 공유 산출은 **단일 self-contained HTML** (`explainer.html`).

**Skip:** 단일 파일·자명한 변경(typo 등)은 사용자에게 스킵 가능 여부를 확인한 뒤, 동의하면 파이프라인을 돌리지 않는다.

---

## 시작 전 확인

```bash
orca status --json
orca orchestration task-list --brief --json   # 잔존 태스크 목록 — 건드리지 말 것
command -v grok || true
command -v codex || true
command -v claude || true
test -f "$HOME/.orca/letsgo/DESIGN.md"
test -f "$HOME/.orca/letsgo/templates/explainer.shell.html"
test -f "$HOME/.orca/letsgo/LESSONS.md"
mkdir -p "$HOME/Desktop/letsgo"
```

Orca 설정 → Experimental → Orchestration 이 켜져 있어야 합니다.  
기존 `ready`/`dispatched` 잔존 태스크가 있으면 **목록만 인지**하고, **이번 런 `task-create`로 받은 id만** dispatch 한다 (blind reset 금지 · **제목 퍼지 매칭 금지**).

### Goal 입력 계약 (필수)

| 필드 | 규칙 |
|------|------|
| **변경 범위** | 다음 중 **정확히 1**: `base..HEAD` (예: `main...HEAD`), PR URL, 커밋 SHA 범위 |
| **브랜치** | 자동: `git rev-parse --abbrev-ref HEAD` → sanitize (`/`→`-`, 실패·detached → `no-branch-YYYYMMDD`) |
| 선택 | 이해 깊이(core/full), 독자(본인/리뷰어/PM) |

Goal에 변경 범위가 없으면 **한 번만** 묻고 시작하지 않는다.

### 런 식별자 (필수)

```bash
RUN_ID=$(date +%Y%m%d-%H%M%S)
# 모든 task-create spec/title 앞에: [letsgo:$RUN_ID][role=…]
# dispatch 는 이번 런 create 응답의 task.id 만 사용
```

### 브랜치 sanitize 예

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
BRANCH=$(echo "$BRANCH" | tr '/' '-' | tr -cd 'a-zA-Z0-9._-')
[ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ] && BRANCH="no-branch-$(date +%Y%m%d)"
OUT="$HOME/Desktop/letsgo/$BRANCH"
mkdir -p "$OUT"
```

---

## 산출물 레이아웃 (프로젝트 무관 · 항상 Desktop)

```text
~/Desktop/letsgo/<branch>/
  research-notes.md    # research / fix
  verify-claude.md     # test-claude (review-only)
  verify-codex.md      # test-codex  (review-only)
  verify-report.md     # merge 요약 (양쪽 PASS 후)
  explainer.md         # docs (literate + 정적 퀴즈 섹션)
  explainer.html       # design (최종 · self-contained)
  gate-report.md       # review (optional)
```

- 앱 프로덕션 소스 수정 **금지** (이해 모드).
- 시크릿(API 키·토큰·.env)은 diff에 있어도 **마스킹** (`sk-•••`, `<redacted>`).
- HTML 본문 언어: **한국어** (코드·경로·식별자는 원문 유지).

---

## 역할

| 역할 | 에이전트 | 할 일 |
|------|----------|--------|
| **팀장** | Grok | DAG 분해, dispatch, **단일** wait, hung 복구(**역할당 1회**), dual-verify merge, 3회 실패 시 사용자 확인, 사람 최종 확인, **한글 FINAL** |
| **조사 (`research`)** | Codex<br/>`codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access`<br/>ownership: **edit (산출 노트만)** | 변경 범위·기존 구조·데이터/실행 흐름·불확실 목록 조사.<br/>**산출:** `$OUT/research-notes.md` |
| **검증 Claude (`test-claude`)** | Claude<br/>`claude --model sonnet --dangerously-skip-permissions`<br/>ownership: **review-only** | research 노트 사실성·환각·공백 검증. P0/P1.<br/>**산출:** `$OUT/verify-claude.md` 만 작성 (다른 파일 덮어쓰기 금지) |
| **검증 Codex (`test-codex`)** | Codex<br/>동일 codex 커맨드<br/>ownership: **review-only** (verify 파일만 쓰기) | **독립** 교차 검증 (Claude 결과 읽지 말 것 · 오염 방지).<br/>**산출:** `$OUT/verify-codex.md` 만 |
| **문서 (`docs`)** | Claude<br/>`claude --model sonnet --dangerously-skip-permissions`<br/>ownership: edit | literate explainer + **정적 퀴즈 5문항**.<br/>**산출:** `$OUT/explainer.md`<br/>**터미널:** `claude-docs` |
| **HTML (`design`)** | Claude<br/>`claude --model sonnet --dangerously-skip-permissions`<br/>ownership: edit | Revolut DESIGN + **shell 템플릿** 기반 self-contained HTML.<br/>**입력:** `explainer.md` + DESIGN.md + `templates/explainer.shell.html`<br/>**산출:** `$OUT/explainer.html`<br/>**터미널:** `claude-html` · hang 시 **1회만** 재시도 · **Grok/Codex HTML 대체 금지**(사용자 승인 없으면) |
| **이해 게이트 (`review`)** | Grok<br/>`grok -m grok-4.5 --reasoning-effort high`<br/>ownership: **review-only** | 이해 5축 · 퀴즈 · md↔html grounding. DESIGN 감리 안 함. |

**모델 규칙:** 모델은 worker `command`(meta) 에만. `dispatch` 에 `--model` 없음. hang 후 meta 밖 모델을 **발명하지 않음**.  
**조율 유형:** supervised (`task-create` + `dispatch --inject` + post-inject liveness + **단일** `check --wait`).

### 역할 키

- `research` — 조사·노트 (fix 포함)
- `test-claude` / `test-codex` — dual-verify (병렬)
- `docs` — literate markdown + 퀴즈
- `design` — HTML
- `review` — 이해 게이트

### 이해 5축 (gate · FINAL · verify 공통 프레임)

1. 왜 이 변경인가  
2. 데이터/실행 흐름  
3. 핵심 설계 선택 + 버린 대안  
4. 요구 변경 시 깨질 지점  
5. 장애 시 먼저 볼 곳  

verify 워커 spec에 위 5축을 **명시**한다 (저장소 grep 불필요).

### 퀴즈 “통과” 정의

- 퀴즈는 **정적 목록** (자동 채점 없음).
- **gate**가 커버리지·grounding 체크리스트를 통과시킨 뒤,
- **사람(사용자) 최종 확인**을 받아야 모드 완료로 본다.

---

## 파이프라인 (DAG)

```text
research
  → (parallel) test-claude ∥ test-codex
       ⇄ research(fix)     # maxRounds=3
  → merge verify-report.md   # pass = BOTH P0+P1 == 0
  → (3회 후에도 실패) → 중단 + 사용자 확인  # docs 금지
  → docs
  → design (html)
  → review (gate)
  → 사람 최종 확인
  → FINAL (한글 6항목)
```

### dual-verify / fix 계약

| 항목 | 값 |
|------|-----|
| 모드 | **병렬** Claude + Codex (동시 2) |
| 독립성 | Codex verify는 `verify-claude.md`를 **읽지 않음**. Claude도 역으로 Codex 결과 미사용. |
| pass | **양쪽** `P0 + P1 = 0` |
| fail | 한쪽이라도 FAIL → research fix (두 리포트 이슈 union) |
| maxRounds | **3** (research fix 라운드) |
| 3회 초과 | **중단** · 사용자 계속/중단 |
| fix scope | `research-notes.md` 등 research 산출만 |
| merge | 양쪽 PASS 후 팀장이 `verify-report.md` 요약 작성 (또는 짧은 merge 태스크). docs는 merge PASS 전 시작 금지 |
| 산출 충돌 | 각 워커는 **자기 파일만** 씀 (`verify-claude.md` / `verify-codex.md`) |

### docs → design 핸드오프

- design 입력 (3개):
  1. `$OUT/explainer.md`
  2. `$HOME/.orca/letsgo/DESIGN.md` (Revolut)
  3. `$HOME/.orca/letsgo/templates/explainer.shell.html` (**CSS·랜드마크 정본**)
- **권장 절차:**
  ```bash
  cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
  # 그다음 SLOT·sections·quiz만 explainer.md로 채움
  ```
- **`<style>` / `:root` 재작성 금지.** 기존 컴포넌트 클래스만 재사용.
- research/verify 원문을 HTML에서 재해석해 **새 기술 주장 추가 금지**
- 불일치 발견 시 md를 고치고 design 재실행
- 채워진 참고 샘플: `$HOME/Desktop/letsgo/<branch>/explainer.html` (구조 참고용 · 내용 복붙 금지)

### DESIGN self-check (design 워커 DoD · Revolut)

- [ ] `$HOME/.orca/letsgo/DESIGN.md` 필독 (Revolut)
- [ ] 셸을 복사한 뒤 SLOT/본문만 채움 (`<style>` 미재작성)
- [ ] `:root` 유지: `--canvas` `#000` · `--surface-elevated` · `--primary` cobalt `#494fdf` · `--on-dark` / `--on-dark-mute` · radius scale
- [ ] 밴드 교차: dark canvas storytelling ↔ `section white` catalogue (full-bleed 전환)
- [ ] display 계열 weight 500 전후 · 본문 Inter 400/600 · 코드/라벨 mono
- [ ] elevation = surface 휘도 차이 (drop-shadow **금지**)
- [ ] cobalt primary는 강조 스탬프(배지·featured·accent)에만 — 본문 배경색 남용 금지
- [ ] mesh gradient / Vercel Geist 라이트 룩 **사용 금지**
- [ ] self-contained (신규 외부 JS/CSS 추가 금지 · 기존 font link 유지 OK)
- [ ] 정적 퀴즈 섹션 (`details.quiz-item` · 자동 채점 없음 · 보통 5문항)
- [ ] 경로 `$HOME/Desktop/letsgo/<branch>/explainer.html`

gate는 DESIGN 감리 안 함. **이해·퀴즈·grounding만**.

---

## 팀장 하드 규칙 (2026-07 사고 반영)

### A) 태스크·디스패치 위생

1. `task-create` 응답의 **`task.id`를 런 로컬 변수에 저장**한다.
2. `dispatch --task` 인자 = 그 id **만**.  
   - 금지: `task-list`에서 제목에 "design"/"test" 포함 검색해 고르기  
   - 금지: 이전 goal의 `ready` 태스크 재사용
3. 모든 spec 접두사: `[letsgo:$RUN_ID][role=…]`
4. 태스크가 이미 `dispatched`/`completed` 이면 **재배정 금지** (hang 복구 예외는 아래 B).
5. `completed` 태스크에 대한 **late `worker_done` / heartbeat → 무시**. 페이즈를 되돌리지 않음.

### B) Hung 복구 (상한 엄격)

| 항목 | 규칙 |
|------|------|
| liveness | inject 후 45–90s: 도구 호출·파일 경로·의미 있는 출력 증가 |
| unhealthy | spinner-only / MCP only / no tools ≥90s |
| 복구 | `task-update --status ready` → **fresh terminal** → `dispatch --inject` **1회** |
| 상한 | **role × task 당 hang 재시도 1회** |
| 1회 실패 후 | **사용자에게 보고** (계속/중단/다른 모델). meta 밖 모델 발명 금지 |
| design | Claude 1회 재시도 후 실패 시 사용자 확인 전 **Codex/Grok HTML 금지** |
| capacity | Codex model capacity 메시지도 동일 상한 |

### C) Wait 소유권

```bash
# 단일 소유자만. 백그라운드에 이전 check --wait 가 있으면 종료 후 시작.
orca orchestration check --wait \
  --types worker_done,escalation,decision_gate \
  --timeout-ms 90000 --json
```

- dual-verify 중에는 **하나의 wait 루프**가 두 `worker_done`을 순서대로 수집 (병렬 wait 금지).
- timeout / count=0 = 체크포인트 (실패 아님). 터미널 liveness 확인 후 계속.

### D) 동시성

- `maxConcurrent=3` 상한.
- dual-verify 구간만 **의도적 동시 2** (test-claude + test-codex).
- 그 외 단계는 보통 **동시 1**.

---

## 팀장 루프

### 1) 일 쪼개기

```text
[letsgo:$RUN_ID][role=research] → research-notes.md
[letsgo:$RUN_ID][role=test-claude] → verify-claude.md   # deps: research
[letsgo:$RUN_ID][role=test-codex]  → verify-codex.md    # deps: research
# both PASS → merge verify-report.md (coordinator)
[letsgo:$RUN_ID][role=docs] → explainer.md
[letsgo:$RUN_ID][role=design] → explainer.html
[letsgo:$RUN_ID][role=review] → gate
```

research 완료 전에는 dual-verify 터미널을 **미리 띄우지 않음**. research `worker_done` 후 둘을 함께 create+dispatch.

### 2) 일 등록

```bash
orca orchestration task-create --spec "[letsgo:$RUN_ID][role=research] …" --json
# id 저장 → dispatch
# research done 후:
orca orchestration task-create --spec "[letsgo:$RUN_ID][role=test-claude] …" --json
orca orchestration task-create --spec "[letsgo:$RUN_ID][role=test-codex] …" --json
```

### 3) 실무 창 (meta 커맨드 그대로)

```bash
# research / fix
orca terminal create --worktree active --title "codex-research" \
  --command 'codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access' --json

# dual-verify (병렬, 별도 터미널)
orca terminal create --worktree active --title "claude-test" \
  --command 'claude --model sonnet --dangerously-skip-permissions' --json
orca terminal create --worktree active --title "codex-test" \
  --command 'codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access' --json

# docs
orca terminal create --worktree active --title "claude-docs" \
  --command 'claude --model sonnet --dangerously-skip-permissions' --json

# design — docs와 세션 공유 금지
orca terminal create --worktree active --title "claude-html" \
  --command 'claude --model sonnet --dangerously-skip-permissions' --json

# review
orca terminal create --worktree active --title "grok-review" \
  --command 'grok -m grok-4.5 --reasoning-effort high' --json
```

각 터미널: `wait --for tui-idle` → `dispatch --task <THIS_RUN_ID> --to <handle> --inject`.

### 4) 배정

```bash
orca orchestration dispatch --task <task_id_from_this_run> --to <handle> --inject --json
```

### 5) 기다리기

단일 rolling wait (60–90s 창 권장). dual-verify는 done 2개 수집 후 merge.

### 6) 사람 최종 확인

gate pass 후:

1. `explainer.html` 경로  
2. 정적 퀴즈 목록  
3. 이해 5축 요약  
4. dual-verify 요약 (양쪽 PASS 여부)

### 7) FINAL (한글 6항목)

1. 요약  
2. 이해 (5축)  
3. 파이프라인 결과 (research / dual-verify rounds / docs / html / gate)  
4. 퀴즈 커버리지  
5. HTML 경로  
6. 잔여 리스크와 다음 질문  

---

## 실무 의무 (역할 공통)

inject 후: 역할 범위 수행 → `worker_done` **딱 1번** → idle.

```json
{
  "taskId": "…",
  "dispatchId": "…",
  "role": "research|test-claude|test-codex|docs|design|review",
  "filesModified": [],
  "reportPath": "$HOME/Desktop/letsgo/<branch>/…"
}
```

- `test-*` / `review` worker_done ≠ edit 권한 (자기 리포트 파일 제외).
- `design` worker_done 전 DESIGN self-check 필수.
- dual-verify: **상대 verify 파일 읽기 금지**.

---

## 프로젝트 추가 규칙

저장소 `.orca/letsgo.md` / `.orca/PLAYBOOK.md` / `AGENTS.md` 가 있으면 함께 읽음.  
조율·파이프라인은 **전역 이 파일 우선**, 도메인/안전은 프로젝트 우선.

---

## Anti-patterns

- dual-verify 없이 / 한쪽만 PASS로 docs 진행
- verify 파일 하나에 두 워커가 덮어쓰기
- maxRounds 무시 무한 fix
- 앱 프로덕션 코드 수정
- docs와 html 같은 Claude 세션
- design이 md에 없는 기술 사실 추가
- dispatch에 `--model`
- hang 시 Grok/Codex에게 HTML 무단 위임
- 퀴즈 자동 채점 후 사람 확인 생략
- DESIGN.md 없이 HTML
- shell 템플릿 무시하고 `<style>` 전부 재작성
- Vercel mesh/라이트 토큰으로 Revolut 셸을 덮어쓰기
- 제목 퍼지로 잔존 태스크 dispatch
- completed 태스크 late done으로 페이즈 재오픈
- 역할당 hang 재시도 1회 초과
- 병렬 `check --wait`
- meta 밖 모델 문자열 발명 (`claude-sonnet-5` 등 폐기 ID 재사용 포함)

---

## 이론적 근거 (짧게)

- **이해 목적 = 검증 + 참여** (Geoffrey Litt)
- **인지 부채** 방지 · literate explainer · 퀴즈 · 공유 HTML
- **교차 검증 (Claude∥Codex)** 으로 단일 모델 환각·공백 완화

---

## meta 요약

`meta.json` 이 정본. 요지:

- `verifyMode`: `dual-parallel`
- `verifyPass`: `both:P0+P1==0`
- `hangRetryMaxPerRole`: `1`
- Claude: `claude --model sonnet --dangerously-skip-permissions`
- Codex research/test: `gpt-5.6-sol` xhigh, `-a never`, `-s danger-full-access`
```

---

## SKILL.md (Grok)

```markdown
---
name: letsgo
description: >
  Run the user-defined Orca orchestration mode pack "letsgo" (supervised).
  Trigger when user says /letsgo, letsgo, lets-go, 이해 리뷰, explain-diff,
  or wants code-understanding explainer HTML for a change range.
  Coordinator=Grok. Pipeline: Codex research → dual verify (Claude∥Codex)
  ↔ research fix (max 3) → Claude docs → Claude design/html
  (Revolut DESIGN.md + templates/explainer.shell.html)
  → Grok review gate → human confirm → FINAL in Korean.
  Loads $HOME/.orca/letsgo/PLAYBOOK.md.
---

# letsgo mode (lets-go)

User-owned Orca mode pack. Engine = `orchestration` skill. This skill loads the pack and runs the supervised loop.

**Source pack (repo-relative):** `skills/orca/orchestration/letsgo-orchestration-pack.md`  
**Install root:** `$HOME/.orca/letsgo/`  
**Grok runtime skill:** `$HOME/.grok/skills/letsgo/SKILL.md`  
**Public package (this folder):** `skills/orca/skills/letsgo/`

> Path policy: use `$HOME/...` or **repo-relative** paths only.  
> Never commit absolute machine paths (`<absolute-home>/...`).

### Skill file sync (mandatory)

Grok letsgo `SKILL.md` 를 수정하면 **아래를 모두 동일 내용으로 갱신**한다 (한쪽만 고치지 않음):

| 역할 | 경로 |
|------|------|
| Grok 런타임 | `$HOME/.grok/skills/letsgo/SKILL.md` |
| 공용 패키지 (폴더) | `skills/orca/skills/letsgo/` (레포 루트 기준) |
| 공용 패키지 (파일) | `skills/orca/skills/letsgo/SKILL.md` |

```bash
# REPO = 이 skills monorepo 루트 (환경마다 다름 — 절대경로 하드코딩 금지)
REPO="${LETSGO_SKILLS_REPO:-$PWD}"   # 또는 본인 clone 경로를 일시 지정

# 권장: 런타임 정본 수정 후 공용 패키지로
cp "$HOME/.grok/skills/letsgo/SKILL.md" \
   "$REPO/skills/orca/skills/letsgo/SKILL.md"
# install 산출 전체 미러 (경로 마스킹 후 — 아래 Portable install)
rsync -a --delete --exclude 'SKILL.md' \
  "$HOME/.orca/letsgo/" \
  "$REPO/skills/orca/skills/letsgo/"
cp "$HOME/.grok/skills/letsgo/SKILL.md" \
   "$REPO/skills/orca/skills/letsgo/SKILL.md"
# 미러 meta 경로가 $HOME 형태인지 확인 (절대 홈 디렉터리 절대경로 금지)
```

## When invoked (`/letsgo` or aliases)

1. Read **required**:
   - `$HOME/.orca/letsgo/PLAYBOOK.md`
   - `$HOME/.orca/letsgo/meta.json`
   - `$HOME/.orca/letsgo/DESIGN.md` (Revolut · must exist)
   - `$HOME/.orca/letsgo/templates/explainer.shell.html` (design shell · must exist)
   - skim `$HOME/.orca/letsgo/LESSONS.md` (**do this every run**)
2. If the current repo has `.orca/letsgo.md` or `.orca/PLAYBOOK.md`, also follow as overlay. Read `AGENTS.md` when present.
3. Follow engine skill `orchestration` for all `orca orchestration …` — including **Coordinator Efficiency**, **post-inject liveness**, **hung recovery**.
4. Confirm `orca status --json` (runtime ready). Experimental → Orchestration must be ON.
5. **Residual tasks:** list existing tasks. Never dispatch by fuzzy title match. Only use **task ids created in this run** (store from `task-create` response). Do not touch unrelated `ready`/`dispatched` work from prior goals.
6. **Goal gate:** require a **change range** (one of: `base..HEAD` / PR URL / commit range). If missing, ask once and do not start.
7. Resolve branch → `$OUT=$HOME/Desktop/letsgo/<sanitized-branch>/` (`mkdir -p`). Record `RUN_ID` (timestamp or uuid) and put it in every task title/spec prefix: `[letsgo:$RUN_ID]`.
8. Act as **Grok coordinator** (supervised DAG):

```text
research (Codex)
  → verify-claude ∥ verify-codex     # parallel; maxConcurrent uses 2 here
       ⇄ research fix                # maxRounds=3; pass = BOTH P0+P1==0
  → (fail after 3) stop + user confirm
  → docs (Claude) → design/html (Claude, separate terminal; copy shell then fill)
  → review gate (Grok) → human confirm → FINAL (Korean 6 sections)
```

### Design HTML (template)

```bash
cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
# design worker fills SLOTs + sections from explainer.md; do NOT rewrite <style>
```

Inputs: `explainer.md` + `DESIGN.md` (Revolut) + shell.  
Optional filled sample: `$HOME/Desktop/letsgo/<branch>/explainer.html` (구조 참고 · 내용 복붙 금지).

### Hard rules (from production failures)

| Rule | Value |
|------|--------|
| Worker commands | **exact** from `meta.json` only — no invented models/flags |
| Hang recovery | **max 1 retry per role per task** then **user confirm** (no infinite restarts) |
| Same taskId | while `dispatched`, **never** re-dispatch; do not spawn parallel assignees |
| Late `worker_done` | if task already `completed`, **ignore** (do not re-open phase) |
| `check --wait` | **exactly one** owner loop; never stack parallel waits |
| Task selection | dispatch **only** ids returned by this run's `task-create` |
| Claude model | `sonnet` + skip-permissions (see meta) — **not** `claude-sonnet-5` |
| design hang | retry Claude **once**; **no Grok HTML**, **no silent Codex design** without user OK |
| App code | **no production edits**; artifacts only under `$OUT` + notes |
| Secrets | mask in notes/HTML |

- Prefer `--worktree active` for reading the change.
- **Do not** pre-spawn the whole worker pool; advance phase-by-phase (except dual-verify which is intentionally parallel).
- Claude docs vs html: **separate terminals** (`claude-docs`, `claude-html`).
- Dual verify outputs: `verify-claude.md` + `verify-codex.md`; coordinator (or last pass worker) writes merge summary `verify-report.md` only after both done.

9. On completion (after human confirm), synthesize **FINAL** (한글):

1. 요약  
2. 이해 (5축)  
3. 파이프라인 결과  
4. 퀴즈 커버리지  
5. HTML 경로  
6. 잔여 리스크와 다음 질문  

## Worker commands (from meta — keep in sync)

| role | agent | command | ownership |
|------|-------|---------|-----------|
| research | codex | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | edit (notes only) |
| test-claude | claude | `claude --model sonnet --dangerously-skip-permissions` | review-only |
| test-codex | codex | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | review-only (notes: verify file only) |
| docs | claude | `claude --model sonnet --dangerously-skip-permissions` | edit |
| design | claude | `claude --model sonnet --dangerously-skip-permissions` | edit |
| review | grok | `grok -m grok-4.5 --reasoning-effort high` | review-only |

## Outputs

```text
~/Desktop/letsgo/<branch>/
  research-notes.md
  verify-claude.md
  verify-codex.md
  verify-report.md      # merge: both PASS required
  explainer.md
  explainer.html        # final: shell + filled content, Revolut tokens, Korean body
  gate-report.md        # optional review artifact
```

## Skip

Single-file trivial change → ask user whether to skip full pipeline.

## Anti-patterns

- Fire-and-forget handoff (this pack is **supervised**).
- `--model` on `orca orchestration dispatch`.
- Parallel `check --wait` loops.
- Single-agent verify when dual-verify is required.
- verify without **both** agents pass before docs/html.
- Same Claude session for docs + html.
- design inventing technical claims not in explainer.md.
- design rewriting shell `<style>` / inventing Vercel mesh look.
- Treating test/review `worker_done` as edit authority.
- Editing app production sources under this mode.
- Fuzzy task-title dispatch (e.g. any task containing "design").
- Re-dispatching a completed task because a late `worker_done` arrived.
- >1 hang recovery per role without asking the user.
- Inventing CLI models after hang (`claude-sonnet-5` → random aliases) outside meta.
```

---

## README.md (package / install root)

```markdown
# letsgo (lets-go) Orca mode pack

Installed orchestration mode for code-understanding explainers.

| File | Role |
|------|------|
| `PLAYBOOK.md` | Full coordinator + worker rules (**authoritative**) |
| `meta.json` | Worker commands, dual-verify flags, hang caps |
| `LESSONS.md` | Session learnings — skim every run |
| `DESIGN.md` | **Revolut** HTML design tokens ([source](https://github.com/VoltAgent/awesome-design-md/blob/main/design-md/revolut/DESIGN.md)) |
| `templates/explainer.shell.html` | Design worker shell (CSS + landmarks + SLOT markers) |
| `templates/README.md` | Template usage |
| `prompts/quick-command.txt` | Orca Quick Command text |

**Pipeline:** research (Codex) → **dual verify Claude∥Codex** → docs → design/html (shell + DESIGN) → review → human → FINAL (Korean).

**Design flow:** copy shell → fill slots from `explainer.md` → do **not** rewrite `<style>`.

Invoke via Grok skill `/letsgo` or Orca Quick Command **lets-go**.

After edit, keep `$HOME/.grok/skills/letsgo/SKILL.md` in sync with the install root.

## Path policy (public package)

This folder is the **shared** skill package. Paths must stay portable:

| OK | Not OK |
|----|--------|
| `$HOME/.orca/letsgo/...` | `<absolute-home>/.orca/...` |
| `$HOME/Desktop/letsgo/<branch>/` | hard-coded home absolute paths |
| `skills/orca/skills/letsgo/` (repo-relative) | hard-coded monorepo absolute paths |

When mirroring from a local install, rewrite absolute paths before commit.
```

---

## templates/README.md

```markdown
# letsgo HTML templates

| File | Role |
|------|------|
| `explainer.shell.html` | Revolut-styled self-contained shell (CSS + landmarks + SLOT markers) |

## Design worker flow

```bash
OUT="$HOME/Desktop/letsgo/<branch>"
cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
# Then fill SLOTs / sections from $OUT/explainer.md using DESIGN.md tokens already in :root
```

**Do not** regenerate the `<style>` block from scratch. Fill content only.

Optional filled reference: `$HOME/Desktop/letsgo/<branch>/explainer.html` (structure only).

DESIGN tokens: `$HOME/.orca/letsgo/DESIGN.md` (Revolut).

Path policy: `$HOME` / repo-relative only — never absolute `<absolute-home>/...`.
```

---

## 변경 이력

### 2026-07-18 (path masking · public package)

- 공용 문서/패키지에서 머신 홈 절대경로 · monorepo 절대경로 제거
- meta paths: `$HOME/...` + repo-relative `sourcePack`
- Desktop 개인 사본 경로를 팩 문서에서 제거 (레포 경로만 유지)

### 2026-07-18 (template + Revolut)

- DESIGN.md: Vercel → **Revolut** (VoltAgent awesome-design-md)
- HTML shell: `$HOME/.orca/letsgo/templates/explainer.shell.html`
- design 입력 3개: explainer.md + DESIGN.md + shell
- DoD: Revolut tokens · no mesh gradient · no style rewrite
- meta: `htmlShellPath`, `htmlShellSample`

### 2026-07-18 (dual-verify)

- **dual-verify:** `test-claude` ∥ `test-codex` 병렬, 독립 산출, merge 후 docs
- **Claude 모델:** `sonnet` + `--dangerously-skip-permissions` (폐기: `claude-sonnet-5`)
- **hang 상한:** role×task 당 1회 재시도 후 사용자 확인
- **태스크 위생:** `[letsgo:$RUN_ID]` 접두사, 이번 런 task-create id만 dispatch, 제목 퍼지 금지
- **wait:** 단일 `check --wait` 소유자
- **late worker_done:** completed 태스크는 무시
- **design fallback:** 사용자 승인 없는 Grok/Codex HTML 금지

### 이전

- 단일 Claude verify, sequential DAG, Grok coordinator 초안

---

## 동기화 메모

| 위치 | 역할 |
|------|------|
| `skills/orca/orchestration/letsgo-orchestration-pack.md` | 이 문서 (배포·설치 스냅샷) |
| `skills/orca/skills/letsgo/` | 공용 패키지 정본 (포터블 경로) |
| `$HOME/.orca/letsgo/*` | 런타임 install |
| `$HOME/.grok/skills/letsgo/SKILL.md` | Grok `/letsgo` 트리거 |

```bash
# REPO = monorepo root (환경 변수 또는 현재 디렉터리 — 문서에 절대경로 금지)
REPO="${LETSGO_SKILLS_REPO:-$PWD}"

# install → 공용 패키지 (경로 마스킹된 파일만)
rsync -a --delete --exclude 'SKILL.md' \
  "$HOME/.orca/letsgo/" \
  "$REPO/skills/orca/skills/letsgo/"
cp "$HOME/.grok/skills/letsgo/SKILL.md" \
  "$REPO/skills/orca/skills/letsgo/SKILL.md"
# meta/sourcePack 이 $HOME·repo-relative 인지 확인 후 커밋

# 공용 패키지 → install
rsync -a "$REPO/skills/orca/skills/letsgo/" "$HOME/.orca/letsgo/"
cp "$REPO/skills/orca/skills/letsgo/SKILL.md" "$HOME/.grok/skills/letsgo/SKILL.md"
```
