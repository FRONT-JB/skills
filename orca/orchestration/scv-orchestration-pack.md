# scv 조율 모드 팩 (사용자 맞춤)

> Orca 조율 스튜디오에서 **이 사용자가 만든** 설정입니다.
> 아래를 **이 컴퓨터**의 `$HOME/.orca/scv/` 에 저장하세요.
>
> **버전:** 2026-07-20 v8.0 (packVersion **1.3.1**)  
> **변경 요약:** RPC id verb paths · wait JSON-sequence parse · per-task activeDispatch · peer soft-warn · wait·liveness fusion · handoff latency · terminal next-role reuse · SKILL SSOT · run.json schema · step-preserving speed (파이프라인 단계 불변)
>
> 파일 SSOT: `$HOME/Desktop/jb/skills/orca/skills/scv/` → install `$HOME/.orca/scv/` · Grok mirror `$HOME/.grok/skills/scv/SKILL.md`

## 이 팩 요약
| 항목 | 값 |
|------|-----|
| 표시 이름 | scv |
| packVersion | 1.3.1 |
| 팀장 | Grok · supervised |
| 교차 검증 | plan Claude/Codex · code Codex/Claude |
| 문서 언어 | 기본 ko (`resolvedDocsLanguage`) |
| Intake | **prompt-first** (옵션 메뉴 선제 금지) |
| Wait | single owner · JSON-sequence parse · wait·liveness fusion · per-task dispatchId |
| Terminal | first create + split · idempotent reuse · next-role only |
| 말미 | AUDIT → RECLAIM → CLOSING → FINAL |
| Audit 초점 | time / stability only · 고도화 금지 |
| 상태 루트 | `.scv/state/$RUN_ID/` (gitignore) |

### 파이프라인

```text
preflight → seed/interview → plan… → release
  → AUDIT (inventory + Claude∥Codex · time|stability)
  → RECLAIM (createdByRun)
  → CLOSING → FINAL
```

## 설치

```bash
rsync -a --delete "$HOME/Desktop/jb/skills/orca/skills/scv/" "$HOME/.orca/scv/"
mkdir -p "$HOME/.grok/skills/scv"
cp "$HOME/.orca/scv/SKILL.md" "$HOME/.grok/skills/scv/SKILL.md"
"$HOME/.orca/scv/scv-selfcheck.sh"
```

---

# PLAYBOOK (SSOT copy)

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
- packVersion: `meta.json` 의 `packVersion` (현재 **1.3.1** — RPC id 계약 · wait/pretty 파서 · per-task dispatch · peer soft-warn · wait·liveness fusion · handoff latency · terminal reuse 강제)

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
| 1 | **첫 워커만** `terminal create` |
| 2+ | **`terminal split`** + `rename` |
| 예외 | split 실패 복구 1회 · 사용자 “탭으로” · 다른 worktree |

- direction: 기본 `vertical` · 리뷰 쌍 `horizontal`
- **핑퐁 세션 재사용:** 역할당 handle 1개. round 2+ = **같은 handle 재dispatch**. 라운드마다 새 세션 금지.
- **Idempotent create (필수):** 동일 `(title, role)` 이 **alive** 이면 재사용. dead 슬롯만 교체 생성. create 직후 `terminal list/show` 로 live handle **1개** 확정 후 그 handle 만 dispatch/read/message routing. dead pane 은 completion authority 금지.
- 중복 first-create 금지 (이중 탭 create 후 하나만 쓰기 금지 — 즉시 하나로 합치거나 dead 마킹).
- **속도 · 재사용 (1.3.1):** 라운드마다 새 탭 create 금지(이미 규칙). **바로 다음 역할**만 command-compatible idle handle 로 준비. 먼 미래 역할 warm pool 금지(stale/Codex update 위험). implement 와 review/fix 는 **meta command 가 다르면** 같은 Codex process 로 퉁치지 말 것.
- create/split 직후 **직렬 tui-idle 다중 wait 남발 지양** — 필요 pane 을 bounded `terminal list/show` sweep 으로 readiness 확인 가능. inject 는 단계 도달 후에만.

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
| 사용자 안내 | 한글 한 줄: `【scv · 대기】 plan 워커 작업 중 (heartbeat≠완료). worker_done 대기.` |

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
| 역할 핸들 재사용 · 다음 역할만 준비 | 먼 미래 warm pool · 라운드마다 새 탭 |
| audit/리뷰 쌍 maxConcurrent=2 병렬 | plan∥plan-review, same-batch implement∥code-review |
| 승인 대기 중 read-only 준비(branch/gate dry/다음 터미널) · **inject 금지** | 승인 전 implement dispatch |
| handoff latency 기록 (`workerDoneAt`→`consumedAt`→`nextDispatchAt`) | 병렬 task duration 단순 합으로 overhead 음수 계산 |

