# scv Orchestration Mode (Orca) — Global

OpenCode Go GLM-5.2 = **coordinator**. Workers = **OpenCode/init + Claude/plan + Codex/plan-review + Codex/implement + Claude/code-review + Codex/review-fix + OpenCode/release**.
When workers finish, the coordinator produces a **FINAL** synthesis.

Mode type: **supervised** — coordinator injects lifecycle, waits for worker_done (`check --wait`), then FINAL.

- 엔진: orchestration 스킬 (`orca orchestration …`) — **worker_done CLI 정본**
- 이 파일: 그 엔진 위에 얹는 **MyMode 행동 계약 SSOT**
- 표시/연출 SSOT: `$HOME/.orca/scv/UX.md` · `meta.json` `ui`
- 홈: `$HOME/.orca/scv/`
- 템플릿: `$HOME/.orca/scv/templates/`
- 프로젝트 오버레이: `.orca/scv.md` (있으면) · `AGENTS.md` (있으면)
- 런타임 상태(레포 내부): `.scv/state/$RUN_ID/` (**gitignore**, 커밋 금지)
- packVersion: `meta.json` 의 `packVersion` (**1.3.10**). 변경 이력: `LESSONS.md` / `meta.notes.changelog_*`

## 사용자 대면 언어 (필수 · 한글)

coordinator 진행·질문·FINAL = **한국어**. role/path/task id/CLI 영문 허용 · `scv_line` 인용 영문.

**연출·표·예시 SSOT = `$HOME/.orca/scv/UX.md`** (+ `meta.json` `ui`). 이 절은 요약만.

| 표면 | 규칙 (상세 → UX.md) |
|------|---------------------|
| 채팅 | 한 줄: `**【한글 phase 】** "scv_line" — 요약 · 다음: …` · `】` 앞 공백 1칸만 (`【대기 】`) |
| 탭 / `--display-name` | 한글 역할 라벨 (`계획 작성` …) |
| `--task-title` | `[scv:$RUN_ID] 한글 phase · slug` |
| wait shell description | `계획 작성 완료 대기` · bare `worker_done` / `Rolling wait…` 금지 (UX 1.3.9) |
| 발화 시점 | phase 진입·dispatch·gate·blocked·FINAL 만 (soft-wait 스팸 금지) |
| **사람 결정 게이트** | **AskUser 정확히 1회** (아래 절) · 본문 선택지 재질문 금지 |

## Human decision gates · AskUser (필수 · pack 1.3.6)

coordinator 세션의 **`ask_user_question` (AskUser)** 가 사람 확인 UI다.

### 적대 검증 요약 (왜 이 규칙인가)

| 우려 | 판정 |
|------|------|
| intake “추정 메뉴 선제 금지”와 충돌? | **아니오** — bare seed free-text와 **결정 게이트**는 분리 |
| 모든 채팅을 메뉴로? | **아니오** — 선택/승인/중단이 있는 게이트만 |
| 수정 내용 장문? | AskUser로 **모드** 선택 후 free-text (수정 본문은 Other/후속 메시지) |
| Orca `decision_gate`와 이중 질문? | AskUser = **유일한 질문 UI** · Orca gate/`decisions.md`는 추적 기록(채팅 재질문 금지) |
| 워커(Claude/Codex) AskUser? | **아니오** — 사람 게이트는 **coordinator only** |

### 필수 AskUser (human decision gate)

다음에서는 **AskUser를 정확히 1회** 호출한다. 같은 선택지를 채팅 본문에 bullet/문장으로 **다시 쓰지 않는다**.

| 게이트 | 대표 옵션 (권장 첫 항) |
|--------|------------------------|
| plan → implement 승인 | 승인 · 수정 요청 · 중단 |
| 범위 확장 (§3b) | 원범위 완료 · 후속 분리 · 현 런 편입 |
| P0 / P1 risk accept | 위험 수용 · 수정 후 재개 · 중단 |
| dirty worktree / 보호 브랜치 | 안내 후 선택 (커밋 분리·stash·중단 등) |
| push / 릴리스 최종 확인 | push 진행 · 보류 · 중단 |
| mid-run reclaim opt-in | 회수 · 유지 |
| hang 포기·재배정 (사람 결정) | 재시도/재배정 · 중단 |

### AskUser 금지 · 예외 (free-text / 비게이트)

| 상황 | UI |
|------|-----|
| bare `/scv` · empty seed | **free-text 1회** (추정 옵션 메뉴 선제 금지 — 기존 intake) |
| “수정 요청” 선택 후 변경점 서술 | free-text (AskUser 직후) |
| 정보성 진행 내레이션 | UX 한 줄만 · 선택지 없음 |
| worker_done 대기 | `check --wait` · AskUser 아님 |

### 출력 순서 (중복 금지)

```text
1) 요약·표·경로 (정보)
2) 선택: UX 라벨 한 줄 (질문 문장 없이)
   예: **【계획 승인 대기 】** "Orders, Cap'n?" — plan-review APPROVED · 승인 대기
3) AskUser 1회 (승인 / 수정 요청 / 중단 …)
4) 금지: "이 계획으로 구현을 진행할까요?" 를 본문에 다시 쓰기
5) 답 수신 전 implement dispatch / push / 파괴적 동작 금지
6) 답 → decisions.md 또는 run 상태 기록 · 필요 시 Orca gate resolve (채팅 재질문 없이)
```

### plan 승인 게이트 (대표)

plan-review 최종 APPROVED(또는 동등) 후 implement 전:

1. 요약 표 + 리포트/plan 경로  
2. UX 라벨 0~1줄 (재질문 없음)  
3. **AskUser 1회** — 승인(Recommended) / 수정 요청 / 중단  
4. 승인 시에만: plan 로컬 커밋 + hash/scope/gate 동결 → implement  

## 문서 언어 (강한 기본값 · 정책)

**finding P0(never SUCCESS)와 혼동하지 말 것.** 문서 언어 위반은 **정책 P1** (release 전 수정). 안전/정확성 P0 슬롯을 문서 언어에 쓰지 않는다.

### resolve 우선순위

```text
명시적 사용자 지시  >  프로젝트 `.orca/scv.md` docsLanguage  >  전역 기본(ko)
```

preflight에서 한 번 계산해 `run.json`에 `resolvedDocsLanguage: "ko"|"en"` 기록.  
워커 task spec에는 **Korean 하드코딩 금지** — resolved directive를 주입:

```text
Prose language: <resolvedDocsLanguage>. Keep identifiers/paths/commands/error quotes in English.
```

| 대상 | 언어 |
|------|------|
| 사용자 채팅 진행·질문·FINAL | 항상 한글 (위 절) |
| 커밋 `docs/**` 프로즈 (ARCHITECTURE, plan, CR, changelog, TESTING, memo, README) | **resolvedDocsLanguage** (기본 ko) |
| `.orca/scv.md` 설명 문장 | resolved (기본 ko) |
| `.scv/state/**` | 한글 권장 (커밋 안 함) |
| 경로·role·task id·명령·에러 로그·코드 식별자 | 영문 유지 |

검증: Hangul 비율 휴리스틱만으로 PASS/FAIL 확정 **금지**. FINAL 전 체크리스트에 “변경된 docs 프로즈 언어 = resolvedDocsLanguage” **필수 항목**. code-review는 프로젝트 기본이 ko일 때 영문 프로즈를 P1로 기록 가능.

