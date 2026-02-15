# e2e-runner

ridenow-frontend monorepo의 페이지를 코드 분석하여 E2E 테스트 시나리오를 자동 생성하고, 선택적으로 Playwright MCP로 검증하는 스킬입니다.

## 트리거

다음 상황에서 이 스킬을 사용합니다:

- 사용자가 `/e2e-runner {경로}` 형태로 실행
- 사용자가 "E2E 시나리오 생성", "테스트 시나리오 작성", "페이지 분석" 등을 요청
- 예시:
  - `/e2e-runner admin/member-management`
  - `/e2e-runner b2c/product/[id]`
  - `/e2e-runner validate ./scenarios/admin-member-management-scenario.md`
  - `/e2e-runner settings`

## 핵심 특징

1. **코드 분석 기반 시나리오 생성**: 고정 템플릿이 아닌 실제 코드 분석 결과로 시나리오 생성
2. **마크다운 형식**: 읽기 쉽고 버전 관리 가능한 .md 파일로 저장
3. **조건부 로직 커버리지**: if/else, Zod 검증, 권한 체크 등 모든 분기 반영
4. **독립적 실행**: 서비스 프로젝트에 테스트 패키지 설치 불필요
5. **선택적 Playwright 검증**: 생성된 시나리오를 실제 브라우저에서 검증 (선택)

---

## 사용법

### 기본 사용 (시나리오 생성)
```bash
/e2e-runner <route>
```

예시:
```bash
/e2e-runner admin/member-management
/e2e-runner b2c/product/[id]
/e2e-runner admin/products/$id/detail
```

### 시나리오 검증만 실행
```bash
/e2e-runner validate <파일경로>
```

예시:
```bash
/e2e-runner validate ./scenarios/admin-member-management-scenario.md
/e2e-runner validate /Users/jb/Desktop/test-scenarios/admin-member-management-scenario.md
```

### 설정 확인/수정
```bash
/e2e-runner settings
```

---

## 워크플로우

### Step 0: 커맨드 파싱 및 환경 확인

#### 0.1 커맨드 파싱
args를 파싱하여 실행 모드 결정:

1. **validate**: 시나리오 검증만 실행 → Step 6으로 이동
2. **settings**: 설정 확인 → config.json 표시 및 수정 안내
3. **경로 (기본)**: 시나리오 생성 → Step 1부터 진행

#### 0.2 config.json 로드
```
{skillDir}/config.json 읽기
→ project.rootPath, apps, testAccounts, scenarioOutput 확인
```

**에러 처리**:
- config.json 없음 → config.example.json 참고하여 생성 안내
- 필수 필드 누락 → 구체적인 에러 메시지

#### 0.3 프로젝트 경로 확인
```
config.project.rootPath 존재 확인
→ 없으면 에러: "프로젝트 경로가 존재하지 않습니다"
```

#### 0.4 출력 디렉토리 생성
```
mkdir -p {config.scenarioOutput.baseDir}
```

---

### Step 1: 경로 매핑

**참고 문서**: `references/route-mapping-rules.md`

#### 1.1 앱 prefix 추출
```
입력: "admin/member-management"
→ app: "admin"
→ route: "member-management"

입력: "b2c/product/[id]"
→ app: "b2c"
→ route: "product/[id]"
```

**검증**:
- 지원하지 않는 앱 → 에러: "사용 가능한 앱: admin, b2c"

#### 1.2 앱 설정 로드
```
appConfig = config.apps[app]
→ baseUrl, appPath, routePattern, pathAliases 등
```

#### 1.3 파일 경로 계산

**Admin (직접 매핑)**:
```
{projectRoot}/{appPath}/{route}/page.tsx
```

**B2C (직접 → glob)**:
```
1. 직접 매핑 시도: {projectRoot}/{appPath}/{route}/page.tsx
2. 실패 시 glob: {projectRoot}/{appPath}/**/page.tsx
   - 경로를 '/'로 분할하여 각 세그먼트 사이에 '**/` 삽입
   - Route Groups (groupName) 자동 탐색