사람 승인·워커 사고 시간은 줄이지 않는다. 줄이는 대상은 **코디 오버헤드·공회전·직렬 낭비**.

**안티패턴 (메일 스택 · 대기)**

- wait 루프 2개 이상
- `--types` 에 heartbeat 포함
- NDJSON 전체를 단일 `json.loads`
- RPC envelope 루트 `id` 를 taskId 로 사용 · `terminal split` 을 `result.terminal.handle` 로 오파싱
- completed/stale `dispatchId` 메일을 현재 완료로 처리 · 전역 단일 activeDispatchId 로 병렬 정상 dispatch 를 straggler 처리
- active-dispatch stuck 에 같은 pane re-inject 반복
- 라운드마다 새 세션 create → inject 폭증 · 먼 미래 역할 warm pool
- worker_done 을 읽지 않고 “메시지 있음” 만 반복 표시
- 미소비 메일 N건을 한 화면에 쌓아 두고 파이프라인 정지
- 무타입 unread drain 후 decision_gate/다른 런 worker_done 유실
- 고정 sleep 60 후 show · 완료 후에도 rolling wait 창을 계속 염
- task-list `completed` 만 보고 gate 증거 없이 다음 단계 전진

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
run.json          # 아래 스키마
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

#### run.json 필드 (pack 1.3.1)

| 구분 | 필드 |
|------|------|
| **필수** | `runId`, `phase`, `closed`, `resolvedDocsLanguage`, `thisRunTaskIds[]`, `completedTaskIds[]`, `terminals[]`(`handle,role,createdByRun,preExisting`), `tasksById` 또는 동등 map: `{ taskId: { activeDispatchId, terminalHandle, status } }` |
| **권장** | `phaseEnteredAt` / phase 전환 시각, `workerDoneAt`·`messageConsumedAt`·`nextDispatchAt`(handoff latency), `peerTaskIdsObserved[]`(관측 only), `activeWaitOwner`, `waitGeneration`, `lastConsumedMsgId`, `status`/`auditStatus`/`reclaimStatus` |
| **주의** | 전역 단일 `activeDispatchId` 만 쓰면 `maxConcurrent: 2` 병렬에서 오판. 병렬 task duration **단순 합**으로 overhead 계산 금지 → critical-path/union 또는 handoff gap 사용 |

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
- `check --wait` NDJSON 을 단일 `json.loads` 로 파싱 (keepalive Extra data)
- Orchestration Messages 미소비 스택 방치 · 같은 메일 반복 낭독하며 정지
- heartbeat 를 worker_done 처럼 취급
- completed/stale dispatchId 의 late worker_done 으로 파이프라인 재오픈
- closed 런의 **미해결** decision_gate 무시
- FINAL 후 late mail 반복 고지
- 워커마다 새 탭 create · 핑퐁마다 새 세션 · 동일 role 중복 create
- Codex update/shell/Ready 공회전에 같은 pane re-inject 반복
- recovery 시 coordinator + worker **이중 편집** (SSOT uncommitted 목록 없이)
- Hangul 비율만으로 문서 언어 gate 확정
- `READY_TO_PUSH`를 gate 실패 수용 상태로 오용
- `codex exec`에 인터랙티브 `-a never` 사용
- audit로 **파이프라인 고도화/재설계** 제안 (time/stability only)
- audit 전용 meta worker 추가 · audit 핑퐁
- audit 실패로 ship SUCCESS를 BLOCKED로 강등
- reclaim 시 `reset --all` · 퍼지 handle close · borrowed pane 강제 종료
- FINAL 전에 audit/reclaim 없이 closed (사용자 명시 skip 제외)
- RPC root `id` 를 taskId 로 사용 · split handle 경로 오인
- 고정 sleep liveness · 완료 후 빈 wait 창 반복
- 무타입 unread 로 미해결 decision_gate 유실
- same-batch implement∥code-review · plan∥plan-review 병렬
- maxConcurrent 무제한 상향 · post-inject 전면 삭제


