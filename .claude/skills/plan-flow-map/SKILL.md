---
name: plan-flow-map
description: >
  플랜/계획/로드맵/구현계획 문서를 다크모드 리치 HTML 문서(파일)로 시각화한다. 목표·게이트 콜아웃,
  현재↔목표 비교표, method 배지가 붙은 API 엔드포인트 카드(파라미터 표·JSON), 필드/타입 엔티티 카드,
  번호 매긴 구현순서 표, 변경배지 파일 트리 등 타입별 블록을 위→아래로 렌더링한다. 어떤 마크다운
  플랜이 와도 일관된 블록 문서로 재구성한다. 속도 최우선: 마크다운의 기계적 구조는 parse_md.py가
  무-LLM(0토큰)으로 블록화하고, LLM은 한눈 요약(hero)과 산문 압축만 담당한 뒤 build.py로 조립한다.
  결과물은 self-contained · 다크/라이트 대응. 반드시 이 스킬을 쓸 것 — 사용자가 "플랜/계획/로드맵/구현계획
  시각화", "plan 아티팩트", "이 계획 문서 그림으로/문서로 보여줘", "plan.md 시각화", "실행 계획 문서
  만들어줘", "구현 계획 렌더", "plan visual", "roadmap artifact" 라고 하거나, 플랜/로드맵/구현계획
  마크다운을 건네며 "시각적으로 보고 싶다"고 할 때는 '아티팩트'라는 단어가 없어도 이 스킬을 사용한다.
argument-hint: "[플랜 문서 경로 또는 대상 플랜(선택)]"
compatibility: "python3 (표준 라이브러리만) · 파일 read/write 필요. 선택: 병렬 하위 에이전트(없으면 순차)."
---

# plan-flow-map

플랜 문서를 다크모드 팔레트의 **리치 스크롤 문서**로 시각화한다.
타입별 블록(콜아웃·비교표·엔드포인트 카드·엔티티 카드·구현순서 표·파일 트리·코드)을 위→아래로 렌더링한다.

## 목적 — 긴 문서를 "빠르게 이해"시키는 도구

이 스킬의 목적은 길게 쓰인 마크다운 문서를 **읽기 쉽게** 보여주는 것이다. 보고서처럼 딱딱하게 원문을 그대로
옮기지 말고, 이해가 빠르도록 재구성한다.

**출력은 2-레이어다:** 맨 위에 항상 펼쳐진 **한눈 요약(hero)** + 그 아래 **기본 접힘 상세 섹션**(펼쳐서
리뷰). 빠른 이해(hero)와 무손실 상세(접이식)를 동시에 준다. 요약은 세부를 *삭제*하는 게 아니라 위에 *얹는다*.

## ⛔ 최우선 규칙

- **전달받은 플랜 문서가 유일한 진실**이다. 문서에 없는 엔드포인트·필드·파일·게이트를 지어내지 않는다.
- **어떤 마크다운이 와도 하나의 블록 문서로 재구성**한다(스키마는 `references/doc-schema.md`).
- **HTML/CSS를 손으로 만들지 않는다.** 블록 JSON만 만든다 — `build.py`가 다크 스타일 HTML로 조립한다.
- **하이브리드 = 기계는 파서, 판단은 LLM.** 마크다운의 기계적 구조(헤딩·표·코드·파일목록→트리·중첩 불릿·
  blockquote→콜아웃)는 `parse_md.py`가 **무-LLM(0토큰)** 으로 만든다. LLM은 판단이 필요한 것 — **한눈
  요약(hero)** 과 **산문 압축·콜아웃 승격(폴리시)** — 만 담당한다. "모든 섹션을 LLM으로"는 하지 않는다.

## 경로 규약 (런타임 중립)

- `<skill>` = **이 SKILL.md가 있는 디렉토리**(스킬 루트). 아래 상대경로·명령은 이 폴더 기준이다.
- **절대경로를 하드코딩하지 않는다** — 런타임마다 설치 위치가 다르다: Claude Code `~/.claude/skills/`,
  Codex `~/.agents/skills/`, OpenCode는 둘 다 스캔. 하위 에이전트엔 메인이 `<skill>`을 실제 절대경로로 치환해 전달.
