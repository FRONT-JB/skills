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
