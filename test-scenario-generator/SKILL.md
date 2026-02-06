---
name: test-scenario-generator
description: "Playwright를 사용하여 웹 애플리케이션의 테스트 시나리오를 작성하고 Notion 데이터베이스에 입력하는 스킬. 다음 상황에서 사용: (1) 웹 페이지를 Playwright로 분석하여 E2E 테스트 시나리오를 자동 생성할 때, (2) 사용자가 설명한 기능에 대한 테스트 케이스를 작성하고 Notion DB에 기록할 때, (3) 기존 Playwright 테스트 코드(.spec.ts)를 파싱하여 Notion 테스트 관리 DB에 동기화할 때, (4) '테스트 시나리오 작성', 'QA 시나리오', '테스트 케이스 노션에 등록' 등의 요청 시 트리거."
---

# Playwright Test to Notion

Playwright로 웹앱을 분석하고 테스트 시나리오를 작성하여 Notion 데이터베이스에 등록하는 워크플로우.

## Workflow

```
사용자 요청 분석
    ├─ A: 특정 기능/페이지 지정 → Step 1로
    ├─ B: 전체 앱 테스트 요청 → Step 0(범위 확인) → Step 1로
    └─ C: 기존 .spec.ts 파일 동기화 → Step 3으로
```

### Step 0: 범위 확인

전체 앱 테스트 요청 시 사용자에게 우선순위를 확인:

- 어떤 페이지/기능을 우선 테스트할지
- Critical Path(핵심 사용자 플로우)가 무엇인지

### Step 1: Playwright로 페이지 분석

Playwright MCP 도구 또는 Chrome DevTools MCP를 사용하여 대상 페이지를 분석한다.

```
1. browser_navigate로 대상 URL 접속
2. browser_snapshot으로 접근성 트리 캡처
3. 주요 인터랙티브 요소 식별:
   - 폼 필드 (input, select, textarea)
   - 버튼 및 링크
   - 모달/다이얼로그 트리거
   - 네비게이션 요소
4. browser_network_requests로 API 엔드포인트 파악
5. browser_console_messages로 에러 패턴 확인
```

**분석 시 수집할 정보:**
- 페이지의 주요 UI 요소와 역할
- 사용자 인터랙션 가능한 요소 목록
- API 호출 패턴 (인증, CRUD 등)
- 현재 에러 또는 경고 메시지

### Step 2: 테스트 시나리오 작성

분석 결과 + 사용자 요구사항을 결합하여 테스트 시나리오를 작성한다.

**시나리오 구조:**
각 시나리오는 다음 속성을 포함한다 (상세 스키마는 `references/db-schema.md` 참조):

| 속성 | 타입 | 설명 |
|------|------|------|
| 시나리오 ID | Title | 카테고리 접두사 + 순번 (예: `LGN-001`) |
| 시나리오명 | Text | 무엇을 검증하는지 간단히 설명 |
| 사전조건 | Text | 테스트 실행 전 필요한 환경/데이터 |
| 테스트 절차 | Text | 사용자가 수행하는 구체적 단계 (번호 목록) |
| 기대결과 | Text | 단계 수행 시 시스템이 보여야 하는 결과 |
| 카테고리 | Select | `로그인`, `아이디 찾기`, `아이디 설정`, `비밀번호 설정` |

**시나리오 패턴 참조:** 일반적인 테스트 패턴은 `references/scenario-patterns.md` 참조.

**작성 규칙:**
- 테스트 단계는 사용자 관점에서 작성 (Given-When-Then 또는 번호 목록)
- 하나의 시나리오는 하나의 검증 목적만 가짐
- 기대결과는 관찰 가능한 결과로 명시 (UI 변화, 네트워크 응답, 상태 변경)

### Step 3: Notion 데이터베이스에 등록

Notion MCP 서버의 `notion-create-pages` 도구를 사용하여 시나리오를 등록한다.

**대상 DB 정보:**
- 사용자에게 Notion DB 이름 또는 URL을 확인
- `notion-fetch`로 DB를 조회하여 data_source_id와 스키마를 확인
- `references/db-schema.md`의 기본 스키마와 매핑

**등록 절차:**