- `<tmp>` = 임시 작업 폴더(런타임 스크래치, 없으면 `mktemp -d`나 repo-local `.plan-flow-map-tmp/`).

## 이 스킬의 파일

- `scripts/parse_md.py` — 마크다운 플랜을 **무-LLM 결정론 파싱**해 블록 JSON 본문 생성. (python3 표준 라이브러리만)
- `scripts/build.py` — `doc.json`(블록 목록)을 HTML로 조립·주입. 블록별 렌더러 포함.
- `assets/template.html` — 렌더링 셸(CSS+테마 토글, 다크/라이트). **직접 수정 금지.**
- `references/doc-schema.md` — `doc.json`/블록 스키마(11종). **작업 전 반드시 읽는다.**
- `references/reshaping-rubric.md` — 마크다운→블록 재구성 규칙(매핑·무손실·표현압축·자가점검). LLM 패스가 따른다.

## 절차 (하이브리드)

최종 HTML은 `<skill>/cache/`에 캐시로 저장한다 — 게시/아티팩트 도구로 올리지 말고 파일로만 남긴다.

### Step 0 — 스키마·규칙 숙지
`references/doc-schema.md`(블록 11종)와 `references/reshaping-rubric.md`(재구성 규칙)를 읽는다.

### Step 1 — 플랜 확보 + meta
- 플랜 문서를 읽는다(경로가 주어지면 그 파일, 없으면 대화 컨텍스트의 플랜).
- `meta`를 정한다: `title`, `eyebrow`(예: "구현 계획"), `subtitle`(한두 문장 요약), `source`(문서 경로
  + git 레포면 `git rev-parse --short HEAD`·branch). parse_md.py가 기본 meta를 넣지만, Step 5에서 보강한다.

### Step 2 — 결정론 파싱 (본문 · 0 토큰)
`parse_md.py`로 마크다운 구조를 블록 본문으로 만든다. LLM을 쓰지 않는다.
```bash
python3 "<skill>/scripts/parse_md.py" "<플랜.md>" "<tmp>/body.json" --title "<제목>"
```
이 단계가 헤딩·표(파일+변경 표는 자동으로 **트리**로)·코드펜스·중첩 불릿·blockquote→콜아웃·문단을 처리한다.
남는 것은 **판단이 필요한 것**뿐이다(Step 3·4).

> **폴백**: 입력이 깔끔한 마크다운 구조가 아니어서 파서 결과가 부실하면, 옛 방식(문서를 섹션으로 나눠 섹션마다
> LLM 하위 에이전트 1개가 rubric대로 블록 JSON 생성 → 병합)으로 전환한다. 이때도 hero(Step 4)는 동일하게 얹는다.

### Step 3 — 폴리시 패스 (LLM 1개 · 산문 압축·콜아웃 승격)
LLM 에이전트 1개에 `<tmp>/body.json`과 원본 플랜을 주고 아래만 시킨다(결과 `<tmp>/body.polished.json`):
```
- reshaping-rubric.md §3(표현 압축)·§2(무손실)을 따른다.
- prose 블록: 원문 문단을 ≤2문장 리드 + 필요 시 bullets로 압축(산문 벽 금지). 항목·기술 토큰은 verbatim.
- 산문 속에 묻힌 게이트/위험/목표는 알맞은 tone의 callout으로 승격.
- 명백한 블록 오선택 교정(예: 산문으로 서술된 API→endpoint, 모델→entity).
- 절대 규칙: 모든 블록·리스트 항목·표 행·코드·tree·경로를 보존(삭제 금지). 순서 유지. table/tree/code/stats는
  그대로 통과. 바꾸는 것은 prose 표현과 callout 승격뿐.
```
속도를 최우선으로 하고 산문이 적은 문서면 이 단계를 생략하고 `body.json`을 그대로 써도 된다(단 산문이 원문
그대로 길게 남는다).