```

**예시**:
```
입력: b2c/my-page/info/coupon
직접: apps/b2c/src/app/my-page/info/coupon/page.tsx (실패)
Glob: apps/b2c/src/app/my-page/**/info/**/coupon/page.tsx
발견: apps/b2c/src/app/my-page/(user-info)/info/coupon/page.tsx
```

#### 1.4 파일 존재 확인
```
Read 도구로 page.tsx 읽기 시도
→ 성공: Step 2로 진행
→ 실패: 에러 메시지 + 시도한 경로 표시
```

---

### Step 2: 코드 분석 (깊이 있게)

**참고 문서**: `references/code-analysis-guide.md`

#### 2.1 페이지 파일 분석 (page.tsx)

**추출 정보**:
1. **Import 문**:
   ```typescript
   import { MemberFilter } from './components/MemberFilter';
   import { MemberTable } from './components/MemberTable';
   import { userService } from '@services/user';
   ```
   → 읽어야 할 파일 목록 생성

2. **조건부 렌더링**:
   ```typescript
   {status === 'PENDING' && <ApproveButton />}
   {hasPermission('DELETE') && <DeleteButton />}
   ```
   → 조건문 추출

3. **페이지 구조**:
   - FilterGrid 존재 여부
   - DataGrid/Table 존재 여부
   - Form 존재 여부

#### 2.2 로컬 컴포넌트 분석 (./components/*.tsx)

**FilterGrid 컴포넌트**:
```typescript
<FilterGrid
  formList={[
    { label: "회원명", name: "name", formType: "text" },
    { label: "상태", name: "status", formType: "select", options: [...] }
  ]}
/>
```

**추출**:
- 필터 필드 목록: `[{ name, type, label, options }]`
- Select 필드의 options (enum 값)

**DataGrid/Table 컴포넌트**:
```typescript
<DataGrid
  columns={[
    { id: "seq", header: "회원 ID", accessorKey: "seq" },
    {
      id: "actions",
      cell: ({ row }) => (
        row.status === 'ACTIVE' && <EditButton />
      )
    }
  ]}
/>
```

**추출**:
- 테이블 컬럼 목록: `[{ id, header, accessorKey }]`
- 조건부 컬럼: `{ condition, element }`
- 액션 버튼: `[{ label, condition }]`

**Form 컴포넌트**:
```typescript
const schema = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
  age: z.number().min(18).max(100).optional()
});
```

**추출**:
- 필드별 검증 규칙 (상세 분석)
- Required vs Optional
- Min/Max, Regex, Enum 등

#### 2.3 서비스 레이어 분석 (@services/{domain}/)

**읽을 파일**:
1. `services.ts`: API 메서드 (참고용)
2. `type.ts`: Enum, 타입 정의
3. `schema.ts`: Zod 검증 규칙 상세

**type.ts 예시**:
```typescript
export enum UserStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  PENDING = 'PENDING'
}
```

**추출**: Enum 값 목록

#### 2.4 Path Alias 해석

**예시**:
```typescript
import { userService } from '@services/user';

// config.json pathAliases
"@services": "src/services"

// 실제 경로
→ {projectRoot}/apps/{app}/src/services/user/services.ts
```

**알고리즘**:
1. Import 문에서 `@alias/path` 추출
2. config.pathAliases에서 실제 경로 찾기
3. 절대 경로 생성
4. 확장자 추가 (.ts, .tsx) 및 파일 읽기

#### 2.5 분석 결과 통합

**최종 추출 데이터 구조**:
```json
{
  "pageType": "list | detail | create | custom",
  "files": {
    "page": "경로",
    "components": ["경로1", "경로2"],
    "services": ["경로1", "경로2"]
  },
  "ui": {
    "filters": [{ "name": "name", "type": "text", "label": "회원명" }],
    "columns": [{ "id": "seq", "header": "회원 ID" }],
    "formFields": [{ "name": "name", "type": "text", "validation": {...} }],
    "actions": [{ "label": "수정", "condition": "status === 'ACTIVE'" }]
  },
  "conditions": [
    { "condition": "status === 'PENDING'", "result": "승인/거부 버튼 표시" }
  ],
  "validations": {
    "name": { "required": true, "min": 1, "max": 50 },
    "email": { "required": true, "format": "email" }
  },
  "enums": {
    "UserStatus": ["ACTIVE", "INACTIVE", "PENDING"]
  }
}
```

---

### Step 3: 페이지 타입 판단

**판단 로직**:
```typescript
function determinePageType(analysis) {
  if (analysis.ui.filters.length > 0 && analysis.ui.columns.length > 0) {
    return "list";
  }
  if (routePath.includes("/$id/") || routePath.includes("/[id]/")) {
    return "detail";
  }
  if (routePath.includes("/create/") || analysis.ui.formFields.length > 0) {
    return "create";
  }
  return "custom";
}
```

---

### Step 4: 시나리오 생성 (코드 분석 기반)

**참고 문서**: `references/markdown-format.md`

**핵심 원칙**:
- ✅ 마크다운 구조만 통일 (섹션, 필드명)
- ✅ 내용은 Step 2의 분석 결과에 따라 동적 생성
- ❌ 고정 템플릿 사용하지 않음
- ✅ 번호는 001부터 순차적

#### 4.1 메타데이터 섹션 생성
```markdown
## 메타데이터
- **App**: {Admin | B2C}
- **Route**: {경로}
- **생성일**: {YYYY-MM-DD}
- **페이지 타입**: {analysis.pageType}
- **분석 파일**:
  - Page: {analysis.files.page}
  - Components: {analysis.files.components.length}개
  - Services: {analysis.files.services.length}개
