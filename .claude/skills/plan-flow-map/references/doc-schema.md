# doc.json schema (block document)

`build.py` reads ONE JSON object: `{ "meta": {...}, "blocks": [ ... ] }`. `meta` sets the header;
`blocks` is an ordered list of typed blocks rendered top→bottom. You (and parallel subagents) only
produce this JSON — `build.py` turns each block into styled dark/light HTML. Never write HTML yourself.

## meta

```jsonc
{
  "title":    "역삼 단일 오피스 전환 구현 계획",   // required. <title> + H1
  "eyebrow":  "구현 계획",                         // optional. small uppercase label above the title
  "subtitle": "예약 도메인을 단일 오피스로 좁히고 …", // optional. 1–2 sentence lede
  "source":   "docs/plans/2026-07-22_office.plan.md · <b>main</b> · a1b2c3d" // optional. mono badge (inline md ok)
}
```

## blocks — the eleven types

Every block is `{ "type": "<name>", ... }`. Text fields accept a tiny markdown subset: `` `code` ``
and `**bold**` (everything else is escaped — safe for raw plan text). Below, each type with its fields.

### heading
Section / sub-section title. `text`; optional `level` (2 = section default, 3 = sub).
**렌더링 동작:** level-2 heading은 그 다음 블록들과 함께 **접이식 섹션(`<details>`, 기본 접힘)**으로 묶인다.
예외로 **`"summary": true`** 를 준 level-2 heading은 **항상 펼쳐진 hero 패널**(상단 "한눈 요약")이 된다.
```json
{ "type": "heading", "text": "API 계약" }
{ "type": "heading", "text": "요청 파라미터", "level": 3 }
{ "type": "heading", "text": "한눈 요약", "summary": true }   // 상단 hero (접히지 않음)
```

### prose
Paragraph(s). `text` is a string (blank lines split paragraphs) or an array of paragraph strings.
```json
{ "type": "prose", "text": "이 변경은 예약 모델을 `Reservation`으로 통합한다. **비파괴** 마이그레이션." }
```

### bullets
List. `items` (array). Optional `title` (uppercase sub-label), `ordered` (numbered), `mono`
(monospace bordered chips — good for commands / acceptance criteria).
**중첩**: 항목은 문자열(leaf)이거나 `{ "text": "...", "items": [ ... ] }`(하위 목록)일 수 있다 — 부모-자식
계층이 있는 체크리스트/단계는 이렇게 중첩한다(평탄화 금지).
```json
{ "type": "bullets", "title": "범위", "items": ["frontend 직접 노출 제거", "backend 예약 API 정리"] }
{ "type": "bullets", "mono": true, "items": ["pnpm --filter api test", "pnpm lint --max-warnings 0"] }
{ "type": "bullets", "items": [
  { "text": "T1 새 repository 작성", "items": ["본문 이관", "클래스명 규칙"] },
  { "text": "T2 기존 파일 삭제", "items": ["typeorm.repository.ts", "interfaces/"] } ] }
```

### callout
Emphasis box. `tone` ∈ `gate` | `goal` (gold) · `warn` (red) · `info` (blue). Optional `title`; `body`
(string/array, paragraphs).
```json
{ "type": "callout", "tone": "gate", "title": "게이트", "body": "`pnpm --filter api test` 통과 + reservation e2e green." }
{ "type": "callout", "tone": "warn", "body": "frontend/backend를 **한 브랜치**에서 바꾸면 배포 순서가 꼬인다." }
```

### compare
Side-by-side cards (before/after, current/target). `columns`: array of `{ label, items[], accent? }`.
The last column is accent-highlighted by default (set `"accentLast": false` to disable).
```json
{ "type": "compare", "columns": [
  { "label": "현재 공개 모델", "items": ["`branchId` 노출", "office = branch 혼용"] },
  { "label": "목표 공개 모델", "items": ["`officeId` 단일", "Reservation.office = 고정"] }
] }
```

### table
Generic table. `headers` (array), `rows` (array of arrays). Optional `title`. First column is emphasized.
**용도:** 진짜 속성 매트릭스 — 구현 순서(순서·작업·책임), 파라미터, 속성 비교 등 여러 열이 의미 있는 격자.
**안 쓸 때:** 파일·경로 목록은 **`tree`를 써라**(소스가 마크다운 표여도). 경로 한 열 + 설명은 표가 아니다.
```json
{ "type": "table", "title": "구현 순서",
  "headers": ["#", "작업", "책임 경계"],
  "rows": [["1", "shared 타입/스키마 리팩터", "비파괴 · `packages/shared`"],
           ["2", "backend 예약 API 정리", "`apps/api` · migration 포함"]] }
```