오버라이드: `.orca/scv.md`에 `docsLanguage: en` 명시 시 영문 문서 허용 (위반 아님). 질문/FINAL은 여전히 한글.

## 언제 쓰나

트리거: **scv**, **/scv**, **scv-harness**

피처를 plan → implement(배치) → quality gate → code-review → release(docs/push) 순으로 출시할 때.

## 시작 전 확인 (preflight)

```bash
orca status
command -v opencode codex claude
# 권장 스모크 (모드별 플래그 주의 — LESSONS)
# 터미널 워커(meta): codex … -a never -s danger-full-access
# codex exec (비대화): -s danger-full-access --dangerously-bypass-approvals-and-sandbox  ( -a 사용 금지 )
```

추가 의무 (light preflight — **seed 확보 전**에도 가능):

1. residual tasks 목록 요약 (`task-list --brief`) — **이번 런 task-create id만** dispatch
2. dirty면 decision_gate · 기존 변경 stage/commit 금지 · **`git add -A` 금지**
3. `.scv/` 가 `.gitignore`에 있는지 확인 · **`.scv/**` 절대 스테이징 금지**
4. `.orca/scv.md` 에 기본 gate·docsLanguage·versionPolicy·`audit` 확인
5. (권장) claude alias / codex 터미널 플래그 스모크

**RUN_ID / state dir는 non-empty seed 확보 후에만** 발급 (bare `/scv` 만으로 orphan state 금지). seed 확보 후:

6. `RUN_ID=$(date +%Y%m%d-%H%M%S)-<slug>` · `[scv:$RUN_ID]` 접두 · `.scv/state/$RUN_ID/` 생성  
7. path · branch · HEAD · dirty · **seed snapshot** → `run.json` (`phase: RUNNING`, `closed: false`)  
8. **`resolvedDocsLanguage`** resolve → `run.json`  
9. 터미널 레지스트리 준비: `terminals[]` = `{ handle, role, createdByRun, preExisting }` (reclaim allowlist)

## 역할