```

#### 4.2 사전 설정 섹션 생성
```markdown
## 사전 설정

### 테스트 계정
- Email: {config.testAccounts[app].email}
- Password: {config.testAccounts[app].password}

### 테스트 URL
- Base URL: {config.apps[app].baseUrl}
- Full URL: {baseUrl + route}
```

#### 4.3 테스트 시나리오 생성 (동적)

**List 페이지 시나리오 생성 전략**:
```
1. 기본 로딩 시나리오
2. 필터 필드별 검색 시나리오 (analysis.ui.filters 기반) - 각 필터를 개별적으로 테스트
   - Text 필터: 필드당 1개 시나리오 (예: 회원명 검색, 휴대폰번호 검색)
   - DateRange 필터: 필드당 1개 시나리오 (예: 가입일 범위 검색)
   - Select 필터: 필드당 1개 시나리오, 대표 옵션 하나만 테스트
     → 예: userStatus → 1개 시나리오 (active 옵션만 테스트)
     → 예: signupMethod → 1개 시나리오 (kakao 옵션만 테스트)
3. 복합 필터 검색 시나리오 (여러 필터 조합)
4. 필터 초기화 시나리오
5. 조건부 컬럼/버튼 시나리오 (analysis.conditions 기반)
6. 페이지네이션 시나리오 (다음 페이지, 페이지 크기 변경)
7. 상세 페이지 이동 시나리오 (테이블에 링크가 있으면)
```

**중요**: 모든 필터 필드는 개별적으로 테스트하되, Select 필터는 대표 옵션 하나만 확인합니다.

**Detail 페이지 시나리오 생성 전략**:
```
1. 상세 페이지 로딩
2. 상태별 액션 버튼 시나리오 (analysis.conditions 기반)
3. 권한별 버튼 노출 시나리오 (analysis.conditions 기반)
```

**Create/Edit 페이지 시나리오 생성 전략**:
```
1. 폼 로딩
2. 필드별 검증 시나리오 (analysis.validations 기반)
   - Required 필드 미입력
   - Min/Max 경계값
   - Regex 형식 오류
   - Enum 값별 분기
3. 유효값 제출 성공
```

**조건문 → 시나리오 자동 생성 예시**:
```
분석 결과:
{
  "condition": "status === 'PENDING'",
  "result": "승인/거부 버튼 표시"
}

→ 생성되는 시나리오:
- 00N: PENDING 상태에서 승인 버튼 클릭
- 00N+1: PENDING 상태에서 거부 버튼 클릭
- 00N+2: APPROVED 상태에서 승인/거부 버튼 미표시
```

**Zod 검증 → 시나리오 자동 생성 예시**:
```
분석 결과:
{
  "name": { "required": true, "min": 1, "max": 50 },
  "email": { "required": true, "format": "email" },
  "age": { "required": false, "min": 18, "max": 100 }
}

→ 생성되는 시나리오:
- 00N: name 필드 비어있을 때 에러
- 00N+1: name 51자 입력 시 에러
- 00N+2: email 형식 오류 시 에러
- 00N+3: age 17 입력 시 에러
- 00N+4: age 101 입력 시 에러
- 00N+5: 모든 필드 유효값 제출 성공
```

#### 4.4 코드 분석 결과 섹션 생성 (참고용)

**페이지 타입별 다른 형식**:

**List 페이지**:
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
...

### UI 요소 분석
**필터 필드**: {analysis.ui.filters 목록}
**테이블 컬럼**: {analysis.ui.columns 목록}
**액션 버튼**: {analysis.ui.actions 목록}

### 조건부 로직 분석
{analysis.conditions 목록}

### 상태/Enum 값
{analysis.enums 목록}
```

**Create/Edit 페이지**:
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
...

### UI 요소 분석
**폼 필드**: {analysis.ui.formFields 목록}

### 검증 규칙 (Zod 스키마)
{analysis.validations 상세}

