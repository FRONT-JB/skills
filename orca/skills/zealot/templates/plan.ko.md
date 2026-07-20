# Plan — {{제목}}

- **RUN_ID:** `{{RUN_ID}}`
- **Branch:** `{{branch}}`
- **작성일:** {{YYYY-MM-DD}}
- **Prose language:** {{resolvedDocsLanguage}} (식별자·경로·명령은 영문)

---

## Overview

### 문제

(무엇을 왜 고치는지)

### 목표

(성공 시 관찰 가능한 결과)

### 비목표 (Out of scope)

-

---

## Architecture

(영향 범위·모듈 관계. 코드 스니펫 금지 — 산문으로)

---

## Files to change (Scope manifest 초안)

| 경로/glob | 변경 종류 | 설명 |
|-----------|-----------|------|
| | 추가/수정/삭제/rename | |

- **예상 파일 수 / 상한:**
- 승인 후 이 표·상한·종류가 **동결**된다. 이탈 시 범위 확장 gate.

---

## Test Impact

### 가설

(변경 후 어떤 검사가 어떻게 변할 것으로 예상하는가)

### 검증

(실제로 무엇을 돌려 확인할 것인가. “위반 집합 불변” 같은 추측은 가설로만 쓰고 검증으로 확인)

### Lint 재활성 정책

설정 로드 복구 등으로 이전에 죽어 있던 lint가 살아날 수 있음:

- [ ] (A) 최소 autofix를 **별 배치**로 처리 (사용자 확인)
- [ ] (B) FAIL 보고 후 decision_gate
- [ ] (C) 후속 이슈로 분리 (**기본 권장**)

coordinator 자가 확장 금지.

---

## To-dos (배치)

### Batch 1 —

1. … → **verify:**
2. …

---

## Gate commands (frozen candidates)

```text
{{예: pnpm lint}}
```

- typecheck / test: 스크립트 없으면 **N/A** (발명 금지)

---

## Constraints

- scope manifest 준수
- `git add -A` 금지 · `.zealot/**` 스테이징 금지
- push는 사용자 확인 전 금지

---

## Implementation deltas vs original plan

(구현 중 범위 확장·decision_gate 결과 — 사후 기록)
