# 웹앱 테스트 시나리오 패턴 가이드

일반적인 웹 애플리케이션 테스트 시나리오 패턴과 Playwright 분석 기법.

## 목차

1. [인증 테스트](#1-인증-테스트)
2. [폼 검증 테스트](#2-폼-검증-테스트)
3. [CRUD 테스트](#3-crud-테스트)
4. [네비게이션 테스트](#4-네비게이션-테스트)
5. [반응형 테스트](#5-반응형-테스트)
6. [접근성 테스트](#6-접근성-테스트)
7. [에러 처리 테스트](#7-에러-처리-테스트)
8. [Playwright 분석 기법](#8-playwright-분석-기법)

---

## 1. 인증 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 유효한 자격증명 로그인 | Critical | 리다이렉트, 세션 생성, UI 상태 변경 |
| 잘못된 자격증명 로그인 | Critical | 에러 메시지, 입력값 유지 여부 |
| OAuth 로그인 (Google 등) | Critical | 외부 팝업, 콜백 처리, 사용자 정보 표시 |
| 로그아웃 | High | 세션 파괴, 보호 페이지 접근 차단 |
| 비인증 상태에서 보호 페이지 접근 | High | 로그인 페이지로 리다이렉트 |
| 세션 만료 처리 | Medium | 자동 로그아웃, 안내 메시지 |
| 회원가입 유효성 검증 | High | 필수 필드, 형식 검증, 중복 검사 |

### Playwright 분석 시 확인

```
- /login 페이지의 폼 요소 (input[type=email], input[type=password])
- OAuth 버튼 존재 여부와 href 패턴
- /api/auth/* 엔드포인트 패턴
- middleware.ts의 보호 라우트 목록
```

## 2. 폼 검증 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 필수 필드 미입력 제출 | High | 에러 메시지 위치, 내용, 포커스 이동 |
| 형식 오류 입력 (이메일, 전화번호 등) | High | 실시간/제출 시 검증, 에러 메시지 |
| 최대/최소 길이 초과 | Medium | 입력 제한 또는 에러 표시 |
| 특수문자/XSS 입력 | Medium | 이스케이프 처리, 에러 없음 |
| 유효한 데이터 제출 성공 | Critical | 성공 메시지, 리다이렉트, 데이터 반영 |
| 중복 제출 방지 | Medium | 버튼 비활성화, 로딩 상태 |

### Playwright 분석 시 확인

```
- form 요소와 input 속성 (required, pattern, maxlength)
- Zod schema 파일 (schemas/ 디렉토리)
- 에러 메시지 요소의 aria-live 속성
- 제출 버튼의 disabled 상태 변화
```

## 3. CRUD 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 항목 생성 (Create) | Critical | 폼 제출, 목록 반영, 성공 메시지 |
| 항목 조회 (Read) | Critical | 목록 표시, 상세 뷰, 데이터 정확성 |
| 항목 수정 (Update) | High | 기존 데이터 로드, 변경 반영 |
| 항목 삭제 (Delete) | High | 확인 다이얼로그, 목록에서 제거 |
| 빈 상태 (Empty State) | Medium | 데이터 없을 때 안내 메시지 |
| 목록 페이지네이션/무한스크롤 | Medium | 추가 로드, 스크롤 위치 |

### Playwright 분석 시 확인

```
- 생성 버튼/모달의 존재와 위치
- API 엔드포인트 패턴 (POST, GET, PUT/PATCH, DELETE)
- TanStack Query 캐시 무효화 패턴
- 삭제 확인 다이얼로그 구현 방식
```

## 4. 네비게이션 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 메인 네비게이션 링크 작동 | High | 올바른 페이지 이동, URL 변경 |
| 뒤로가기/앞으로가기 | Medium | 브라우저 히스토리 정상 작동 |
| 직접 URL 입력 접근 | Medium | 딥링크 정상 작동, 404 처리 |
| 404 페이지 | Medium | 존재하지 않는 경로 접근 시 처리 |
| 동적 라우트 파라미터 | High | [projectId] 등 파라미터 올바른 전달 |

## 5. 반응형 테스트

### 뷰포트별 시나리오

| 뷰포트 | 해상도 | 검증 포인트 |
|--------|--------|------------|
| 모바일 | 375×667 | 햄버거 메뉴, 스택 레이아웃, 터치 타겟 크기 |
| 태블릿 | 768×1024 | 그리드 변화, 사이드바 동작 |
| 데스크톱 | 1280×720 | 풀 레이아웃, 호버 상태 |
| 와이드 | 1920×1080 | 최대 너비 제한, 콘텐츠 정렬 |

### Playwright 분석 기법

```
browser_resize로 뷰포트 변경 후:
- 레이아웃 브레이크 확인
- 요소 가시성 변화 확인 (모바일 메뉴 등)
- 터치 인터랙션 요소 크기 (최소 44×44px)
```

## 6. 접근성 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 키보드만으로 전체 기능 사용 | High | Tab 순서, Enter/Space 동작, Esc로 닫기 |
| 스크린리더 호환성 | High | ARIA 레이블, 역할, 상태 |
| 포커스 관리 | Medium | 모달 포커스 트랩, 포커스 복원 |
| 색상 대비 | Medium | WCAG 2.1 AA 기준 (4.5:1) |

### Playwright 분석 기법

```
browser_snapshot(verbose=true)로 접근성 트리 확인:
- aria-label, aria-describedby 존재
- role 속성 올바른 사용
- 포커스 가능한 요소의 tabindex
```

## 7. 에러 처리 테스트

### 필수 시나리오

| 시나리오 | 우선순위 | 검증 포인트 |
|----------|----------|------------|
| 네트워크 오류 | High | 에러 메시지 표시, 재시도 옵션 |
| API 서버 에러 (5xx) | High | 사용자 친화적 에러 메시지 |
| API 클라이언트 에러 (4xx) | Medium | 적절한 안내, 입력 교정 유도 |
| 타임아웃 | Medium | 로딩 상태 해제, 에러 표시 |

## 8. Playwright 분석 기법

### 페이지 초기 분석 체크리스트

```
1. browser_navigate → 페이지 로드
2. browser_snapshot → 전체 요소 트리 캡처
3. 인터랙티브 요소 목록화:
   - button, a[href], input, select, textarea
   - [role="button"], [role="link"], [role="tab"]
   - data-testid 속성이 있는 요소
4. browser_network_requests → API 패턴 파악
5. browser_console_messages(level="error") → 기존 에러 확인
```

### 인터랙션 테스트 패턴

```
# 폼 필드 발견 및 테스트
1. snapshot에서 input/select/textarea 식별
2. browser_fill_form으로 유효/무효 데이터 입력
3. 제출 후 snapshot으로 결과 확인
4. network_requests로 API 호출 검증

# 모달/다이얼로그 테스트
1. 트리거 버튼 click
2. snapshot으로 모달 내용 확인
3. 모달 내 동작 수행
4. 닫기 후 원래 상태 복원 확인

# 네비게이션 테스트
1. 링크/버튼 click
2. URL 변경 확인
3. snapshot으로 새 페이지 내용 확인
4. browser_navigate_back으로 이전 페이지 복원 확인
```

### 네트워크 분석 패턴

```
browser_network_requests(includeStatic=false)로 API 호출만 필터링:
- 인증: POST /api/auth/*
- CRUD: GET/POST/PUT/DELETE /api/resources/*
- 에러 응답: status >= 400
```