### 상태/Enum 값
{analysis.enums 목록}
```

---

### Step 5: 파일 저장

#### 5.1 저장 경로 결정
```
기본: config.scenarioOutput.baseDir
우선순위: 사용자가 실행 시 지정한 경로 (args로 전달 가능)
```

#### 5.2 파일명 생성
```
패턴: config.scenarioOutput.filenamePattern
기본: "{app}-{route}-scenario.md"

예시:
- admin-member-management-scenario.md
- b2c-product-[id]-scenario.md
```

**route에서 슬래시 제거**:
```
route: "member-management" → "member-management"
route: "product/[id]" → "product-[id]"
```

#### 5.3 디렉토리 생성 (없으면)
```
mkdir -p {scenarioOutput.baseDir}
```

#### 5.4 마크다운 파일 작성
```
Write 도구로 파일 생성
→ 성공 메시지: "✅ 시나리오 파일 생성 완료: {경로}"
```

---

### Step 6: Playwright 검증 (선택적)

**참고 문서**: `references/playwright-validation.md`

#### 6.1 사용자 확인
```
✅ 시나리오 파일 생성 완료: {파일 경로}

🤖 생성된 시나리오를 Playwright로 검증할까요?
- Yes: Playwright MCP로 브라우저 자동 테스트 실행
- No: 종료
```

**사용자가 "No" 선택** → 종료

**사용자가 "Yes" 선택** → Step 6.2로 진행

#### 6.2 Playwright MCP 도구 로드
```
ToolSearch를 사용하여 다음 도구 로드:
- mcp__plugin_playwright_playwright__browser_navigate
- mcp__plugin_playwright_playwright__browser_click
- mcp__plugin_playwright_playwright__browser_fill_form
- mcp__plugin_playwright_playwright__browser_snapshot
- mcp__plugin_playwright_playwright__browser_take_screenshot
- mcp__plugin_playwright_playwright__browser_close
```

**에러 처리**:
- Playwright MCP 미설치 → 안내 메시지

#### 6.3 마크다운 파싱
생성된 마크다운 파일을 읽어서 실행 가능한 단계로 변환

**파싱 예시**:
```markdown
### 001: 페이지 기본 로딩
**테스트 절차**:
1. 회원 관리 메뉴 클릭
2. 필터 영역 확인
```

→ 파싱 결과:
```json
[
  {
    "scenarioId": "001",
    "title": "페이지 기본 로딩",
    "steps": [
      { "type": "navigate", "url": "{baseUrl}/member-management" },
      { "type": "verify", "selector": ".filter-grid" }
    ]
  }
]
```

#### 6.4 자연어 → Playwright 명령 매핑

**매핑 규칙**:
```
"회원 관리 메뉴 클릭"
→ browser_navigate({ url: "{baseUrl}/member-management" })

"회원명 필드에 '홍길동' 입력"
→ browser_fill_form({ selector: 'input[name="name"]', value: '홍길동' })

"적용하기 버튼 클릭"
→ browser_click({ selector: 'button[type="submit"]' })

"필터 영역 표시 확인"
→ browser_snapshot() + 검증
```

#### 6.5 시나리오 실행

**각 시나리오별로 순차 실행**:
```typescript
for (const scenario of scenarios) {
  try {
    console.log(`실행 중: ${scenario.id} - ${scenario.title}`);

    for (const step of scenario.steps) {
      await executeStep(step);
    }

    console.log(`✅ ${scenario.id}: 성공`);
    results.push({ id: scenario.id, status: 'success' });
  } catch (error) {
    console.log(`❌ ${scenario.id}: 실패 - ${error.message}`);
    await browser_take_screenshot({ path: `failure-${scenario.id}.png` });
    results.push({ id: scenario.id, status: 'failure', error: error.message });
  }
}
```

#### 6.6 검증 리포트 생성

**리포트 형식**:
```markdown
# Playwright 검증 리포트

- **검증 일시**: {timestamp}
- **시나리오 파일**: {파일명}
- **총 시나리오**: {total}개
- **성공**: {success}개
- **실패**: {failure}개

## 성공 시나리오
- ✅ 001: 페이지 기본 로딩
- ✅ 002: 회원명 필터 검색
...

## 실패 시나리오

### ❌ 005: INACTIVE 상태 수정 버튼 미표시
**실패 원인**: 수정 버튼이 여전히 표시됨
**스크린샷**: failure-005.png
```

**리포트 저장**:
```
{scenarioOutput.baseDir}/{파일명}-validation-report.md
```

#### 6.7 브라우저 종료
```
browser_close()
```

---

## 에러 처리

### 파일을 찾을 수 없는 경우
```
❌ 페이지 파일을 찾을 수 없습니다.
입력 경로: {route}
시도한 경로:
- {directPath}
- {globPattern} (B2C의 경우)