---

# meta.json

```json
{
  "modeName": "scv",
  "displayName": "scv",
  "packVersion": "1.3.1",
  "coordination": "supervised",
  "coordinator": {
    "agent": "grok"
  },
  "maxConcurrent": 2,
  "worktreePolicy": "active",
  "waitTimeoutMs": 900000,
  "waitRollingTimeoutMs": 90000,
  "implementSoftBudgetMs": 1800000,
  "postInjectLivenessMs": 60000,
  "postInjectLivenessMode": "wait-fusion",
  "hangRetryMaxPerRole": 1,
  "taskTitlePrefix": "[scv:$RUN_ID]",
  "stateRoot": ".scv/state/$RUN_ID/",
  "planPathPattern": "docs/plans/YYYY-MM-DD_<slug>.plan.md",
  "templatesDir": "$HOME/.orca/scv/templates/",
  "defaultDocsLanguage": "ko",
  "skillCanonical": "$HOME/.orca/scv/SKILL.md",
  "skillMirror": "$HOME/.grok/skills/scv/SKILL.md",
  "wait": {
    "types": "worker_done,escalation,decision_gate",
    "forbidHeartbeatInWaitTypes": true,
    "singleOwner": true,
    "parseMode": "ndjson-linewise-or-json-sequence",
    "skipKeepaliveKeys": ["_keepalive", "_heartbeat"],
    "stragglerDrop": true,
    "requireActiveDispatchIdMatch": true,
    "perTaskActiveDispatch": true,
    "completionRequiresOkAndMessages": true,
    "forbidFixedSleepBeforeWait": true,
    "rollingVsBudget": "90000 rolling window; 900000 meta budget guide — do not block one CLI call for 15m"
  },
  "rpcIdPaths": {
    "task": "result.task.id",
    "dispatch": "result.dispatch.id",
    "terminalCreate": "result.terminal.handle",
    "terminalSplit": "result.split.handle",
    "sendMessage": "result.message.id",
    "checkMessages": "result.messages[].id",
    "forbidRootIdAsTaskId": true
  },
  "speed": {
    "stepPreservingOnly": true,
    "waitLivenessFusion": true,
    "terminalReuseNextRoleOnly": true,
    "forbidFarWarmPool": true,
    "forbidPlanParallelReview": true,
    "forbidSameBatchImplementParallelReview": true,
    "handoffLatencyFields": [
      "workerDoneAt",
      "messageConsumedAt",
      "nextDispatchAt"
    ],
    "userGatePrepReadOnly": true
  },
  "audit": {
    "requiredAttempt": true,
    "shipStatusOrthogonal": true,
    "focus": [
      "time",
      "stability"
    ],
    "forbidEvolution": true,
    "noDedicatedMetaWorkers": true,
    "reviewsPerAgent": 1,
    "pingPong": false,
    "stateDir": ".scv/state/$RUN_ID/audit/",
    "preferParallelClaudeCodex": true
  },
  "reclaim": {
    "order": "after-audit-before-close",
    "pipeline": "AUDIT → RECLAIM → CLOSING → FINAL",
    "allowOnlyCreatedByRun": true,
    "forbidResetAll": true,
    "skipDestructiveOnBlocked": true
  },
  "intake": {
    "mode": "prompt-first",
    "forbidPrematureOptionMenu": true,
    "runIdAfterNonEmptySeed": true
  },
  "finalSections": [
    "요약",
    "단계별 결과",
    "결정 로그",
    "변경 파일",
    "품질 게이트",
    "Git/릴리스 상태",
    "Docs updated",
    "위험 및 다음 단계"
  ],
  "triggers": [
    "scv",
    "/scv",
    "scv-harness"
  ],
  "workers": [
    {
      "role": "init",
      "agent": "grok",
      "command": "grok -m grok-4.5 --reasoning-effort high",
      "ownership": "edit"
    },
    {
      "role": "plan",
      "agent": "claude",
      "command": "claude --model opus --dangerously-skip-permissions",
      "ownership": "edit"
    },
    {
      "role": "plan-review",
      "agent": "codex",
      "command": "codex -m gpt-5.6-sol -c model_reasoning_effort=\"high\" -a never -s danger-full-access",
      "ownership": "review-only"
    },
    {
      "role": "implement",
      "agent": "codex",
      "command": "codex -m gpt-5.6-sol -c model_reasoning_effort=\"xhigh\" -a never -s danger-full-access",
      "ownership": "edit"
    },
    {
      "role": "code-review",
      "agent": "claude",
      "command": "claude --model opus --dangerously-skip-permissions",
      "ownership": "review-only"
    },
    {
      "role": "review-fix",
      "agent": "codex",
      "command": "codex -m gpt-5.6-sol -c model_reasoning_effort=\"high\" -a never -s danger-full-access",
      "ownership": "edit"
    },
    {
      "role": "release",
      "agent": "grok",
      "command": "grok -m grok-4.5 --reasoning-effort high",
      "ownership": "edit"
    }
  ],
  "crossReview": {
    "plan": {
      "write": "claude/plan",
      "review": "codex/plan-review"
    },
    "code": {
      "write": "codex/implement",
      "review": "claude/code-review",
      "fix": "codex/review-fix"
    }
  },
  "notes": {
    "claudeModels": "plan and code-review use opus + --dangerously-skip-permissions (verified alias pattern). Do not invent full model ids after hang.",
    "codexFlags": "Orca terminal workers: always -a never -s danger-full-access. implement=xhigh; review/fix=high. codex exec (non-interactive): do NOT pass -a; use -s danger-full-access --dangerously-bypass-approvals-and-sandbox.",
    "codexStuck": "Self-update / shell prompt / Ready with no tools after inject = hung. Do not re-inject into active-dispatch-stuck pane. task-update ready → fresh terminal → new dispatch. Max 1 hang recovery per role×task.",
    "paths": "Use $HOME or repo-relative paths. Never commit absolute /Users/<name>/ paths. Never stage .scv/**.",
    "sourcePack": "$HOME/Desktop/jb/skills/orca/orchestration/scv-orchestration-pack.md",
    "skillInstall": "Canonical SKILL at $HOME/.orca/scv/SKILL.md; mirror to $HOME/.grok/skills/scv/SKILL.md (byte-identical preferred). selfcheck verifies both.",
    "userFacingLanguage": "Korean for progress/questions/FINAL; English tokens OK for roles/paths/ids/CLI",
    "docsLanguage": "Default ko for committed docs prose. Resolve: user directive > .orca/scv.md docsLanguage > meta defaultDocsLanguage. Inject resolved directive into worker specs; do not hardcode Korean when override is en.",
    "runClose": "RUNNING→AUDIT→RECLAIMING→CLOSING→closed→FINAL. Block close if open human decision_gate. Late completed heartbeats/worker_done: silent dedupe by completedTaskIds+dispatchId. Unresolved decision_gate must not be dropped.",
    "scopeExpansion": "Leave approved scope manifest → stop. In-run expand: user approve + plan patch + Codex plan-review re-pass + re-freeze. No skip. Baseline lint FAIL unrelated to docs-only: record only, do not auto-expand.",
    "taskCreateCli": "orca orchestration task-create --task-title ... --spec ... (not --title). taskId = result.task.id only — never root envelope id.",
    "rpcIdContract": "task=result.task.id; dispatch=result.dispatch.id; terminal create=result.terminal.handle; terminal split=result.split.handle; check messages=result.messages[].id. Root id is RPC UUID.",
    "intake": "Prompt-first: consume user message as seed; no premature estimated option menu. Bare /scv → free-text once. RUN_ID only after non-empty seed.",
    "audit": "Post-release audit: time/stability only, keep pipeline ops. No evolution redesign. No dedicated meta workers—reuse idle Claude/Codex handles with new task ids. Each agent 1 review, no ping-pong. Prefer parallel Claude∥Codex. Ship status orthogonal to auditStatus. Artifacts under .scv/state/$RUN_ID/audit/ (gitignore).",
    "reclaim": "After audit, before close: reclaim only createdByRun exact handles + orphan waiters. Never reset --all, never fuzzy match, keep coordinator tab and borrowed handles. BLOCKED: skip destructive reclaim by default.",
    "waitMailStack": "Exactly one check --wait; types=worker_done,escalation,decision_gate only; never heartbeat in wait types; consume one msg then act; drain with type/run routing (never drop unresolved decision_gate); heartbeat≠completion; timeout=soft recheck; parse wait as JSON sequence (skip keepalive); drop straggler lifecycle for non-active per-task dispatchId",
    "waitLivenessFusion": "No fixed sleep before wait. Open check --wait after inject; on first soft timeout recheck inject-delta; hung only at Ready-no-tools≥90s etc. Early healthy≠done. No early-hung.",
    "terminalIdempotent": "first create then split+rename; reuse alive (title,role); one live handle per role; dead pane never completion authority; warm only next role; no far-future pool",
    "recoverySsot": "On implement resume after hang/coordinator-exception: task spec must list uncommitted SSOT paths; single edit owner only",
    "speed": "Step-preserving only. Kill coord overhead (parser miss empty waits, fixed sleep, tab churn, serial audit). Never skip review/gates; never same-batch implement∥review; never raise maxConcurrent without evidence.",
    "peerRuns": "Soft-observe other [scv:*] tasks; do not assume shared worktree from title alone (task-list has no branch).",
    "changelog_1_3_0": "2026-07-19: coordination hygiene — NDJSON wait parse, straggler drop, Codex stuck recovery, terminal idempotent, recovery SSOT, phaseEnteredAt recommended",
    "changelog_1_3_1": "2026-07-20: RPC id verb paths; wait JSON-sequence parse; per-task activeDispatch; peer soft-warn; unread routing; wait·liveness fusion; handoff latency; terminal next-role reuse; SKILL SSOT paths; run.json schema; speed rules without step changes"
  }
}

```