```
1. DB 확인
   - 사용자에게 Notion DB 이름 또는 URL 확인
   - notion-fetch로 DB 스키마 조회 후 매핑

2. 카테고리 검증
   - notion-fetch로 DB의 카테고리 Select 옵션 목록을 조회
   - 작성한 시나리오의 카테고리가 기존 옵션에 존재하는지 확인
   - 존재하지 않는 카테고리가 있으면:
     a. 사용자에게 해당 카테고리가 DB에 없음을 알림
     b. 추가할 카테고리 이름을 사용자에게 확인 (제안 포함)
     c. 사용자가 확정한 이름으로 시나리오의 카테고리 값을 설정
     d. notion-update-data-source로 DB 스키마의 카테고리 Select에
        새 옵션을 먼저 추가 (존재하지 않는 값으로 행 삽입 시 validation error 발생)
     e. 옵션 추가 완료 후 create-pages로 행 삽입 진행

3. 행 삽입
   - notion-create-pages로 data_source_id에 행 삽입
   - 모든 테스트 정보를 속성(properties)으로 입력

4. 결과 보고
   - 등록된 시나리오 수와 목록 출력
   - 새로 추가된 카테고리가 있으면 함께 안내
   - Notion 페이지 링크 제공
```

**카테고리 검증 예시:**

```
기존 옵션: [로그인, 아이디 찾기, 아이디 설정, 비밀번호 설정]
시나리오 카테고리: "대시보드"

→ "대시보드" 카테고리가 현재 DB에 존재하지 않습니다.
  다음 이름으로 새 카테고리를 추가할까요?
  - 제안: "대시보드"
  - 다른 이름을 원하시면 알려주세요.
```

**Notion API 사용 패턴:**

```python
# 행 삽입 (notion-create-pages 도구 사용)
{
  "parent": {
    "data_source_id": "<your-data-source-id>"
  },
  "pages": [
    {
      "properties": {
        "시나리오 ID": "LGN-001",
        "시나리오명": "유효한 이메일/비밀번호로 로그인 성공",
        "사전조건": "회원가입 완료된 계정이 존재",
        "테스트 절차": "1. /login 페이지 접속\n2. 이메일 입력\n3. 비밀번호 입력\n4. 로그인 버튼 클릭",
        "기대결과": "/dashboard로 리다이렉트\n사용자 이름 표시",
        "카테고리": "로그인"
      }
    }
  ]
}

# 여러 시나리오 일괄 삽입 시 pages 배열에 추가
```

### Step 3-alt: 기존 .spec.ts 파일에서 동기화

기존 Playwright 테스트 코드가 있는 경우:

```
1. Glob으로 **/*.spec.ts 파일 탐색
2. 각 파일에서 test() 또는 it() 블록 파싱
3. 매핑:
   - describe 이름 → 카테고리
   - test title → 시나리오명
   - 파일명 + 순번 → 시나리오 ID (예: LGN-001)
   - 코드 내 주석/step → 테스트 절차
   - expect/assert → 기대결과
4. Step 3의 Notion 등록 절차 실행
```

## 사용 예시

### 예시 1: 특정 페이지 테스트 시나리오 생성

```
사용자: "로그인 페이지의 테스트 시나리오를 작성해서 노션에 등록해줘"

→ Step 1: /login 페이지를 Playwright로 분석
→ Step 2: 로그인 관련 시나리오 작성 (성공, 실패, OAuth 등)
→ Step 3: Notion DB에 등록
```

### 예시 2: 사용자 설명 기반 시나리오 작성

```
사용자: "프로젝트 생성 기능에 대한 QA 테스트 케이스를 만들어서 노션에 넣어줘"

→ Step 0: 프로젝트 생성 관련 페이지/모달 확인
→ Step 1: /dashboard 페이지에서 프로젝트 생성 모달 분석
→ Step 2: CRUD 시나리오 작성
→ Step 3: Notion DB에 등록
```

### 예시 3: 기존 테스트 코드 동기화

```
사용자: "기존 playwright 테스트 파일들을 노션 DB에 동기화해줘"

→ Step 3-alt: .spec.ts 파일 파싱 후 Notion에 등록
```

## Resources

- **references/db-schema.md** - Notion 데이터베이스 기본 속성 스키마 정의
- **references/scenario-patterns.md** - 웹앱 테스트 시나리오 패턴 가이드