확인 사항:
1. 경로가 올바른지 확인
2. page.tsx 파일이 존재하는지 확인
3. Route Groups이 있다면 실제 파일 구조 확인
```

### config.json 오류
```
❌ config.json 로드 실패
원인: {에러 메시지}

해결 방법:
1. {skillDir}/config.example.json 참고
2. 필수 필드 확인: project.rootPath, apps, testAccounts
```

### Path Alias 해석 실패
```
⚠️ Path alias를 해석할 수 없습니다: @unknown/path
→ config.json의 pathAliases에 추가 필요
```

---

## 참고 문서

스킬 디렉토리의 `references/` 폴더에 상세 가이드가 있습니다:

1. **route-mapping-rules.md**: 경로 매핑 로직 (Admin/B2C 차이점)
2. **code-analysis-guide.md**: 코드 분석 전략 (컴포넌트 추적, 조건문, Zod 검증)
3. **markdown-format.md**: 마크다운 출력 형식 가이드
4. **playwright-validation.md**: Playwright MCP 검증 가이드

---

## 설정 파일 (config.json)

**위치**: `{skillDir}/config.json`

**주요 섹션**:
- `project`: 프로젝트 경로
- `apps`: 앱별 설정 (admin, b2c)
- `testAccounts`: 테스트 계정 정보
- `scenarioOutput`: 시나리오 출력 설정

**수정 방법**:
```bash
/e2e-runner settings
→ config.json 내용 표시
→ 직접 파일 수정
```

---

## 예시

### 예시 1: List 페이지 시나리오 생성
```bash
/e2e-runner admin/member-management
```

**실행 과정**:
1. config.json 로드
2. 경로 매핑: apps/admin/src/app/member-management/page.tsx
3. 코드 분석:
   - MemberFilter 컴포넌트: 필터 필드 5개
   - MemberTable 컴포넌트: 테이블 컬럼 7개, 조건부 버튼
4. 페이지 타입: List
5. 시나리오 생성: 001-010번 (동적)
6. 저장: /Users/jb/Desktop/test-scenarios/admin-member-management-scenario.md
7. Playwright 검증 확인 → 사용자 선택

### 예시 2: Detail 페이지 시나리오 생성
```bash
/e2e-runner admin/member-management/$id
```

**실행 과정**:
1. 경로 매핑: apps/admin/src/app/member-management/$id/page.tsx
2. 코드 분석:
   - 조건부 액션: PENDING → 승인/거부, APPROVED → 취소
   - 권한 체크: DELETE 권한
3. 페이지 타입: Detail
4. 시나리오 생성:
   - 001: 상세 페이지 로딩
   - 002-003: PENDING 상태 승인/거부
   - 004: APPROVED 상태 취소
   - 005-006: DELETE 권한별 버튼 표시
5. 저장 및 검증

### 예시 3: Create 페이지 시나리오 생성
```bash
/e2e-runner admin/member-management/create
```

**실행 과정**:
1. 경로 매핑: apps/admin/src/app/member-management/create/page.tsx
2. 코드 분석:
   - Zod 스키마: name (min 1, max 50), email (email 형식)
3. 페이지 타입: Create
4. 시나리오 생성:
   - 001: 폼 로딩
   - 002: name 필수 검증
   - 003: name 최대 길이 검증
   - 004: email 형식 검증
   - 005: 유효값 제출 성공
5. 저장 및 검증

### 예시 4: 시나리오 검증만 실행
```bash
/e2e-runner validate ./scenarios/admin-member-management-scenario.md
```

**실행 과정**:
1. 마크다운 파일 읽기
2. Playwright MCP 도구 로드
3. 시나리오 파싱
4. 브라우저에서 실행
5. 검증 리포트 생성

---

## 주의사항

1. **프로젝트 경로**: config.json의 `project.rootPath`가 정확해야 함
2. **테스트 계정**: 실제 로그인 가능한 계정 정보 필요
3. **로컬 서버**: Playwright 검증 시 앱이 실행 중이어야 함
4. **코드 변경**: 코드 변경 시 시나리오 재생성 필요
5. **Notion 연동 없음**: 이 스킬은 Notion DB와 연동하지 않음 (순수 마크다운)

---

## 향후 확장

- Notion DB 연동 (test-scenario-generator처럼)
- 코드 변경 감지 시 자동 업데이트
- 다중 프로젝트 지원
- AI 기반 시나리오 품질 개선