### endpoint
Collapsible API card. `method` (GET/POST/PATCH/PUT/DELETE), `path`. Optional: `tag` (e.g. "신규"/"추가"),
`summary` (right-aligned one-liner), `desc`, `params` `{headers?, rows[]}`, `request`, `response`
(string OR JSON object — objects are pretty-printed), `note` (→ info callout), `open` (start expanded).
```json
{ "type": "endpoint", "method": "POST", "path": "/api/v1/reservations", "tag": "신규",
  "summary": "예약 생성", "desc": "office 단위 예약을 만든다.",
  "params": { "headers": ["필드","타입","필수","설명"],
              "rows": [["officeId","string","Y","대상 오피스"],["slot","ISO8601","Y","예약 시간"]] },
  "request": { "officeId": "ofc_123", "slot": "2026-08-01T09:00:00Z" },
  "response": { "id": "rsv_1", "status": "confirmed" },
  "note": "중복 슬롯은 `409`." }
```

### entity
Schema / model card. `name`, optional `sub`, `fields`: array of `{ name, type, note? }`,
optional `relations` (array of strings).
```json
{ "type": "entity", "name": "Reservation", "sub": "firestore · reservations/{id}",
  "fields": [ {"name":"id","type":"string"},
              {"name":"officeId","type":"string","note":"branchId 대체"},
              {"name":"status","type":"'confirmed'|'canceled'"} ],
  "relations": ["Office 1—N Reservation"] }
```

### tree
Annotated file/directory tree. `title?`, `lines`: array of `{ depth, name, kind?("dir"|"file"), change?, note?, tag? }`.
**용도:** 파일·경로 목록, 디렉토리 구조, "변경될 파일" 스코프. **파일 목록이면 소스가 표여도 이걸 써라**(표 대신).
- `depth` 들여쓰기 단계(0-based). `kind:"dir"`는 금색, 파일은 평문.
- **`change`**: 변경 종류 배지 — `"신규"`(초록) · `"수정"`(노랑) · `"삭제"`(빨강+취소선) · `"재생성"`(파랑). 색은 자동.
- `note`: 우측 흐린 설명(파일별 변경 요지). `tag`: 그 외 일반 pill.
- 디렉토리로 묶으면(공통 상위 경로를 dir 노드로) 스캔이 쉬워진다.
```json
{ "type": "tree", "title": "변경될 파일", "lines": [
  { "depth": 0, "name": "apps/api/", "kind": "dir" },
  { "depth": 1, "name": "reservations.controller.ts", "kind": "file", "change": "수정", "note": "office 파라미터" },
  { "depth": 1, "name": "create-branch.dto.ts", "kind": "file", "change": "삭제", "note": "write 표면 제거" },
  { "depth": 0, "name": "packages/shared/", "kind": "dir" },
  { "depth": 1, "name": "reservation.schema.ts", "kind": "file", "change": "신규" } ] }
```

### code
Mono block. `text` (string) or a JSON value (pretty-printed). Optional `title`, `lang` (label only).
```json
{ "type": "code", "title": "gate command", "text": "pnpm --filter api test -- reservation" }
```

### stats
At-a-glance metric chips — value + label. **용도:** 규모/요약 수치(변경 파일 수, 배치 수, diff 집계 등).
주로 hero(한눈 요약)나 파일 스코프 상단에 둔다. `items`: `{ value, label }` 배열.
```json
{ "type": "stats", "items": [
  { "value": "36", "label": "변경 파일" }, { "value": "45", "label": "상한" },
  { "value": "5", "label": "배치" }, { "value": "2", "label": "신규" } ] }
```

## Authoring rules

- **재구성 방법(어떤 원문을 어떤 블록으로)은 `reshaping-rubric.md`를 따른다** — 매핑 표·무결성(누락 금지)·
  자가 점검. 이 문서는 각 블록의 *형태*만 정의한다.
- **The plan document is the only source of truth.** Do not invent endpoints, fields, files, or gates.
  Use the doc's real names/paths/commands. If a detail is uncertain, omit it rather than guess.
- **Pick the block that fits the content**, not the fanciest one: model definitions → `entity`;
  API surface → `endpoint`; before/after → `compare`; ordered work → `table`; commands/criteria →
  `bullets` (mono) or `code`; risks/gates → `callout`.
- **Keep the reading order of the source.** Blocks render in array order.
- Not every plan has API/entities/trees — only emit blocks the plan actually contains.
- Sizing: prefer several focused blocks over one giant table. Endpoint/param tables ≤ ~8 rows each.