### Step 4 — 한눈 요약(hero) 합성 (LLM 1개 · Step 3와 병렬 가능)
합성 에이전트가 **문서 전체**를 읽고 hero 블록을 `<tmp>/hero.json`(배열)로 만든다:
```
[ {"type":"heading","level":2,"text":"한눈 요약","summary":true},   // summary:true → 접히지 않는 hero
  {"type":"callout","tone":"goal","title":"목표","body":"<1~2문장>"},
  {"type":"bullets","title":"핵심 변경","items":[<3~5개>]},
  {"type":"stats","items":[{"value":"..","label":".."}, ...]},        // 규모 칩(파일 수·배치 등)
  {"type":"callout","tone":"gate","title":"핵심 게이트","body":"<압축>"},
  {"type":"callout","tone":"warn","title":"최상위 위험","body":"<1~3개>"} ]
```
요약이지만 원문에 있는 사실만 쓴다(지어내기 금지).

### Step 5 — 병합
`hero.json`(맨 앞) + Step 3의 `body.polished.json`(없으면 `body.json`) blocks를 이어붙이고, Step 1 `meta`를
보강해 `<tmp>/doc.json`을 완성한다:
```jsonc
{ "meta": { "title": "...", "eyebrow": "...", "subtitle": "...", "source": "..." },
  "blocks": [ /* hero 블록 + 본문 블록 */ ] }
```

### Step 6 — 빌드 (캐시로 저장)
슬러그를 정한다(원본 파일명/주제 기반, kebab-case ascii). **게시/아티팩트 도구로 올리지 않는다(파일만).**
```bash
mkdir -p "<skill>/cache"
cp "<tmp>/doc.json" "<skill>/cache/<slug>.doc.json"
python3 "<skill>/scripts/build.py" "<skill>/cache/<slug>.doc.json" "<skill>/cache/<slug>.html"
```
같은 슬러그면 덮어써 캐시가 갱신된다. 검증 실패 시 메시지대로 `doc.json`을 고쳐 다시 빌드한다.

### Step 7 — 열기 (선택)
경로를 사용자에게 알린다: `<skill>/cache/<slug>.html`. self-contained라 파일을 그대로 브라우저로 열면 된다.
```bash
python3 -c "import webbrowser,sys; webbrowser.open('file://'+sys.argv[1])" "<skill>/cache/<slug>.html"
# 셸 대안: Linux=xdg-open · macOS=open · Windows=start
```

## 품질 체크(끝내기 전)
- [ ] 상단 hero(한눈 요약)가 있는가? (목표·핵심 변경·규모 stats·게이트·위험)
- [ ] 파일 목록이 표가 아니라 `tree`(변경배지)로 갔는가? API/모델은 endpoint/entity로?
- [ ] 게이트/승인 기준에 실제 명령·검증이 있는가? ("잘 됨" 금지)
- [ ] 폴리시를 돌렸다면 산문 벽이 없고 항목·토큰이 보존됐는가? build.py 검증 통과했는가?

## 참고
- 결과물은 self-contained · 다크/라이트 자동 대응(우상단 토글) · 반응형. 코드/JSON 블록은 Dracula 하이라이트.
- **레이아웃**: 상단 hero(항상 펼침) + 각 level-2 섹션은 접이식(`<details>`, 기본 접힘). 목차에 "모두 펼치기"
  토글이 있고, 목차 링크 클릭 시 해당 섹션이 자동으로 열린다.
- 파일 스코프는 `tree`(변경배지 신규/수정/삭제/재생성), 규모는 `stats` 칩, 중첩 체크리스트는 중첩 `bullets`.
- **비용 감각(실측)**: 전-섹션 LLM 방식 ≈ 수십만 토큰/수분. 하이브리드(파서+hero, 폴리시 생략) ≈ hero 1개
  토큰/수십초. 폴리시까지 = LLM 2개. 기계적 비중이 큰 문서일수록 하이브리드 이득이 크다.
- 런타임 이식: parse_md.py·build.py·template.html은 python3만 있으면 그대로 동작(툴명 비의존).
- 코드 구조(코드베이스) 시각화가 필요하면 architecture-flow-map을 쓴다. 이 스킬은 계획 문서 전용.
