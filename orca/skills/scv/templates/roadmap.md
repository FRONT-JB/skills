<!--
  Roadmap Draft — plan 워커(Claude Code)에게 전달되는 최초 프롬프트 문서.
  coordinator가 인터뷰 종료 후 이 템플릿을 채워 `.scv/state/$RUN_ID/brief/roadmap.md`로 저장.
  plan 워커 `--spec` 의 handoff 경로에 roadmap.md 를 포함해 전달.
  템플릿 고정 — 항목·순서·섹션 제목 변경 금지(PLAYBOOK §0c).

  채우기 규칙 (plan 워커는 본 주석 무시, 본문만 따름):
  - `{{placeholder}}` 는 coordinator가 인터뷰 결과로 치환. casing은 본문에 표기된 대로.
  - 항목이 0개일 때는 `- N/A` 로 표기.
  - §3.1 In scope / §3.2 Out of scope / §3.3 Non-goals / §4 후보 / §4.1 Docs / §5 Constraints / §7: 항목 없으면 `- N/A`.
  - §6 Gates 三-way:
      (a) Filled  — coordinator가 gate 명령·현황을 채운 줄. 승인 후 동결 대상.
      (b) Empty   — `- ` (게이트 미확정). plan 워커가 plan.md에서 gate 명령을 확정한다.
      (c) N/A     — `- N/A`. 이 런에서 게이트가 해당 없음.
    §6의 두 placeholder 줄은 coordinator가 (a) 또는 (c)로 치환하거나, (b)로 남겨둘 수 있다.
  - §4 후보 bullet 앞에 선택적 분류 태그를 붙일 수 있다: `[route] [route-local] [pkg] [docs] [backend] [migration] [test]` 등. 헤더·§4·§8.3에 동일 목록.
  - §7: 각 bullet 은 `- risk:` 또는 `- open:` 접두로 시작.
-->

# [scv:{{RUN_ID}}] 계획 작성 · {{slug}}

- **RUN_ID:** `{{RUN_ID}}`
- **Slug:** `{{slug}}`
- **Branch:** `{{branch}}`
- **작성일:** {{YYYY-MM-DD}}
- **Prose language:** {{resolvedDocsLanguage}} (식별자·경로·명령·에러 인용은 영문)
- **Handoff to:** `plan` 워커 (Claude Code)
- **Plan output:** `docs/plans/{{YYYY-MM-DD}}_{{slug}}.plan.md`

---

## 1. Context (한 단락 · 권장 2-3문장 이상)

{{사용자 요청(Goal)의 배경·의도·같이 논의된 제약을 한 단락 서사. coordinator가 인터뷰로 확정한 내용.}}

## 2. Goal (한 문장)

{{이 런에서 달성해야 하는 결과. 동사 원형 + 목적어. 예시는 참고용 — UI/백엔드/마이그레이션/버그픽스 무관하게 한 문장으로 목표를 서술한다.}}

## 3. Scope

### 3.1 In scope
- {{item 1}}

### 3.2 Out of scope (이 런에서 하지 않음)
- {{item 1}}

### 3.3 Non-goals (절대 하지 않음)
- {{item 1}}

---

## 4. Candidate areas (수정 영역 후보 · 파일 경로 목록)

> **주의:** coordinator는 아래 경로의 **존재만 확인**했다. 파일 단위 구조·시그니처·의존·분기·전이 등 상세 분석은 plan 워커가 plan.md 작성 시 수행한다. 이 목록은 plan 워커가 plan.md를 0부터 시작하지 않도록 하는 출발점이다. 항목 없으면 `- N/A`.

- {{선택적 분류 태그}} `{{상대 경로}}`
- {{선택적 분류 태그}} `{{상대 경로}}`

선택적 분류 태그(하나 이상 권장): `[route] [route-local] [pkg] [docs] [backend] [migration] [test]`. 작업에 없는 분류는 생략한다.

### 4.1 Docs (plan.md 외, 이 런에서 함께 수정될 문서)

- `docs/{{...}}` · 해당 없으면 `- N/A`

---

## 5. Constraints (사용자·프로젝트 제약)

> 작업에 맞는 제약만 채운다. 예시는 참고용 — UI/백엔드/마이그레이션/버그픽스 모두에 적용되는 것은 아니다. 항목 없으면 `- N/A`.

- {{제약 1}}
- {{제약 2}}

## 6. Gates (coordinator가 이미 확정한 경우만 · 동결 대상)

> 三-way (PLAYBOOK §0c): Filled(동결 대상) / Empty(placeholder 그대로 — plan 워커가 plan.md에서 gate 명령을 확정) / `- N/A`(이 런에서 게이트 해당 없음).

- `{{gate 명령}}` · {{pass/fail/NA}}
- `{{gate 명령}}` · {{pass/fail/NA}}

---

## 7. Risks / open questions (plan 워커가 plan.md에서 명시적으로 다뤄야 할 점)

> 작업 유형 무관. `- risk:` 또는 `- open:` 접두 고정. 항목 없으면 `- N/A`.

- risk: {{위험 1}}
- open: {{열린 질문 1}}

---

## 8. Plan worker에게 전달하는 지시 (Claude Code용)

아래는 plan 워커가 이 로드맵을 받아 수행해야 할 작업입니다.

1. **이 로드맵을 출발점**으로 `docs/plans/{{YYYY-MM-DD}}_{{slug}}.plan.md`를 작성하라. 산출물 섹션 구성은 `$HOME/.orca/scv/templates/plan.ko.md`(resolvedDocsLanguage=ko) 또는 동등 템플릿을 따른다.
2. **코드 스니펫 금지** — plan.md는 산문과 파일 경로/표로 설계한다.
3. 위 §4 후보 파일을 직접 열어 **파일 단위로 작업 유형에 맞는 관점(구조·시그니처·의존·분기·전이·실행 흐름·시각적 위계 등)으로 세부 설계**를 전개하라. 관점은 §2 Goal과 §3 Scope를 보고 판단한다. §4 분류 태그(`[route] [route-local] [pkg] [docs] [backend] [migration] [test]`)는 후보 영역의 성격을 나타내는 메타정보로 활용한다.
4. §5 Constraints 를 준수하고, 위반 사항이 발견되면 plan.md Constraints 섹션에 명시하라.
5. §6 Gates 의 三-way 를 존중하라: Filled 줄은 동결 대상, Empty 줄은 plan.md에서 gate 명령을 확정, `- N/A`는 gate 없음.
6. §7 Risks / open questions 를 plan.md의 해당 섹션에서 명시적으로 다루라.
7. **Scope manifest (동결 대상)**: allowed paths/globs · 예상 파일 수 또는 상한 · 변경 종류 · frozen gate 명령을 반드시 포함.
8. 완료 후 `orca orchestration send --type worker_done` structured flags 로 완료 신호. 정확한 플래그는 `--spec` 상단의 LIFECYCLE 블록을 따른다(LIFECYCLE 블록은 coordinator가 task-create `--spec`에 주입하므로 plan 워커는 그대로 실행한다).

---

## 9. Handoff paths (coordinator 기록)

- brief(선택): `.scv/state/{{RUN_ID}}/brief/plan-brief.md` — coordinator가 인터뷰 중 확정한 것이 있으면 여기에. 없으면 `- N/A`.
- roadmap (this file): `.scv/state/{{RUN_ID}}/brief/roadmap.md`
- plan output (plan 워커가 작성): `docs/plans/{{YYYY-MM-DD}}_{{slug}}.plan.md`
- plan-review 산출: `.scv/state/{{RUN_ID}}/plan-review/codex.md`