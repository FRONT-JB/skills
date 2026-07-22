---
name: architecture-flow-map
description: >
  현재 프로젝트의 코드베이스를 분석해, 전체 구조 지도(좌) + 유저 액션 flow 목록(우상) + 선택한
  flow의 단계별 진행(우하)으로 구성된 인터랙티브 HTML 아티팩트를 생성한다. flow를 고르면 그 경로가
  지도에 강조되고 실제 함수·파일 기준 단계가 펼쳐진다. 결과물은 다크/라이트 대응 self-contained HTML.
  트리거: "아키텍처 아티팩트", "아키텍처 지도", "코드베이스 지도 만들어줘", "flow 다이어그램",
  "architecture flow map", "codebase map artifact", "구조 시각화 아티팩트".
argument-hint: "[프로젝트 경로 또는 강조할 도메인(선택)]"
---

# architecture-flow-map

코드베이스를 ToDesktop 스타일 3-패널 인터랙티브 다이어그램으로 시각화한다.
좌: 전체 구조 지도(카테고리 컬럼 × 노드) / 우상: 유저 액션(flow) 목록 / 우하: 선택한 flow의
노드→노드 단계(실제 함수·파일 근거). flow 선택 시 좌측 지도에 경로가 번호 화살표로 강조된다.

## ⛔ 최우선 규칙 — 실행되는 프로젝트 기준으로만 작성

이 스킬의 모든 노드·flow·라벨은 **지금 스킬이 실행된 프로젝트를 직접 분석해서** 만든다.

- 다른 프로젝트(예: ride-office)나 `assets/example-data.json`의 내용을 **절대 복사하지 않는다.**
  example-data.json은 오직 JSON 스키마 형태를 보여주는 예시다.
- 존재하지 않는 파일·함수·엔드포인트를 지어내지 않는다. 반드시 열어서 확인한 것만 인용한다.
  확신이 없으면 `det`에 `(추정)`을 붙인다.
- 프로젝트 언어/도메인 용어를 그대로 쓴다(백엔드 프레임워크, 라우팅 방식, 외부 서비스명 등).

## 이 스킬의 파일

- `assets/template.html` — 렌더링 셸(CSS+JS). 프로젝트마다 바뀌지 않는다. **직접 수정하지 않는다.**
- `scripts/build.py` — `data.json`을 템플릿에 주입해 최종 HTML 생성 + 참조 무결성 검증.
- `references/data-schema.md` — `data.json` 스키마. **작업 전 반드시 읽는다.**
- `assets/example-data.json` — 스키마 예시(형태 확인용, 복사 금지).

경로는 `~/.claude/skills/architecture-flow-map/` 기준.

## 절차

작업 파일(`data.json`, `architecture.html`)은 스크래치패드에 만든다. 사용자가 레포에 커밋하길
원할 때만 레포로 옮긴다.

### Step 0 — 스키마 숙지 + 스냅샷 메타
- `references/data-schema.md`를 읽는다.
- git 메타를 수집해 `meta.snapshot`에 넣는다(git 레포일 때):
  ```bash
  printf '스냅샷 · <b>%s</b> · %s · %s' "$(git branch --show-current)" "$(git rev-parse --short HEAD)" "$(date +%F)"
  ```

### Step 1 — 프로젝트 파악
- `README`, `AGENTS.md`/`CLAUDE.md`, 매니페스트(`package.json`·`go.mod`·`pom.xml`·`pyproject.toml` 등),
  최상위 디렉토리 구조를 읽어 **도메인·스택·아키텍처 형태**를 파악한다.
- 모노레포면 앱/패키지 경계를, 단일 앱이면 레이어 경계를 식별한다.

### Step 2 — 컬럼(카테고리) 정의
프로젝트 아키텍처를 4~8개 컬럼으로 나눈다. 기본 taxonomy를 프로젝트 용어로 조정한다:

| 기본 컬럼 | 의미 | 예 |
|---|---|---|
| 행위자 | 시스템을 쓰는 주체 | 사용자, 관리자, 외부 시스템, 스케줄러 |
| 프론트 화면 | 유저가 마주하는 UI 표면 | 라우트/페이지 그룹, API client |
| API · Handler | 진입 컨트롤러/핸들러/라우터 | REST 컨트롤러, GraphQL resolver, RPC |
| 도메인 로직 | 핵심 서비스/유스케이스 | service, usecase, domain module |
| 데이터 · 저장소 | 영속화 | DB, 캐시, 오브젝트 스토리지, 큐 |
| 외부 연동 | 서드파티/아웃바운드 | 결제·메일·SMS·webhook·시크릿 |