| 역할 | agent | ownership | command | 할 일 | 산출 | 제약 |
|------|-------|-----------|---------|-------|------|------|
| coordinator | opencode | — | `opencode -m opencode-go/glm-5.2 --auto` (현재 세션) | 인터뷰·브리프·dispatch·gate 판정·FINAL | FINAL · decisions | plan/코드 **설계 본문** 미작성 |
| init | opencode | edit | `opencode -m opencode-go/glm-5.2 --auto` | docs 골격·ARCHITECTURE 초안 | docs/** scaffolding | 소스 수정 금지 · 사용자 승인 후만 · 템플릿 참조 |
| plan | claude | edit | `claude --model opus --dangerously-skip-permissions` | plan.md 작성·수정 | `docs/plans/YYYY-MM-DD_<slug>.plan.md` | 코드 스니펫 금지 · gate·scope manifest 필수 |
| plan-review | codex | review-only | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | plan 검증 | `.scv/.../plan-review/codex.md` | 파일 수정 금지 |
| implement | codex | edit | `codex -m gpt-5.6-luna -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | 배치 구현 · 로컬 커밋 · gate | 코드 + commits + gate 증거 | feature branch · scope 준수 |
| code-review | claude | review-only | `claude --model opus --dangerously-skip-permissions` | 코드 리뷰 | `.scv/.../code-review/claude-round-N.md` | 수정 금지 |
| review-fix | codex | edit | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` | 리뷰 반영 · gate | 코드 + commits + gate | P0/P1 범위만 |
| release | opencode | edit | `opencode -m opencode-go/glm-5.2 --auto` | 7a docs · 7b push 확인 | changelog·CR·ARCHI·push-status | 코드 설계 본문 금지 · push는 확인 후 |

**모델 규칙:** 모델은 worker `command` 에만. `dispatch` 에 `--model` 없음.  
**조율 유형:** supervised

### 교차 검증 (고정)

| 구간 | 작성 | 검증 |
|------|------|------|
| plan | Claude | Codex |
| code | Codex | Claude |

## 팀장 루프

### 0) 프롬프트 우선 intake · 인터뷰 · RUN_ID · preflight

**Empty Goal / bare `/scv` 는 오류가 아니다.** 다만 **추정 옵션 메뉴를 먼저 띄우지 않는다.**

#### 0a. seed prompt 확보 (prompt-first)

1. 사용자 메시지에서 트리거(`scv` `/scv` `scv-harness`)·빈 `Goal:` 접두를 제외한 본문을 **seed prompt** 로 추출.
2. **seed가 비어 있지 않으면** 그 텍스트를 인터뷰 입력으로 사용.  
   - 한 줄 Goal · 긴 배경/제약 모두 동일.  
   - 팀장이 가정·범위 초안을 **한 단락 요약** 후, 모호한 점만 gstack 인터뷰 (선택지는 보조).
3. **seed가 비어 있으면** (`/scv` only 등):  
   - **추정 2–4안 AskUser 메뉴 선제 금지.**  
   - 자유 서술 1회: 「이번 런에서 다루고 싶은 작업을 자유롭게 적어 주세요.」 또는 다음 채팅 메시지 대기.  
   - 답이 오면 그걸 seed로 사용. 무응답 orphan state 만들지 말 것.
4. 모호한 한 단어 seed → 재질문으로 좁힘 (메뉴는 보조).

#### 0b. RUN_ID · brief · 워커 금지선

5. **첫 non-empty seed 확보 직후** `RUN_ID` 발급 · state dir · seed snapshot 저장 · `phase: RUNNING`.  
   - slug는 이후 brief 변경으로 **rename하지 않음** (immutable RUN_ID).
6. gstack 인터뷰로 Goal·범위·brief 확정 → `.scv/state/$RUN_ID/brief/plan-brief.md`.
7. light preflight는 seed 전에도 가능. **워커 dispatch · plan.md 작성은 brief/Goal 확정 후만.**
8. 보호 브랜치면 **최초 커밋 전** feature 브랜치 decision_gate.

#### 0c. 로드맵 초안 (필수 · coordinator → plan handoff)

인터뷰로 Goal·범위가 확정되면 coordinator 는 **plan 워커 dispatch 전**에 로드맵 초안을 반드시 작성한다.

| 항목 | 내용 |
|------|------|
| **템플릿** | `templates/roadmap.md` (고정 · 항목·순서·섹션 제목 변경 금지) — `meta.intake.roadmapTemplate` |
| **필수 포함** | (1) 수행할 작업 요약(목표·의도 한 단락) (2) 수정 영역 후보(파일/디렉터리 경로 목록 — **존재만 확인**, 본문/JSX 구조 분석 금지) |
| **탐색 깊이** | `quick` file-list only. route/컴포넌트 파일 경로 파악 수준. `very thorough` JSX 구조·위계 후보 열거 **금지**(그것은 plan 워커의 역할) |
| **산출** | `.scv/state/$RUN_ID/brief/roadmap.md` — 템플릿의 `{{placeholder}}`를 채운 단일 파일. 빈 칸은 `N/A` |
| **전달** | plan 워커 `--spec` 의 handoff 경로에 `roadmap.md` 경로 포함. plan 워커는 이 초안을 출발점으로 plan.md 를 확장(파일 단위 섹션·스페이싱·위계 설계는 plan 워커가) |
| **금지** | coordinator 가 로드맵에 코드 스니펫·상세 JSX 위계 설계·게이트 명령까지 작성 (plan/코드 설계 본문 미작성 원칙 유지). **템플릿 항목·순서 임의 변경 금지** |

로드맵 초안은 **plan 워커가 plan.md 를 0부터 시작하지 않도록 하는 출발점**일 뿐, plan-review/승인 게이트를 우회하는 경로가 아니다. 템플릿이 고정이므로 매 런 동일한 구조의 첫 prompt 가 plan 워커에게 전달된다.

### 1) task-create

```bash
orca orchestration task-create \
  --task-title "[scv:$RUN_ID] 계획 작성 · <짧은-slug>" \
  --display-name "계획 작성" \
  --spec "<LIFECYCLE block + full task body including resolvedDocsLanguage directive>" \
  --json
```

**주의:** 플래그는 `--task-title` (not `--title`). `--spec` 필수.  
**`--display-name` = 한글 역할 라벨 필수** · `--task-title` = `[scv:$RUN_ID]` + 한글 phase + slug.  
**이번 런 task-create id만 dispatch.** 제목 퍼지 매칭 금지.

#### LIFECYCLE 블록 (필수 · pack 1.3.5 · inject preamble 보강)

모든 워커 `--spec` **맨 위**에 고정 (Orca inject preamble이 구식 `--payload` 예시를 줘도 이 규칙이 우선):

```text
LIFECYCLE (mandatory):
- On completion send exactly one worker_done with structured flags only:
  orca orchestration send --to <coordinator_from_preamble> --type worker_done \
    --subject "<status>" --body "<summary>" \
    --task-id <taskId> --dispatch-id <dispatchId> \
    [--files-modified "a,b"] [--report-path "<path>"] --json
- NEVER pass --payload together with --task-id/--dispatch-id/--files-modified/--report-path/--phase
  (CLI: Use either --payload or structured payload flags, not both).
- Prefer structured flags over raw --payload. On "not both" error: fix flags, retry once.
- After successful Sent msg_…: do not send a second worker_done. Then idle.
Prose language: <resolvedDocsLanguage>. Keep identifiers/paths/commands/error quotes in English.
```

review-only subject 권장: `REQUEST_CHANGES · 계획 검토` / `APPROVED · 계획 검토` (영문 verdict + 한글 phase).

#### RPC / JSON id 추출 계약 (필수 · pack 1.3.1)

Orca CLI `--json` 응답은 공통 envelope 이다: 루트 `id`(RPC UUID) · `ok` · `result` · `_meta`.  
**루트 `id` 를 task/dispatch/terminal id 로 쓰지 않는다.**

| 대상 | 추출 경로 | 접두(보조) |
|------|-----------|------------|
| task | `result.task.id` | `task_` |
| dispatch | `result.dispatch.id` | `ctx_` |
| terminal **create** | `result.terminal.handle` | `term_` |
| terminal **split** | `result.split.handle` | `term_` |
| send (단건) | `result.message.id` | `msg_` |
| check messages | `result.messages[].id` | `msg_` |

파서 공통: exit code → `ok === true` → 명령별 `result` schema. 실패/timeout envelope 에서는 **task/worker 상태 전이 금지** (soft recheck).  
`thisRunTaskIds[]` 에는 `^task_` 만 push. 접두 검사는 경로 추출 **후** 보조 guard.

### 2) 터미널 레이아웃 — **split pane 우선** · **idempotent create**

| 순서 | 동작 |
|------|------|
| 1 | **첫 워커만** `terminal create` + **한글 `--title`** (역할 라벨 표) |
| 2+ | **`terminal split`** + **`rename` 한글 타이틀** (역할 라벨 표) |
| 예외 | split 실패 복구 1회 · 사용자 “탭으로” · 다른 worktree |

- direction: 기본 `vertical` · 리뷰 쌍 `horizontal`
- **타이틀 / display-name:** 동일 한글 역할 라벨. create `--title` / split 직후 `rename` / task-create `--display-name`.
- create/split 직후 **직렬 tui-idle 다중 wait 남발 지양** — 필요 pane 을 bounded `terminal list/show` sweep 으로 readiness 확인 가능. inject 는 단계 도달 후에만.

##### 세션 재사용 정책 (필수 · pack 1.3.7 · full)

> **Same role + same phase loop → resume. Anything else → fresh session + file handoff.**

| 규칙 | 내용 |
|------|------|
| **ALLOW resume** | **동일 `role` AND 동일 phase 루프** 안 round 2+ 만. 역할당 live handle **1개**. 라운드 번호 시 제목만 `· 2` rename. 라운드마다 새 세션 **금지**. |
| **FORBID cross-role** | role 이 바뀌면 **binary/command 가 같아도** 재사용 금지. 예: plan Claude ≠ code-review Claude · plan-review Codex ≠ implement Codex · implement Codex ≠ review-fix Codex(meta command/effort 다르면 특히). |
| **FORBID cross-phase** | phase 경계에서 이전 role handle 에 다음 phase task inject 금지. 예: plan 계열 → implement/code-review/audit · implement → audit. |
| **FORBID idle-pick** | “놀고 있는 Claude/Codex” 를 다음 역할·Audit 에 재할당 금지. command-compatible idle warm **금지**. |
| **FORBID far warm pool** | 먼 미래 역할 사전 create/warm 금지 (stale / Codex update 위험). |
| **Idempotent create** | 동일 `(title, role, phase-loop)` 이 **alive** 이고 **그 role 루프가 아직 진행 중** 일 때만 재사용. dead 슬롯만 교체. create 직후 live handle **1개** 확정. dead pane 은 completion authority 금지. |
| **중복 create** | 이중 탭 create 후 하나만 쓰기 금지 — 즉시 하나로 합치거나 dead 마킹. |
| **Phase-end close (기본)** | 해당 role 루프가 **terminal**(산출 MUST + worker_done 소비 + 재발화 없음) 이면 **기본 close** (exact handle · evidence escrow · mid-run `--tab` 금지 절차 준수). “default keep forever” 아님. |
| **Hang recovery** | active-dispatch stuck → **fresh terminal** + 새 dispatch (같은 pane re-inject 금지). 기존과 동일. |

**Handoff = 세션이 아니라 파일 (필수)**

이전 transcript 에 의존하지 않는다. phase/role 전환 시 coordinator 가 짧은 handoff 를 state 에 쓰고, **새 세션 spec 에 경로만** 넣는다.

| 전환 | handoff 최소 (`.scv/state/$RUN_ID/handoff/` 또는 기존 산출 경로) |
|------|------|
| intake → plan (로드맵) | `brief/roadmap.md` 경로 + brief 요약 (로드맵 초안 = plan 출발점) |
| plan → plan-review / plan fix 라운드 | plan 경로 · 직전 review verdict 경로 (resume 시 notes) |
| plan 승인 → implement | 승인 plan 경로 · hash/scope/gate 동결 요약 · decisions 앵커 |
| implement → code-review | plan 경로 · gate summary · 배치 report 경로 · 변경 범위 |
| code-review round N→N+1 | 직전 finding · implementer notes · 재실행 gate summary (**이때만** 같은 role resume) |
| release → AUDIT | `audit/inventory.md` (timeline · hang · reclaim · gate · 탭 이력) |
| 템플릿 | `templates/handoff.md` — **≤40줄** · transcript 덤프 금지 |

**짧은 런 예외 (opt-in · 기록 필수)**  
docs-only / 1파일 trivial 이고 사용자가 동의하면, 단일 Claude 또는 단일 Codex 로 축약 가능. 단 **Audit 는 예외 없음**(아래). decisions 에 예외 사유 1줄.

### 3) dispatch · wait (단일 소유자)

```bash
orca orchestration dispatch --task <task_id> --to <handle> --inject --json
# 단일 소유자 · rolling soft window(기본 90s) · soft timeout ≠ 하드 abort
# meta.waitTimeoutMs=900000 은 전체 감독 budget(15m) 가이드 — 한 번의 CLI 블로킹을 15분으로 늘리지 말 것
# heartbeat 를 --types 에 넣지 말 것 (완료로 오인·메일 스택 유발)
# 고정 sleep 후 wait 금지 → wait·liveness fusion (아래)
orca orchestration check --wait \
  --types worker_done,escalation,decision_gate \
  --timeout-ms 90000 --json
```

**Wait · 메일 스택 방지 (필수)**

팀장(scv) 탭에 `Orchestration Messages` 가 **쌓여 멈추는 것**은 정상이 아니다. 아래를 강제한다.

| 규칙 | 내용 |
|------|------|
| 단일 wait 소유자 | 전역 **정확히 하나**의 `check --wait` 루프. 병렬 wait·sleep-poll 이중 루프 **금지** |
| wait 타입 | **`worker_done,escalation,decision_gate` 만**. `heartbeat` / `status` 를 wait 타입에 **넣지 않음** |
| heartbeat | 살아 있음 표시일 뿐 **완료 아님**. 필요 시 `--peek` 또는 terminal show 로만 확인 |
| 메시지 소비 | wait/unread 로 **1건 처리 → 다음 행동**. 미소비 메일을 쌓아 두지 않음 |
| 스택 정리 | UI에 Orchestration Messages 가 쌓이면 drain. **무타입 전체 unread 를 “버리고 끝” 금지** — 반환 메시지를 `type`/`taskId`/`dispatchId`/`msgId` 로 분류해 this-run lifecycle 큐에 넣거나 non-lifecycle 만 제한 소비. **미해결 `decision_gate` 유실 금지** |
| timeout | soft · 실패 아님 → task-list + terminal show + artifact 확인 후 **중복 dispatch 없이** 재대기. rolling window 기본 **90000ms**; `meta.waitTimeoutMs`(900000)는 **전체 budget 가이드**이지 단일 블로킹 호출 값이 아님 |
| shell background | **waiter 프로세스만** 정리 후 새 wait. **worker terminal / orchestration task kill 금지**. kill 시 `runId+waitGeneration+pid+startTime+argv` 검증(불명확하면 skip · `reclaimStatus: partial`) |
| hang | role×task 당 재시도 **1회** 후 decision_gate |
| late done | completed task 의 late `worker_done` **무시** (재오픈·재대기 금지) |
| 완료 후 공회전 | worker_done **소비** + (edit 단계면) gate 증거 확인 후면 **추가 wait 창을 열지 말 것** (task-list completed 만으로 전진 금지 — `worker_done ≠ gate PASS`) |
| post-inject / liveness | **고정 `sleep 60` 금지.** wait·liveness fusion(아래). hung 임계(Ready-no-tools ≥90s 등)는 유지 · **조기 hung 금지** |
| peer 런 | runtime-global task 목록에 다른 `[scv:$OTHER]` 가 보이면 soft warn 한 줄. **title 만으로 공유 worktree 단정 금지**(task row에 branch 없음; terminal registry join 후에만 위험 승격). 값 변할 때만 고지 |
| 사용자 안내 | phase 진입 시 한 줄: `**【대기 】** "Affirmative." — … · 다음: 작업 완료 대기`. bare `worker_done`/`heartbeat` 금지. soft-timeout 스팸 금지. |
| wait shell description | 한글 필수: `계획 작성 완료 대기`. `(worker_done)` 괄호·`Rolling wait…` 금지. |

선택/필수 상태 필드 → 아래 **run.json 스키마**. 병렬(`maxConcurrent: 2`) 시 **전역 단일 `activeDispatchId` 만으로 straggler 판정 금지** — task별 registry 사용.

**`check --wait` 출력 파싱 (필수 · NDJSON + pretty 혼재 · pack 1.3.1)**

`check --wait --json` 은 대기 중 **`_keepalive` / `_heartbeat`** 줄과 pretty-printed 최종 envelope 가 **같은 캡처에 섞일 수 있다**(환경에 따라 stdout 단독 또는 stdout/stderr 분리). 전체를 한 번에 `json.loads` 하면 `Extra data` 로 깨진다.

| 규칙 | 내용 |
|------|------|
| 스트림 | 가능하면 **stdout / stderr 분리**. stderr 의 keepalive marker 는 lifecycle 제외. 병합 캡처면 string/escape-aware 로 **연속 JSON 값**을 읽음(단순 brace count·순진한 line-accumulate 로 pretty 내부 scalar 를 끊지 말 것) |
| line-wise | 한 줄이 완전한 JSON 이면 즉시 parse |
| skip | `_keepalive` · `_heartbeat` · 빈 줄 · 파싱 실패 조각은 lifecycle 제외 |
| 완료 수락 | **`ok === true` 이고 `result.messages` 가 배열** 인 check envelope 만. “마지막 JSON 객체” 단정 금지. `ok: false` / scalar / 다른 verb bare JSON 은 완료 아님 |
| 파서 오류 | task/worker 상태를 바꾸지 않음 · task-list + terminal show 로 soft recheck |

**Straggler / late lifecycle (필수)**

| 규칙 | 내용 |
|------|------|
| authority | 수락 조건: payload `taskId` ∈ this-run **and** (`dispatchId` == **해당 task 의 activeDispatchId** **or** task 가 아직 dispatched). 병렬 시 전역 단일 id 비교 금지 |
| drop | completed taskId · 이전 retry dispatchId · 다른 런 id → **silent drop** (로그 1줄, 사용자 반복 고지 0) |
| closed 후 | late heartbeat/worker_done → silent dedupe · FINAL 이후 잔여 메일 반복 고지 **금지** |
| decision_gate | 미해결 human gate 는 drop 금지 |

**Wait · liveness fusion + hung recovery (필수 · pack 1.3.1)**

`tui-idle` + `injected: true` 만으로 “작업 중” 금지. **고정 `sleep 45–90` 후 show 패턴 금지.**

1. inject 직후 **별도 sleep 없이** 단일 `check --wait`(rolling 60–90s) 를 연다.  
2. **worker_done 이 먼저 오면** → 소비 후 다음 단계(edit 이면 gate 증거 확인). liveness 추가 sleep 불필요.  
3. **첫 timeout(~45–60s)** 이면 soft recheck: task 상태 + **inject 이후** terminal preview/output **delta** 1회.  
   - **Healthy (early):** inject 이후 tool path · 파일 경로 · 비자명 preview 성장 · 유효 heartbeat → **재dispatch 없이** wait 재개 (`healthy ≠ 완료`).  
   - 한 번 tool 찍고 멈춘 pane 을 장시간 healthy 로 고정하지 말 것 — 이후 창에서 delta 재검증.  
4. **Unhealthy / hung 후보 (조기 hung 금지):** shell 프롬프트만 · “Update ran successfully / restart” · MCP/launch 줄만 · spinner-only · **Ready 인데 도구/산출 0 이 ≥90s**.  
5. **Active-dispatch stuck:** dispatch active + 비생산 → **같은 pane re-inject 금지** · `task-update ready` · **fresh terminal** + 새 dispatch · hang recovery max 1.  
6. **Codex 특이:** 자가 업데이트 / Ready 공회전 = hung. update 프롬프트 세션에 inject 금지.  
7. **Recovery SSOT:** uncommitted 경로 목록 + 단일 edit owner.

| 신호 | 판정 |
|------|------|
| inject 이후 tool/path/preview 성장 | healthy → 계속 wait (완료 아님) |
| heartbeat only | alive ≠ done |
| Ready-no-tools / update / bare shell ≥90s | hung |
| dispatch active + 비생산 | stuck → fresh terminal |

**속도 규율 (스텝 불변 · wall-clock)**

| 할 일 | 하지 말 것 |
|-------|------------|
| 1.3.1 파서로 완료 후 공회전 제거 | 리뷰/게이트 스킵, 단계 생략 |
| wait·liveness fusion · 고정 sleep 제거 | wait timeout 단축으로 “완료 가속” 착각 |
| **same-role loop 만** resume · phase-end close | cross-role/cross-phase reuse · idle-pick · command-compatible warm · 먼 미래 warm pool · 핑퐁마다 새 탭 |
| audit/리뷰 쌍 maxConcurrent=2 병렬 | plan∥plan-review, same-batch implement∥code-review |
| 승인 대기 중 read-only 준비(branch/gate dry) · **다음 role terminal create 는 phase 진입 시** · inject 금지 | 승인 전 implement dispatch · 다음 역할을 idle plan pane 에 얹기 |
| handoff latency 기록 (`workerDoneAt`→`consumedAt`→`nextDispatchAt`) + **file handoff** | 병렬 task duration 단순 합 · transcript 를 다음 세션에 통째 의존 |
| phase-end close(기본) + mid-run soft reclaim(예외 pane) · evidence escrow | 끝난 role 을 audit 예비로 방치 · active/audit pane 조기 회수 · `--tab` |

사람 승인·워커 사고 시간은 줄이지 않는다. 줄이는 대상은 **코디 오버헤드·공회전·직렬 낭비·죽은 탭**.

**안티패턴 (메일 스택 · 대기)**

- wait 루프 2개 이상
- `--types` 에 heartbeat 포함
- NDJSON 전체를 단일 `json.loads`
- RPC envelope 루트 `id` 를 taskId 로 사용 · `terminal split` 을 `result.terminal.handle` 로 오파싱
- completed/stale `dispatchId` 메일을 현재 완료로 처리 · 전역 단일 activeDispatchId 로 병렬 정상 dispatch 를 straggler 처리
- active-dispatch stuck 에 같은 pane re-inject 반복
- 핑퐁(same-role) 라운드마다 새 세션 create → inject 폭증 · 먼 미래 역할 warm pool
- **cross-role / cross-phase handle 재사용** · command-compatible idle warm · 놀고 있는 pane 에 다른 역할 inject
- worker_done 을 읽지 않고 “메시지 있음” 만 반복 표시
- 미소비 메일 N건을 한 화면에 쌓아 두고 파이프라인 정지
- 무타입 unread drain 후 decision_gate/다른 런 worker_done 유실
- 고정 sleep 60 후 show · 완료 후에도 rolling wait 창을 계속 염
- task-list `completed` 만 보고 gate 증거 없이 다음 단계 전진

### 4) 파이프라인 단계

#### 0. init (선택)

- 조건: `docs/ARCHITECTURE.md` 또는 docs 골격 부재
- 사용자 scaffolding 승인 후 · docs only · `templates/ARCHITECTURE.ko.md` 참조 (resolved ko일 때)
- 워커: opencode-init

#### 1. plan 인터뷰 (coordinator)

Goal → gstack 인터뷰 → brief: `.scv/state/$RUN_ID/brief/plan-brief.md` → **로드맵 초안**(`roadmap.md`, §0c) 작성 → plan 워커 handoff.
인터뷰 중 plan 본문·코드 작성 금지. 로드맵은 경로 목록 수준(설계 본문 아님).

#### 2. plan 작성

- claude-plan · `docs/plans/YYYY-MM-DD_<slug>.plan.md`
- 템플릿: `$HOME/.orca/scv/templates/plan.ko.md` (resolved ko)
- 필수 섹션: Overview · Architecture · Files · Test Impact(**가설 vs 검증**) · To-dos · **Gate commands** · **Scope manifest** · Constraints · Non-goals
- **Scope manifest (동결 대상):** allowed paths/globs · 예상 파일 수 또는 상한 · 변경 종류 · frozen gate 명령
- **Lint 재활성 정책** (config 로드 복구 등으로 규칙이 살아날 때):  
  (A) 최소 autofix를 **별 배치**로 · (B) FAIL 보고 후 decision_gate · (C) 후속 이슈로 분리  
  기본 권장: **후속 분리(C)** 또는 사용자 확인 후 (A). coordinator 자가 확장 금지.
- 코드 스니펫 금지

#### 3. plan 리뷰 핑퐁 (≤2)

- Codex plan-review ↔ Claude plan fix
- **사용자 plan 승인 = AskUser 1회** (위 Human decision gates). 본문 선택지 중복 금지.
- 승인 시: plan 로컬 커밋 + **content hash + scope manifest + gate 동결** → `plan-refine/decisions.md`
- 승인 후 plan 본문/hash/scope/gate 변경: 승인 무효 → **Codex plan-review 재통과** → 재커밋 + 재동결.  
  **재승인만으로 기술 리뷰 우회 금지. skip 경로 없음.**
- AskUser **승인** 후에만 implement

#### 3b. 범위 확장 decision_gate

| 종류 | 승인자 |
|------|--------|
| 구현 세부 (scope 안 도구 선택) | coordinator 가능 |
| **범위 확장** (paths/파일수/종류/gate 이탈) | **사용자 필수** |
| P1 risk accept | **사용자 only** |

**범위 확장 판정:** 승인 scope manifest의 paths · 파일 수 상한 · 변경 종류 · frozen gate 중 **하나라도** 벗어나면 즉시 중단.

사용자 gate: **AskUser 1회** 옵션 = `원범위 완료` / `후속 분리` / `현 런 편입`  
(원인·추가 범위·예상 파일 수·위험은 요약 본문에 먼저 제시 · 질문 재서술 금지).

- **현 런 편입:** 사용자 승인 **AND** plan 패치 **AND** Codex plan-review 재통과 **AND** hash/scope/gate 재동결 — 그 전 파일 수정 재개 금지.
- **후속 분리:** scope 밖 변경 0 · known debt만 기록.
- autofix / 새 ignore / 다른 패키지 수정을 “구현 세부”로 오인 금지.

#### 4. implement 배치

- feature branch only
- scope manifest 준수 · 관심사 분리 커밋 권장  
  (예: `fix(ui): …` / `style(ui): import-sort` / `chore(web): eslintignore`)
- 커밋 scope는 실제 터치 경로와 일치
- 배치마다 quality gate · 로컬 커밋 (docs+소스만 stage · never `git add -A`)

#### 5. quality gate

- 실행 주체: 방금 트리를 바꾼 edit 워커
- 명령: **동결 목록 only** · invent 금지
- pass = 동결 명령 전부 exit 0 (typecheck/test 없으면 N/A 기록)
- 증거 3겹: quality-gate md · worker_done gate · 로컬 커밋 SHA
- **worker_done ≠ gate PASS**

**baseline 진단 vs acceptance (분리)**

| | baseline 진단 | acceptance gate |
|--|---------------|-----------------|
| 시점 | 변경 전 HEAD 또는 무관 실패 입증 | 이번 변경 후 |
| 목적 | pre-existing known debt 기록 | 이번 ship 합격 |
| docs-only + 무관 FAIL | **기록만** · 차단 안 함 · READY_TO_PUSH 오용 금지 | docs 관련 검사 있으면 그것만 |
| 동작 | **자동 fix 제안 금지** · 후속 분리 기본 | FAIL이면 다음 단계 금지 |
| 현 런 편입 | 사용자 선택 시에만 → §3b 범위 확장 절차 | — |

#### 6. code-review 핑퐁 (≤3)

- Claude review ↔ Codex fix + gate
- exit: P0+P1 == 0
- P0 잔여 → BLOCKED · P1만 → human risk accept 시에만 `SUCCESS_WITH_ACCEPTED_RISK`
- 문서 정합만 P1이면 docs-fix 경로 가능 (소스 불필요 시 review-fix가 plan/docs만)

#### 7a. release docs

- **기본:** opencode-release 워커 dispatch (task/dispatch/worker_done 증거)
- coordinator 대행 시 decisions에 `release:coordinator-exception` + 사유·파일 목록
- 버전 · changelog · CR 승격 · ARCHITECTURE — 경로/bump는 plan 또는 `.orca/scv.md` (`versionPolicy`: 기본 `root-only`)
- 프로즈 언어 = resolvedDocsLanguage
- 빌드 영향 시 최종 gate 재실행 · docs-only면 라벨 명시

#### 7b. release git

- push/PR: **사용자 확인 후** · feature branch · 1회
- 거부/보류 → `READY_TO_PUSH` (실패 아님) · push-status.md
- main push · merge · 자동 태그 · 무단 PR 금지

#### 8. Post-run Audit (필수 시도 · ship 상태와 직교)

release 7b 결과 확정 후 (SUCCESS / SUCCESS_WITH_ACCEPTED_RISK / READY_TO_PUSH / BLOCKED 모두 **시도**).  
**audit 실패·부분 실패는 ship terminal status를 바꾸지 않는다.** `auditStatus: complete | partial | failed`.

```text
phase: AUDIT
  → inventory.md (팀장)
  → Claude∥Codex audit review 각 1회 (핑퐁 금지 · 단일 wait owner가 두 task 대기)
  → improvements.md 합본 (팀장)
```

**목적 (고도화 금지 · time / stability only)**

| 초점 | 내용 |
|------|------|
| **유지** | 기존 파이프라인·교차검증·gate·scope·supervised lifecycle **최대한 유지** |
| **time** | wall-clock 단축 (중복 wait/dispatch, 불필요 create, 공회전 대기 등) |
| **stability** | hang, late mail, gate 유실, waiter 중복, reclaim, CLI 실수 등 |
| **제외** | 단계/역할 재설계, 교차검증 위상 변경, 라운드 상한·gate 3겹 약화, 모델 다운 강요, 앱 코드 리팩터, playbook 전면 개편 |

**워커 · 세션 (pack 1.3.7)**

- **meta에 audit 전용 역할 추가 금지** (workers 7 유지). 표시 라벨만 `감사`(Claude) / `감사 · Codex` — UX.md.
- **Audit = always fresh:** plan/implement/code-review/review-fix 등 **기존 role handle 재사용 금지**. Claude 1 + Codex 1 을 **AUDIT phase 진입 시 새로 create/split** (`createdByRun: true`). idle-pick 금지.
- 입력 SSOT = **`audit/inventory.md` only** (+ 필요 시 handoff 경로 목록). 이전 role transcript·plan 핑퐁 맥락에 의존 금지.
- ownership: **artifact-write-only**  
  - Claude → `audit/claude.md` 만  
  - Codex → `audit/codex.md` 만  
  - `inventory.md` / `improvements.md` / `reclaim-log.md` = **coordinator 단독**
- 소스·docs 수정 금지. audit 리뷰 **핑퐁 금지** (각 1회).
- AUDIT 시작 전: 불필요 edit 워커는 phase-end close 로 정리. Audit 진행 중 그 두 handle 만 유지.

**산출** (`.scv/state/$RUN_ID/audit/`, 기본 비커밋)

- `inventory.md` · `claude.md` · `codex.md` · `improvements.md` · `reclaim-log.md` (reclaim 후)

**improvements 항목 템플릿 (강제)**

```text
### IMP-n
- 현상: (이번 런 관측 + 증거 인용)
- 유지되는 동작:
- 개선 유형: time | stability | both
- 예상 효과:
- 적용 난이도: low | med
- 다음 런 적용: (한 줄 습관 / LESSONS — 재설계 아님)
```

관측 근거 없으면 제안 금지 → `observation-only`. evolution → **기각** 한 줄.

**BLOCKED:** inventory 필수 · review best-effort · **파괴적 reclaim 기본 스킵**.  
**audit skip:** 사용자 **명시 요청** + decisions 기록만 (overlay `audit: false` 일반 경로 금지).


#### 8b. Phase-end close + Mid-run Soft Reclaim (pack 1.3.7 / 1.3.2)

**새 pipeline step 아님.** coordinator 의 터미널 위생. 말미 `AUDIT → RECLAIM → CLOSING → FINAL` 을 대체하지 않는다.

| 종류 | 기본 | 용도 |
|------|------|------|
| **Phase-end close** | **기본 on** (1.3.7) | role 루프 terminal 확정 후 해당 handle 정리 → 다음 phase 는 fresh |
| **Mid-run soft reclaim** | 예외 pane / 죽은 탭 | hang 잔여·오생성 pane · evidence escrow 후 정리 |

##### 원칙 (Hard)

| # | 규칙 |
|---|------|
| 1 | SSOT = disk 산출 + orchestration state + git. pane scrollback 이 아님 |
| 2 | **Phase-end:** role 루프 terminal + 재발화 없음 → **close 기본**. **불확실·BLOCKED·미해결 `decision_gate`·unrouted lifecycle·same-role 라운드 진행 중** → 회수 금지 |
| 3 | `createdByRun: true` · `!preExisting` · **exact handle only**. coordinator/borrowed 금지 |
| 4 | 해당 handle 에 연결된 this-run task 가 **모두 terminal** · active dispatch 없음 (`dispatch-show --task`, per-task map) |
| 5 | worker_done 미소비 · open human gate → 회수 금지 |
| 6 | **AUDIT 중** audit 전용 fresh handle 2개 회수 금지. 다른 edit 워커는 AUDIT **전**에 close 완료 |
| 7 | fuzzy title · worktree-wide stop · **`reset --all`** · mid-run **`terminal close --tab`** 금지 (sibling/coordinator 오종료) |
| 8 | close 전 **evidence escrow** (비밀 제외 bounded preview/error/liveness digest + artifact paths) 없으면 회수 금지 |
| 9 | close 한 handle 을 이후 role/Audit 에 **부활 inject 금지** — 필요 시 새 create |

##### 회수 가능 시점 (eligibility — milestone 이름만 보지 말 것)

| 조건 | 회수( close ) 후보 | 유지 |
|------|-------------------|------|
| plan **승인+hash/scope/gate 동결** · plan 작성 Claude 재발화 없음 | **plan Claude** (phase-end) | **plan-review** 는 첫 implement batch 가 범위 확장 없이 gate PASS 할 때까지 (§3b 가능 시) |
| 첫 implement batch gate PASS · plan 역할 재발화 없음 | **plan-review Codex** (+ 아직 남은 plan Claude) | implement · (다음) code-review **새** handle |
| implement 배치 완료 · code-review 루프 시작 전 | implement 를 당장 안 쓰이면 close 가능 · **review-fix 미생성 상태 유지** | code-review 는 **fresh Claude** |
| code-review round 종료 확정 (P0+P1=0, 추가 round 불필요) | code-review Claude · review-fix Codex (phase-end) | release / **Audit 는 새 handle** |
| AUDIT 직전 | 모든 잔여 edit 워커 | **fresh** Claude 감사 + Codex 감사 only |
| AUDIT 중 / BLOCKED / incident 조사 | **금지**(audit 쌍) | audit 관련 pane |

same-role 핑퐁 중에는 “round 전용 핸들”이 아니라 **역할당 1 handle resume**.  
phase 가 바뀌면 **새 handle + file handoff** — task graph · scope-expansion · role command 로 판단.

##### 절차 (two-phase commit)

```text
1) eligibility + artifact MUST (§ 아래) 확인
2) tasksById 에서 terminalHandle==candidate 인 모든 task terminal + gate/lifecycle clean
3) run.json intent: status=mid_reclaiming, attemptId, expectedHandle, milestone  (아직 mid_reclaimed 아님)
4) evidence escrow → .scv/state/$RUN_ID/reclaim/midrun-log.md append
5) orca terminal close --terminal <exact-handle> --json   # mid-run: --tab 금지
6) terminal show/list 로 exact pane 부재 확인
7) 성공 시에만 status=mid_reclaimed, reclaimedAt, closeResult 확정
8) 실패 시 reclaim_failed + 실제 상태 · 자동 reclaim 중단 가능
```

사용자 수동 close 감지 시: registry reconcile 후 **자동 mid-run reclaim 중단** (stale registry 방지).

##### Artifact MUST (회수 전)

| 역할 | 최소 |
|------|------|
| plan | `docs/plans/….plan.md` + 로컬 커밋 + hash/scope freeze in decisions + worker_done 소비 |
| plan-review | `.scv/.../plan-review/*.md` + verdict + worker_done 소비 |
| implement | commits + quality-gate md + gate PASS 증거 + worker_done |
| code-review | `.scv/.../code-review/claude-round-N.md` + verdict |
| review-fix | gate + commits + worker_done |

미커밋 “워킹트리만 확정” 으로는 회수 금지.

##### Audit 과의 관계

- mid-run reclaim **자체는 Audit 을 막지 않음** (state/git/report SSOT).
- terminal-only hang/update/error 를 escrow 없이 닫으면 **stability Audit 이 어려워짐** → escrow 필수.
- inventory 에 Mid-run reclaim 절 권장: handles · milestone · artifacts · snapshot · reopen 이력.
- ship status 와 auditStatus 직교 (기존).

##### 안티패턴

- plan 승인 직후 plan-review 즉시 회수
- `mid_reclaimed` 를 close 전에 확정
- `--tab` / fuzzy / reset --all
- audit 핸들까지 pane 수 목표로 닫기
- evidence 없이 scrollback 의존 후 삭제


#### 9. Reclaim (Audit 직후 · close 직전 — 권장 순서)

```text
phase: RECLAIMING → allowlist 회수 → reclaim-log.md
```

**전체 종료 순서 (고정 · 권장)**

```text
release outcome
  → AUDIT → audit tasks terminal · decision_gate == 0
  → RECLAIM + reclaim-log
  → CLOSING → closed:true + 스냅샷
  → FINAL 1회
```

| 닫아도 됨 | 금지 |
|-----------|------|
| `createdByRun: true` · exact handle · task terminal · idle | coordinator 탭 · borrowed/`preExisting` handle 기본 종료 |
| orphan **waiter only** | 퍼지 매칭 · worktree-wide stop · **`reset --all`** · 불필요 **`--tab`**(탭 단위 오종료) |
| mid-run 에서 이미 `mid_reclaimed` 인 handle 은 skip | 미결 decision_gate 시 강제 종료 · sibling 불확실 시 추정 close |
| | AUDIT 미완 시 mid-run 잔여와 말미 RECLAIM 혼동 금지 — midrun-log 참고 |

불증이면 skip + `reclaimStatus: partial`. close 직전 `terminal show` 재검증.

#### 10. Run close · FINAL

```text
RUNNING → AUDIT → RECLAIMING → CLOSING → closed:true → FINAL
```

ship: `SUCCESS` | `SUCCESS_WITH_ACCEPTED_RISK` | `READY_TO_PUSH` | `BLOCKED`  
직교: `auditStatus`, `reclaimStatus` (`complete|partial|failed|skipped`)

**close 전 불변조건**

1. ship + audit this-run task terminal (또는 abandoned)
2. **미해결 human decision_gate == 0**
3. HEAD · gate 증거 일치 (해당 시)
4. audit/reclaim 경로 기록
5. `closedAt`, ship status, HEAD, task/dispatch/terminal 스냅샷

`run.json`: `phase: FINAL`, `closed: true`, `status`, `auditStatus`, `reclaimStatus`.  
FINAL 1회 — audit/reclaim 요약을 **위험 및 다음 단계** 등에 포함.

**Late mail (closed 후)**

| 이벤트 | 처리 |
|--------|------|
| completed task 중복 heartbeat / worker_done | silent dedupe · 사용자 고지 0 |
| 미해결 decision_gate | close 전 차단; resolve 미확인이면 **무시 금지** |
| 다른 런·새 dispatch | 구런 필터에 안 걸림 |
| FINAL 이후 잔여 메일 반복 고지 | **금지** |

## 문서 지도

### docs/ (SSOT · 커밋)

```text
docs/
  ARCHITECTURE.md
  plans/YYYY-MM-DD_<slug>.plan.md
  reviews/CR_YYYY-MM-DD_<slug>.md
  changelog/changelog_table.md
  changelog/YYYY-MM-DD_vX.Y.Z.md
  tests/TESTING.md
  memo/
```

### .scv/state/$RUN_ID/

```text
run.json          # 아래 스키마
brief/plan-brief.md
  brief/roadmap.md
  plan-review/codex.md
plan-refine/decisions.md
implement/batch-N.report.md
quality-gate/*.md
code-review/claude-round-N.md
release/push-status.md
audit/
  inventory.md
  claude.md
  codex.md
  improvements.md
  reclaim-log.md
```

#### run.json 필드 (pack 1.3.2)

| 구분 | 필드 |
|------|------|
| **필수** | `runId`, `phase`, `closed`, `resolvedDocsLanguage`, `thisRunTaskIds[]`, `completedTaskIds[]`, `terminals[]`(`handle,role,createdByRun,preExisting`), `tasksById` 또는 동등 map: `{ taskId: { activeDispatchId, terminalHandle, status } }` |
| **권장** | `phaseEnteredAt` / phase 전환 시각, `workerDoneAt`·`messageConsumedAt`·`nextDispatchAt`(handoff latency), `peerTaskIdsObserved[]`(관측 only), `activeWaitOwner`, `waitGeneration`, `lastConsumedMsgId`, `status`/`auditStatus`/`reclaimStatus`, mid-run: `terminals[].status` ∈ {active, mid_reclaiming, mid_reclaimed, reclaim_failed} |
| **주의** | 전역 단일 `activeDispatchId` 만 쓰면 `maxConcurrent: 2` 병렬에서 오판. 병렬 task duration **단순 합**으로 overhead 계산 금지 → critical-path/union 또는 handoff gap 사용. mid-run 은 close 검증 전 `mid_reclaimed` 확정 금지 |

**phase 시각 (필수에 가깝게 · audit/속도 정량화):** phase 전환 시 wall-clock 기록. FINAL 에 handoff latency 요약을 남길 수 있다.

## 성공 상태

| 상태 | 의미 |
|------|------|
| SUCCESS | plan 승인 · 최종 gate PASS · 리뷰 해소 · docs/버전 · (선택) push |
| SUCCESS_WITH_ACCEPTED_RISK | P1만 · **human** · 기록 완비 |
| READY_TO_PUSH | 로컬 완료 · **push 보류** (gate 실패 수용 상태 아님) |
| BLOCKED | P0 · gate fail · 잘못된 브랜치 · 중단 · P1 미승인 |

**P0는 절대 성공 처리하지 않는다.**

## FINAL 목차

1. 요약  
2. 단계별 결과  
3. 결정 로그  
4. 변경 파일  
5. 품질 게이트  
6. Git/릴리스 상태  
7. Docs updated  
8. 위험 및 다음 단계 (audit time/stability 개선 요약 · reclaimStatus · auditStatus 포함)  

## 실무 의무 · worker_done

**전송 CLI (정본 · Orca `orchestration send --help` Notes · orchestration 스킬과 동일):**

```bash
orca orchestration send \
  --to <coordinator_handle> \
  --type worker_done \
  --subject "<short status or REQUEST_CHANGES · 계획 검토>" \
  --body "<summary>" \
  --task-id <task_…> \
  --dispatch-id <ctx_…> \
  --files-modified "path/a,path/b" \
  --report-path ".scv/state/<RUN_ID>/…/report.md" \
  --json
```

| 규칙 | 내용 |
|------|------|
| 정본 | **structured flags only** (`--task-id` + `--dispatch-id` + …) |
| 금지 | `--payload` **와** structured flags **동시 사용** |
| 횟수 | 성공 `worker_done` **1회** · CLI 거절 시에만 플래그 수정 후 1회 재시도 |
| 엔진 | 상세 = orchestration 스킬 Agent Guidance |

**페이로드 내용(개념 · CLI 플래그로 실어 보냄):**

```json
{
  "type": "worker_done",
  "taskId": "<task_id>",
  "dispatchId": "<dispatch_id>",
  "status": "ok",
  "summary": "…",
  "gate": { "lint": 0, "result": "PASS" },
  "head": "<sha>",
  "reportPath": ".scv/state/<RUN_ID>/quality-gate/….md",
  "filesModified": ["…"]
}
```

review-only: `verdict` APPROVED | REQUEST_CHANGES | NEEDS_REWORK.  
실패 재시도로 거절된 send ≠ 이중 완료; 수락된 메시지가 1건이면 late/duplicate는 coordinator silent drop.

## 프로젝트 추가 규칙 (`.orca/scv.md`)

조율 방식은 전역 우선, 도메인/안전은 프로젝트 우선.

권장 필드:

| 필드 | 예 | 설명 |
|------|-----|------|
| `docsLanguage` | `ko` / `en` | 문서 프로즈 (기본 ko) |
| `versionPolicy` | `root-only` | monorepo bump 범위 |
| quality gates | `pnpm lint` 등 | 기본 동결 후보 |
| protected branches | `main` | |
| version file | `package.json` | |
| changelog / ARCHITECTURE 경로 | | |
| reclaim | `soft` 기본 | hard는 명시 시에만 (퍼지 close 금지) |

## Anti-patterns

- plan/코드 설계를 coordinator가 직접 작성
- Claude∥Codex 이중 full plan 병렬 작성 후 팀장 합본
- dispatch `--model` · meta 밖 모델 발명
- `git add -A` · `.scv/**` 커밋
- worker_done만 보고 gate PASS
- 보호 브랜치 커밋 · 태스크마다 자동 push
- P0를 SUCCESS_WITH_ACCEPTED_RISK · coordinator risk accept 자가승인
- 제목 퍼지로 task 재사용 · `task-create --title` (잘못된 플래그)
- Empty Goal을 오류로 반복 · **추정 ship 옵션 메뉴를 seed 없이 선제**
- seed 있는 메시지를 무시하고 다시 「무엇을 ship할까요?」만 물음
- bare `/scv` 만으로 orphan RUN_ID/state 생성
- 사용자 대면 진행 영어 only · `【scv · …】` 접두 · soft-wait/heartbeat 마다 대사 스팸
- human decision gate를 본문 선택지로만 묻고 AskUser 생략 · 같은 게이트 질문 2회
- bare `/scv` empty seed에 추정 AskUser 메뉴 선제 (free-text 1회 규칙 위반)
- 터미널 타이틀 영문 slug only · split 후 rename 누락 · 타이틀로 task 퍼지 매칭
- `--display-name` 영문 only (`scv-plan` 등) · `--task-title` 에 한글 phase 누락
- wait shell description 영문 only (`Rolling wait for plan worker_done` 등)
- `worker_done`/`heartbeat` 에 `--payload` + `--task-id` 등 structured 플래그 **동시 사용**
- 성공 `worker_done` 후 동일 dispatch에 두 번째 완료 send
- docs 프로즈를 resolved 언어와 다르게 커밋
- docs-only 런에서 기존 lint 위반을 자동으로 범위 확장
- plan-review skip / 재승인만으로 기술 리뷰 우회
- 병렬 `check --wait` · waiter 복구 시 worker/task kill
- wait `--types` 에 `heartbeat`/`status` 포함 (메일 스택·완료 오인)
- `check --wait` NDJSON 을 단일 `json.loads` 로 파싱 (keepalive Extra data)
- Orchestration Messages 미소비 스택 방치 · 같은 메일 반복 낭독하며 정지
- heartbeat 를 worker_done 처럼 취급
- completed/stale dispatchId 의 late worker_done 으로 파이프라인 재오픈
- closed 런의 **미해결** decision_gate 무시
- FINAL 후 late mail 반복 고지
- 워커마다 불필요 새 탭 create · **same-role 핑퐁마다** 새 세션 · 동일 role 중복 create
- **cross-role / cross-phase 세션 재사용** · idle Claude/Codex 를 Audit·다음 역할에 재할당 · command-compatible warm
- Codex update/shell/Ready 공회전에 같은 pane re-inject 반복
- recovery 시 coordinator + worker **이중 편집** (SSOT uncommitted 목록 없이)
- Hangul 비율만으로 문서 언어 gate 확정
- `READY_TO_PUSH`를 gate 실패 수용 상태로 오용
- `codex exec`에 인터랙티브 `-a never` 사용
- audit로 **파이프라인 고도화/재설계** 제안 (time/stability only)
- audit 전용 meta worker 추가 · audit 핑퐁 · **기존 plan/implement 세션에 audit inject**
- audit 실패로 ship SUCCESS를 BLOCKED로 강등
- reclaim 시 `reset --all` · 퍼지 handle close · borrowed pane 강제 종료
- FINAL 전에 audit/reclaim 없이 closed (사용자 명시 skip 제외)
- phase-end 인데 끝난 role 탭을 “나중 audit용”으로 방치
- RPC root `id` 를 taskId 로 사용 · split handle 경로 오인
- 고정 sleep liveness · 완료 후 빈 wait 창 반복
- 무타입 unread 로 미해결 decision_gate 유실
- same-batch implement∥code-review · plan∥plan-review 병렬
- maxConcurrent 무제한 상향 · post-inject 전면 삭제
