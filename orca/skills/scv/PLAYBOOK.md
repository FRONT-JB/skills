# scv Orchestration Mode (Orca) — Global

Grok = **coordinator**. Workers = **Grok/init + Claude/plan + Codex/plan-review + Codex/implement + Claude/code-review + Codex/review-fix + Grok/release**.
When workers finish, the coordinator produces a **FINAL** synthesis.

Mode type: **supervised** — coordinator injects lifecycle, waits for worker_done (`check --wait`), then FINAL.

- 엔진: orchestration 스킬 (`orca orchestration …`)
- 이 파일: 그 엔진 위에 얹는 **MyMode 규칙** (행동 계약 **SSOT**)
- 홈: `$HOME/.orca/scv/`
- 템플릿: `$HOME/.orca/scv/templates/`
- 프로젝트 오버레이: `.orca/scv.md` (있으면) · `AGENTS.md` (있으면)
- 런타임 상태(레포 내부): `.scv/state/$RUN_ID/` (**gitignore**, 커밋 금지)
- packVersion: `meta.json` 의 `packVersion`

## 사용자 대면 언어 (필수 · 한글)

coordinator가 사용자 채팅에 쓰는 **진행 과정·질문·FINAL은 한국어**.

| 허용 (영문 유지) | 반드시 한글 |
|------------------|------------|
| `worker_done`, role, task id, 파일 경로, CLI 로그 인용 | 단계 전환, 대기 이유, 완료/실패 요약, decision_gate, FINAL 본문 |

단계 안내 예시:

- `【scv · plan 작성】 Claude 작업 중. heartbeat 수신 — 완료 신호(worker_done)까지 대기합니다.`
- `【scv · plan 검토】 plan 산출물 확인 완료. Codex plan-review를 dispatch 합니다.`