---

# SKILL.md

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
| meta | `$HOME/.orca/scv/meta.json` (`packVersion` **1.3.1**) |
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


---

# LESSONS.md

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

- **RPC id contract (1.3.1):** task=`result.task.id`; dispatch=`result.dispatch.id`; terminal create=`result.terminal.handle`; split=`result.split.handle`. Never root envelope `id`.
- **Wait parse (1.3.1):** JSON sequence / line-wise + multi-value; skip keepalive; complete only `ok===true` with `result.messages` array; no whole-buffer loads.
- **Per-task activeDispatchId** when maxConcurrent>1; never single global id for straggler filter.
- **Unread drain:** route by type/taskId/dispatchId; never drop unresolved decision_gate.
- **Wait·liveness fusion:** no fixed sleep 60; open wait after inject; early healthy≠done; no early-hung (90s Ready-no-tools).
- **Speed:** step-preserving only; reuse terminals (next role only); no empty wait after consumed worker_done; measure handoff latency not raw sum of parallel task durations.

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


- 2026-07-20 — **pack 1.3.1 (logic+speed, step-preserving):** (1) task-create root UUID mistaken for task id → document `result.task.id` only. (2) `terminal split` returns `result.split.handle` not `result.terminal.handle`. (3) init wait-1 keepalive+pretty mixed → whole-buffer parse miss → wait-2..12 empty ~10–16m after complete — JSON-sequence parse + stop opening wait after consumed worker_done. (4) fixed sleep 55–60 before wait → wait·liveness fusion. (5) multi-run same branch confuses UI — peer soft-warn; task-list has no worktree. (6) untyped unread can consume other-run lifecycle/gates — route messages. (7) maxConcurrent=2 needs per-task activeDispatchId. (8) speed: no review skip / no same-batch implement∥review; warm next role only; handoff latency fields. Dual Claude∥Codex re-verify of logic+speed drafts.

