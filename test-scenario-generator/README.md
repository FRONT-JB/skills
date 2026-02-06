# test-scenario-generator

Playwright로 웹 페이지를 분석하고 E2E 테스트 시나리오를 자동 생성하여 Notion 데이터베이스에 등록하는 Claude Code 스킬.

## 주요 기능

| 모드 | 설명 | 트리거 예시 |
|------|------|-------------|
| 페이지 분석 | Playwright로 URL을 방문하여 UI 요소를 분석하고 시나리오 자동 생성 | `"로그인 페이지 테스트 시나리오 작성해줘"` |
| 설명 기반 | 사용자가 설명한 기능에 대해 테스트 케이스 작성 | `"프로젝트 생성 기능 QA 케이스 만들어줘"` |
| 코드 동기화 | 기존 `.spec.ts` 파일을 파싱하여 Notion DB에 동기화 | `"playwright 테스트 파일을 노션에 동기화해줘"` |

## 사전 요구사항

### 1. MCP 서버 설정

이 스킬은 두 개의 MCP 서버가 필요합니다.

**Playwright MCP** (페이지 분석용)

```json
// .claude/settings.json 또는 claude_desktop_config.json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-server-playwright"]
    }
  }
}
```

**Notion MCP** (데이터베이스 등록용)

Claude Code에서 `/mcp` 명령어로 Notion MCP 서버를 추가하고 OAuth 인증을 완료합니다.

### 2. Notion 데이터베이스 준비

아래 템플릿을 복제하여 사용하거나, 동일한 속성을 가진 데이터베이스를 직접 생성합니다.

**[Notion 템플릿 바로가기](https://verbose-baritone-4b4.notion.site/QA-206e8fe23c0e807f83ead2ce1403d8a0)**

필요한 DB 속성:

| 속성명 | 타입 | 필수 | 설명 |
|--------|------|------|------|
| 시나리오 ID | Title | O | 고유번호 (예: `LGN-001`) |
| 시나리오명 | Text | O | 검증 목적 요약 |
| 사전조건 | Text | | 테스트 전 필요한 환경/데이터 |
| 테스트 절차 | Text | O | 구체적 수행 단계 (번호 목록) |
| 기대결과 | Text | O | 시스템이 보여야 하는 결과 |
| 카테고리 | Select | O | 기능 영역 분류 |

> 속성명은 정확히 일치해야 합니다. 스키마 상세는 [`references/db-schema.md`](./references/db-schema.md) 참조.

## 설정

### 플레이스홀더 교체

`SKILL.md`와 `references/db-schema.md`에 있는 플레이스홀더를 실제 값으로 교체합니다.

| 플레이스홀더 | 위치 | 교체할 값 |
|-------------|------|-----------|
| `<your-data-source-id>` | SKILL.md, db-schema.md | Notion DB의 data_source_id |
| `<your-notion-db-url>` | db-schema.md | Notion DB URL |
| `<your-notion-parent-page>` | db-schema.md | 상위 페이지 경로 |
| `<your-db-name>` | db-schema.md | 데이터베이스 이름 |

**data_source_id 확인 방법:**

Claude Code에서 Notion MCP의 `notion-fetch` 도구로 DB URL을 조회하면 응답에 `data_source_id`가 포함됩니다.

```
"DB URL을 notion-fetch로 조회해줘"
→ 응답에서 data_source_id 값 확인
```

> 플레이스홀더를 교체하지 않아도 스킬은 동작합니다. 이 경우 매 실행 시 사용자에게 DB 정보를 확인하는 단계가 추가됩니다.

## 사용법

### 특정 페이지 테스트 시나리오 생성

```
로그인 페이지(https://example.com/login) 테스트 시나리오를 작성하고 노션에 등록해줘
```

**실행 흐름:**
1. Playwright로 해당 URL 방문 및 UI 분석
2. 인터랙티브 요소(폼, 버튼, 링크 등) 식별
3. 분석 결과 기반 시나리오 작성
4. Notion DB에 등록

### 기능 설명 기반 시나리오 작성

```
프로젝트 생성 기능에 대한 QA 테스트 케이스를 만들어서 노션에 넣어줘
```

**실행 흐름:**
1. 대상 페이지/모달 범위 확인
2. Playwright로 해당 기능 분석
3. CRUD 패턴 등을 적용하여 시나리오 작성
4. Notion DB에 등록

### 기존 테스트 코드 동기화

```
기존 playwright 테스트 파일들을 노션 DB에 동기화해줘
```

**실행 흐름:**
1. `**/*.spec.ts` 파일 탐색
2. `test()`/`it()` 블록 파싱 및 매핑
3. Notion DB에 등록

## 시나리오 ID 규칙

카테고리별 영문 3자 접두사 + 순번:

| 카테고리 | 접두사 | 예시 |
|----------|--------|------|
| 로그인 | LGN | `LGN-001` |
| 회원가입 | SGN | `SGN-001` |
| 대시보드 | DSB | `DSB-001` |
| (새 카테고리) | 영문 약어 3자 | `XXX-001` |

## 카테고리 자동 관리

시나리오 작성 시 DB에 존재하지 않는 카테고리가 필요하면:

1. 사용자에게 새 카테고리가 필요함을 알림
2. 카테고리 이름을 제안하고 확인 요청
3. `notion-update-data-source`로 Select 옵션 추가
4. 이후 `notion-create-pages`로 시나리오 등록

> **주의**: Notion Select 속성은 존재하지 않는 값으로 직접 행을 삽입하면 validation error가 발생합니다. 반드시 옵션을 먼저 추가해야 합니다.

## 파일 구조

```
test-scenario-generator/
├── SKILL.md                          # 스킬 정의 (워크플로우, 트리거 조건)
├── README.md                         # 사용 가이드 (이 파일)
└── references/
    ├── db-schema.md                  # Notion DB 속성 스키마 정의
    └── scenario-patterns.md          # 테스트 시나리오 패턴 가이드
```

| 파일 | 역할 |
|------|------|
| `SKILL.md` | Claude Code가 스킬을 인식하고 실행하는 진입점. 워크플로우 4단계 정의 |
| `references/db-schema.md` | Notion DB 속성 타입, 필수 여부, 입력 예시 정의 |
| `references/scenario-patterns.md` | 인증/폼/CRUD/네비게이션 등 7가지 테스트 패턴과 Playwright 분석 기법 |

## 커스터마이징

### 카테고리 추가

`references/db-schema.md`의 "카테고리 옵션" 테이블과 "시나리오 ID 명명 규칙" 테이블에 새 항목을 추가합니다.

### 시나리오 패턴 추가

`references/scenario-patterns.md`에 새로운 테스트 패턴 섹션을 추가하면 시나리오 생성 시 참조됩니다.

### DB 속성 변경

Notion DB 속성을 변경한 경우 `references/db-schema.md`의 속성 테이블과 JSON 예시를 함께 업데이트합니다.
