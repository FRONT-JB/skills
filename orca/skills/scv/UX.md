# scv 사용자 대면 연출 (표시 전용)

**표시 SSOT.** lifecycle / wait / RPC / reclaim 동작은 `PLAYBOOK.md` + orchestration 스킬.  
이 파일은 채팅·탭·task 라벨·wait shell description 만 담당. `run.json`에 scv_line 저장 금지.

pack: see `meta.json` `ui` · `packVersion` **1.3.5**

## 개요

coordinator가 사용자 채팅에 쓰는 **진행 과정·질문·FINAL은 한국어**.

| 허용 (영문 유지) | 반드시 한글 |
|------------------|------------|
| `worker_done`, role, task id, 파일 경로, CLI 로그 인용, **`scv_line` 인용** | 단계 전환, 대기 이유, 완료/실패 요약, decision_gate, FINAL 본문, **task display-name, wait shell description, 터미널 타이틀** |

### 진행 내레이션 포맷 (필수 · pack 1.3.4 · 한 줄)

**한 줄** 고정. 접두 `scv ·` **넣지 않음**. phase 라벨만 볼드.

```markdown
**【 <한글 phase 라벨> 】** "<scv_line>" — <짧은 요약> · 다음: <next>
```

**여백:** `【` 뒤·`】` 앞 **공백 1칸** 고정. 예: `【 대기 】` · `【 계획 작성 】`.

예시:

```markdown
**【 요구사항 접수 】** "I read you." — 오늘 현황 탭만 재구성 · 다음: plan
```

```markdown
**【 계획 작성 】** "SCV good to go, sir." — plan.md 작성 중 · 다음: 계획 검토
```

```markdown
**【 구현 】** "Orders received." — 배치 1 코딩 중 · 다음: 게이트
```

| 규칙 | 내용 |
|------|------|
| 발화 시점 | **phase 진입 · role dispatch · user gate · blocked · hang recovery · FINAL** 만 |
| 여백 | `【 ` + 라벨 + ` 】` — 앞뒤 공백 1칸. `【대기】` / `【 대기】` / `【대기 】` 금지 |
| 금지 | soft-wait/heartbeat 마다 반복 · 진행 내레이션 **영어 only** · `【scv · …】` · 긴 두 줄 본문 기본 |
| 저장 | `scv_line` 표시 전용 — `run.json` 영속 저장 금지 |
| 워커 | task spec / `worker_done` body 에 대사 주입 금지 (팀장 채팅만) |

### phase → 한글 라벨 · `scv_line` (고정 테이블)

원작 StarCraft SCV 음성 대사(레거시 FRONT-JB/scv README 표)를 Orca phase에 매핑. **문구 임의 창작 금지**.

| 이벤트 | 한글 phase 라벨 | `scv_line` |
|--------|-----------------|------------|
| preflight / RUN_ID 발급 | 태스크 초기화 | `Reportin' for duty.` |
| seed / interview | 요구사항 접수 | `I read you.` |
| init dispatch | 초기화 | `Reportin' for duty.` |
| plan dispatch | 계획 작성 | `SCV good to go, sir.` |
| plan 승인 대기 (user gate) | 계획 승인 대기 | `Orders, Cap'n?` |
| plan-review dispatch | 계획 검토 | `I read you.` |
| plan-review fix 라운드 | 계획 수정 | `Come again, Cap'n?` |
| implement dispatch | 구현 | `Orders received.` |
| quality gate 통과 | 인수 확인 | `Affirmative.` |
| code-review dispatch | 코드 리뷰 | `I read you.` |
| review-fix dispatch | 리뷰 수정 | `Right away sir.` |
| release dispatch | 릴리스 | `Roger that.` |
| AUDIT | 감사 | `Affirmative.` |
| RECLAIM | 회수 | `Job's finished.` |
| FINAL / READY | 완료 | `Job's finished.` |
| blocked / P0 hold | 차단 | `I can't build there.` |
| abandon / cancel | 중단 | `I'm not readin' you clearly.` |
| hang recovery redispatch | 재시도 | `SCV good to go, sir.` |

대기 재고지(soft timeout, **드물게 1회**):

```markdown
**【 대기 】** "Affirmative." — 계획 작성 중 · worker_done 대기
```

금지 예: `Heartbeat received…`, `Rolling wait for plan worker_done` 같은 **사용자/Tasks 패널 영어 only**.

### 역할 한글 라벨 (탭 · display-name · wait 공통 · 필수)

| role (meta) | 한글 라벨 | 라운드 변형 |
|-------------|-----------|-------------|
| init | `초기화` | — |
| plan | `계획 작성` | — |
| plan-review | `계획 검토` | `계획 검토 · 2` |
| implement | `구현` | `구현 · 배치2` |
| code-review | `코드 리뷰` | `코드 리뷰 · 2` |
| review-fix | `리뷰 수정` | `리뷰 수정 · 2` |
| release | `릴리스` | — |

### 터미널 타이틀 (한글 · 필수)

```bash
orca terminal create --worktree active --title "계획 작성" --command '…' --json
orca terminal split --terminal <first> --direction vertical --command '…' --json
orca terminal rename --terminal <new_handle> --title "계획 검토" --json
```

| 규칙 | 내용 |
|------|------|
| create | `--title` = 위 한글 라벨 |
| split | 직후 **`rename` 필수** |
| 핑퐁 | 라운드만 `· 2` rename |
| 금지 | 영문 slug only · 제목으로 task 퍼지 매칭 |

### Orca task-title · display-name (한글 · 필수 · pack 1.3.4)

```bash
orca orchestration task-create \
  --task-title "[scv:$RUN_ID] 계획 작성 · <짧은-slug>" \
  --display-name "계획 작성" \
  --spec "<full task body…>" \
  --json
```

| 필드 | 규칙 | 예 |
|------|------|-----|
| `--display-name` | **필수 한글** = 역할 라벨 표와 동일 | `계획 작성` |
| `--task-title` | `[scv:$RUN_ID]` + 한글 phase + `·` + 짧은 slug | `[scv:20260720-…] 계획 작성 · 현황탭-재구성` |
| 금지 | `scv-plan`, `plan-worker`, 영문 only display-name · 제목 퍼지로 task 재사용 |

### wait 셸 description (Tasks 패널 · 필수 · pack 1.3.4)

팀장이 `check --wait` / liveness 셸을 돌릴 때 **tool description·Tasks 표시 문구**를 아래로 고정.  
(앱이 앞에 `Task` 를 붙일 수 있음 — 우리가 넣는 본문만 한글.)

**템플릿:** `{한글 phase} {상태} ({lifecycle})`

| 상황 | description (본문) |
|------|-------------------|
| worker 완료 대기 | `계획 작성 완료 대기 (worker_done)` |
| implement 대기 | `구현 완료 대기 (worker_done)` |
| code-review 대기 | `코드 리뷰 완료 대기 (worker_done)` |
| user/decision gate | `계획 승인 대기 (decision_gate)` |
| escalation 대기 | `에스컬레이션 대기 (escalation)` |
| post-inject liveness | `계획 작성 생존 확인 (liveness)` |

| 규칙 | 내용 |
|------|------|
| 필수 | 한글 phase + 상태 + 괄호 lifecycle |
| 금지 | `Rolling wait…` · `wait for plan worker_done` · 영문 only description |
| soft-timeout 재wait | 동일 한글 description 유지 (새로 영문 짓지 말 것) |