<!-- Append: YYYY-MM-DD — what failed, what fixed, command that worked -->


---

# prompts/quick-command.txt

```text
scv mode (user mode). Read and follow $HOME/.orca/scv/PLAYBOOK.md, $HOME/.orca/scv/meta.json, $HOME/.orca/scv/LESSONS.md, and the orchestration skill. If this project has .orca/scv.md or .orca/PLAYBOOK.md, also follow it as project overlay. You are Grok coordinator: supervised feature-shipping DAG (prompt-first interview → Claude plan → Codex plan-review ↔ Claude fix → implement batches → gate → Claude code-review ↔ Codex fix → release → post-run AUDIT (time/stability only, keep ops) → RECLAIM this-run workers → FINAL). Coordination=supervised: inject lifecycle; single check --wait; hang retry max 1 per role; dispatch only this-run task ids. RPC ids: task=result.task.id; dispatch=result.dispatch.id; terminal create=result.terminal.handle; split=result.split.handle — never root envelope id. Wait: types=worker_done,escalation,decision_gate only (never heartbeat); consume 1 msg then act; drain unread with type/run routing (never drop unresolved decision_gate); heartbeat≠completion; parse check --wait as JSON sequence (skip _keepalive; ok===true + result.messages only); drop late lifecycle unless taskId+per-task dispatchId match this-run; after consumed worker_done do not open empty wait windows. Wait·liveness fusion: no fixed sleep 60; open wait after inject; early healthy≠done; Ready-no-tools≥90s=hung — no early-hung; do not re-inject stuck active-dispatch pane; fresh terminal + new dispatch. Terminal: first create then split+rename; idempotent reuse alive (title,role); one live handle per role; warm next role only. Recovery: uncommitted SSOT paths in resume spec; single edit owner. Max concurrent: 2 with per-task activeDispatchId. Speed: step-preserving only — kill coord overhead (parser miss, fixed sleep, tab churn); never skip review/gates; never same-batch implement∥code-review. Workers: grok/init:{grok -m grok-4.5 --reasoning-effort high} ; claude/plan:{claude --model opus --dangerously-skip-permissions} ; codex/plan-review:{codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access} ; codex/implement:{codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access} ; claude/code-review:{claude --model opus --dangerously-skip-permissions} ; codex/review-fix:{codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access} ; grok/release:{grok -m grok-4.5 --reasoning-effort high}. Prefer horizontal for review pairs. User-facing Korean. Docs prose default Korean (resolvedDocsLanguage). Intake: consume user prompt first — no premature estimated option menu; bare trigger → free-text once; RUN_ID after non-empty seed. Close order: AUDIT → RECLAIM → CLOSING → FINAL. Audit under .scv/state/$RUN_ID/audit/ (time|stability only, no evolution, reuse Claude/Codex handles, prefer parallel). Reclaim createdByRun only; never reset --all. Goal (optional — from user prompt; ask free-text if missing):

```