프로젝트에 없는 컬럼은 빼고, 고유한 축(예: 배치/워커, 알림, 빌드 파이프라인)이 있으면 추가한다.
컬럼 색은 순서대로 자동 배정되므로 색은 신경 쓰지 않는다.

### Step 3 — 노드 인벤토리
각 컬럼에 실제 구성요소를 노드로 채운다(모듈/컨트롤러/서비스/테이블/외부 클라이언트 등).
`lab`은 실제 이름(클래스/파일/테이블), `sub`는 짧은 한 줄(경로·데코레이터·역할).
**중대형 레포는 병렬 서브에이전트(Explore/general-purpose)로 인벤토리를 나눠 수집**한다
(예: 백엔드 모듈 / 프론트 화면·서비스 / 외부 연동). 소형이면 직접 읽는다.

### Step 4 — 유저 flow 추적
주요 유저 액션 5~12개를 고른다(로그인, 핵심 생성·제출, 승인/상태전이, 결제/발행, 외부 웹훅 등).
각 flow를 end-to-end로 추적해 `from→to` 단계(5~13개)로 만들고, 각 단계 `det`에 **실제 함수/엔드포인트/
파일/상태전이**를 적는다. 여기서도 flow별로 서브에이전트에 추적을 맡기면 정확·빠르다.
호출 체인을 실제로 열어 따라가고, 불확실하면 `(추정)` 표기. 코드상 없는 단계는 넣지 않는다.

### Step 5 — data.json 작성
스키마대로 `<scratch>/data.json`을 쓴다. `meta.title`은 "<프로젝트명> — 아키텍처 & 플로우".
모든 flow step의 `from`/`to`는 존재하는 node `id`여야 한다(build.py가 검증).

### Step 6 — 빌드
```bash
python3 ~/.claude/skills/architecture-flow-map/scripts/build.py <scratch>/data.json <scratch>/architecture.html
```
검증 실패 시(미존재 노드 참조, 컬럼 누락 등) 메시지대로 `data.json`을 고쳐 다시 빌드한다.

### Step 7 — (선택) 로컬 확인 후 게시
- 로컬 확인이 필요하면: 스크래치패드에서 `python3 -m http.server`로 charset UTF-8 서빙 후 브라우저로 연다
  (프로젝트 폴더 밖 `file://`는 정적 스냅샷이라 JS가 안 돈다 — HTTP로 띄워야 flow/지도가 보인다).
- 게시: Artifact 도구로 `<scratch>/architecture.html`을 게시한다.
  - `title` = `meta.title`, `favicon` = `🧭`, `description`에 한 줄 요약.
  - 사용자가 "같은 링크 유지"를 원하면 같은 file_path로 재게시(같은 세션) 또는 `url` 전달.

## 품질 체크(끝내기 전)
- [ ] 모든 노드·flow가 이 프로젝트 코드에서 확인된 것인가? (지어낸 것/타 프로젝트 잔재 없음)
- [ ] flow step의 `det`에 실제 함수/파일/엔드포인트가 있는가?
- [ ] 컬럼 4~8개, flow 5~12개 수준으로 과밀하지 않은가?
- [ ] build.py가 검증 통과했는가?

## 참고
- 결과물은 self-contained · 다크/라이트 자동 대응(보는 사람 테마 따라감) · 반응형이다.
- 컬럼이 많으면 넓은 화면에서도 맵이 가로 스크롤될 수 있다(의도된 캔버스 스크롤).
- "dev 갱신 때마다 자동" 같은 라이브 갱신은 아티팩트 자체로는 불가. 필요하면 이 스킬을
  CI(예: push 시 build.py 실행 후 같은 URL로 재게시)로 감싸는 별도 작업이 필요하다.
- UI chrome 라벨 기본값은 한국어다. 영어 등으로 바꾸려면 `meta.ui`로 오버라이드한다(스키마 참고).