금지 예: `Heartbeat received…`, `Plan worker_done received…` 같은 **진행 내레이션 전부 영어**.

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
command -v grok codex claude
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
| coordinator | grok | — | (세션) | 인터뷰·브리프·dispatch·gate 판정·FINAL | FINAL · decisions | plan/코드 **설계 본문** 미작성 |
| init | grok | edit | `grok -m grok-4.5 --reasoning-effort high` | docs 골격·ARCHITECTURE 초안 | docs/** scaffolding | 소스 수정 금지 · 사용자 승인 후만 · 템플릿 참조 |
| plan | claude | edit | `claude --model opus --dangerously-skip-permissions` | plan.md 작성·수정 | `docs/plans/YYYY-MM-DD_<slug>.plan.md` | 코드 스니펫 금지 · gate·scope manifest 필수 |
| plan-review | codex | review-only | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` | plan 검증 | `.scv/.../plan-review/codex.md` | 파일 수정 금지 |
| implement | codex | edit | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | 배치 구현 · 로컬 커밋 · gate | 코드 + commits + gate 증거 | feature branch · scope 준수 |
| code-review | claude | review-only | `claude --model opus --dangerously-skip-permissions` | 코드 리뷰 | `.scv/.../code-review/claude-round-N.md` | 수정 금지 |
| review-fix | codex | edit | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` | 리뷰 반영 · gate | 코드 + commits + gate | P0/P1 범위만 |
| release | grok | edit | `grok -m grok-4.5 --reasoning-effort high` | 7a docs · 7b push 확인 | changelog·CR·ARCHI·push-status | 코드 설계 본문 금지 · push는 확인 후 |

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

### 1) task-create

```bash
orca orchestration task-create \
  --task-title "[scv:$RUN_ID] <phase>-<short>" \
  --display-name "<role-title>" \
  --spec "<full task body including resolvedDocsLanguage directive>" \
  --json
```

**주의:** 플래그는 `--task-title` (not `--title`). `--spec` 필수.  
**이번 런 task-create id만 dispatch.** 제목 퍼지 매칭 금지.

### 2) 터미널 레이아웃 — **split pane 우선**

| 순서 | 동작 |
|------|------|
| 1 | **첫 워커만** `terminal create` |
| 2+ | **`terminal split`** + `rename` |
| 예외 | split 실패 복구 1회 · 사용자 “탭으로” · 다른 worktree |

- direction: 기본 `vertical` · 리뷰 쌍 `horizontal`
- **핑퐁 세션 재사용:** 역할당 handle 1개. round 2+ = **같은 handle 재dispatch**. 라운드마다 새 세션 금지.

### 3) dispatch · wait (단일 소유자)

```bash
orca orchestration dispatch --task <task_id> --to <handle> --inject --json
# 단일 소유자 · 60–90s 롤링 · soft timeout ≠ 하드 abort
# heartbeat 를 --types 에 넣지 말 것 (완료로 오인·메일 스택 유발)
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
| 스택 정리 | UI에 Orchestration Messages 가 쌓이면 `check --unread` 로 비우고 진행. 같은 메일을 반복 낭독하며 정지 금지 |
| timeout | soft · 실패 아님 → task-list + terminal show + artifact 확인 후 **중복 dispatch 없이** 재대기 |
| shell background | **waiter 프로세스만** 정리 후 새 wait. **worker terminal / orchestration task kill 금지** |
| hang | role×task 당 재시도 **1회** 후 decision_gate |
| late done | completed task 의 late `worker_done` **무시** (재오픈·재대기 금지) |
| post-inject | 45–90s liveness (도구/프리뷰 성장). spinner-only 면 hung recovery |
| 사용자 안내 | 한글 한 줄: `【scv · 대기】 plan 워커 작업 중 (heartbeat≠완료). worker_done 대기.` |

선택 상태 필드(권장): `activeWaitOwner`, `expectedTaskIds`, `waitGeneration`, `lastConsumedMsgId`.

**안티패턴 (메일 스택)**

- wait 루프 2개 이상
- `--types` 에 heartbeat 포함
- 라운드마다 새 세션 create → inject 폭증
- worker_done 을 읽지 않고 “메시지 있음” 만 반복 표시
- 미소비 메일 N건을 한 화면에 쌓아 두고 파이프라인 정지

### 4) 파이프라인 단계

#### 0. init (선택)

- 조건: `docs/ARCHITECTURE.md` 또는 docs 골격 부재
- 사용자 scaffolding 승인 후 · docs only · `templates/ARCHITECTURE.ko.md` 참조 (resolved ko일 때)
- 워커: grok-init

#### 1. plan 인터뷰 (coordinator)

Goal → gstack 인터뷰 → brief: `.scv/state/$RUN_ID/brief/plan-brief.md`  
인터뷰 중 plan 본문·코드 작성 금지.

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
- 승인 시: plan 로컬 커밋 + **content hash + scope manifest + gate 동결** → `plan-refine/decisions.md`
- 승인 후 plan 본문/hash/scope/gate 변경: 승인 무효 → **Codex plan-review 재통과** → 재커밋 + 재동결.  
  **재승인만으로 기술 리뷰 우회 금지. skip 경로 없음.**
- 사용자 plan 승인 후 implement

#### 3b. 범위 확장 decision_gate

| 종류 | 승인자 |
|------|--------|
| 구현 세부 (scope 안 도구 선택) | coordinator 가능 |
| **범위 확장** (paths/파일수/종류/gate 이탈) | **사용자 필수** |
| P1 risk accept | **사용자 only** |

**범위 확장 판정:** 승인 scope manifest의 paths · 파일 수 상한 · 변경 종류 · frozen gate 중 **하나라도** 벗어나면 즉시 중단.

사용자 gate 페이로드: 원인 · 추가 범위 · 예상 파일 수 · 대안  
(`원범위 완료` / `후속 분리` / `현 런 편입`) · 위험.

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

- **기본:** grok-release 워커 dispatch (task/dispatch/worker_done 증거)
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

**워커**

- **meta에 audit 전용 역할 추가 금지** (workers 7 유지).
- 기존 유휴 Claude / Codex handle에 **이번 런 새 task-create** 로 재dispatch.
- handle 없으면 최소 create/split 1회 · `createdByRun: true` 기록.
- ownership: **artifact-write-only**  
  - Claude → `audit/claude.md` 만  
  - Codex → `audit/codex.md` 만  
  - `inventory.md` / `improvements.md` / `reclaim-log.md` = **coordinator 단독**
- 소스·docs 수정 금지. audit 리뷰 **핑퐁 금지** (각 1회).

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
| orphan **waiter only** | 퍼지 매칭 · worktree-wide stop · **`reset --all`** |
| | 미결 decision_gate 시 강제 종료 · sibling 불확실 시 추정 close |

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
run.json          # phase, closed, resolvedDocsLanguage, status, auditStatus, reclaimStatus, terminals[]
brief/plan-brief.md
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
  "files": ["…"]
}
```

review-only: `verdict` APPROVED | REQUEST_CHANGES | NEEDS_REWORK.

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

- plan/코드 설계를 Grok가 직접 작성
- Claude∥Codex 이중 full plan 병렬 작성 후 팀장 합본
- dispatch `--model` · meta 밖 모델 발명
- `git add -A` · `.scv/**` 커밋
- worker_done만 보고 gate PASS
- 보호 브랜치 커밋 · 태스크마다 자동 push
- P0를 SUCCESS_WITH_ACCEPTED_RISK · Grok risk accept 자가승인
- 제목 퍼지로 task 재사용 · `task-create --title` (잘못된 플래그)
- Empty Goal을 오류로 반복 · **추정 ship 옵션 메뉴를 seed 없이 선제**
- seed 있는 메시지를 무시하고 다시 「무엇을 ship할까요?」만 물음
- bare `/scv` 만으로 orphan RUN_ID/state 생성
- 사용자 대면 진행 영어 only
- docs 프로즈를 resolved 언어와 다르게 커밋
- docs-only 런에서 기존 lint 위반을 자동으로 범위 확장
- plan-review skip / 재승인만으로 기술 리뷰 우회
- 병렬 `check --wait` · waiter 복구 시 worker/task kill
- wait `--types` 에 `heartbeat`/`status` 포함 (메일 스택·완료 오인)
- Orchestration Messages 미소비 스택 방치 · 같은 메일 반복 낭독하며 정지
- heartbeat 를 worker_done 처럼 취급
- closed 런의 **미해결** decision_gate 무시
- FINAL 후 late mail 반복 고지
- 워커마다 새 탭 create · 핑퐁마다 새 세션
- Hangul 비율만으로 문서 언어 gate 확정
- `READY_TO_PUSH`를 gate 실패 수용 상태로 오용
- `codex exec`에 인터랙티브 `-a never` 사용
- audit로 **파이프라인 고도화/재설계** 제안 (time/stability only)
- audit 전용 meta worker 추가 · audit 핑퐁
- audit 실패로 ship SUCCESS를 BLOCKED로 강등
- reclaim 시 `reset --all` · 퍼지 handle close · borrowed pane 강제 종료
- FINAL 전에 audit/reclaim 없이 closed (사용자 명시 skip 제외)
