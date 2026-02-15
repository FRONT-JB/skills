# Playwright 검증 가이드

이 문서는 생성된 마크다운 시나리오를 Playwright MCP를 사용하여 실제 브라우저에서 검증하는 방법을 정의합니다.

**선택적 기능**: 사용자가 시나리오 생성 후 Playwright 검증을 원할 때만 실행

---

## 검증 프로세스

### 1. 사용자 확인
시나리오 파일 생성 완료 후:
```
✅ 시나리오 파일 생성 완료: {파일 경로}

🤖 생성된 시나리오를 Playwright로 검증할까요?
- Yes: Playwright MCP로 브라우저 자동 테스트 실행
- No: 종료
```

### 2. Playwright MCP 도구 로드
```
ToolSearch를 사용하여 Playwright 도구 로드:
- browser_navigate
- browser_click
- browser_fill_form
- browser_snapshot
- browser_take_screenshot
```

### 3. 마크다운 파싱
생성된 마크다운 파일을 읽어서 실행 가능한 단계로 변환

**파싱 규칙**:
```markdown
### 001: 페이지 기본 로딩
**테스트 절차**:
1. 회원 관리 메뉴 클릭
2. 필터 영역 확인

→ 파싱 결과:
[
  { type: "click", selector: "a[href='/member-management']" },
  { type: "wait", selector: ".filter-grid" }
]
```

### 4. 단계별 실행
각 시나리오를 순차적으로 실행

---

## 자연어 → Playwright MCP 매핑

### 페이지 이동
```
자연어: "회원 관리 메뉴 클릭"
→ browser_navigate({ url: "{baseUrl}/member-management" })

또는

→ browser_click({ selector: 'a[href="/member-management"]' })
```

### 입력 필드 작성
```
자연어: "회원명 필드에 '홍길동' 입력"
→ browser_fill_form({
    selector: 'input[name="name"]',
    value: '홍길동'
  })

자연어: "이메일 필드에 'test@example.com' 입력"
→ browser_fill_form({
    selector: 'input[name="email"]',
    value: 'test@example.com'
  })
```

### Select 박스 선택
```
자연어: "상태 선택박스에서 '활성' 선택"
→ browser_click({ selector: 'select[name="status"]' })
→ browser_click({ selector: 'option:has-text("활성")' })

또는

→ browser_select_option({
    selector: 'select[name="status"]',
    value: 'ACTIVE'
  })
```

### 버튼 클릭
```
자연어: "적용하기 버튼 클릭"
→ browser_click({ selector: 'button[type="submit"]' })

자연어: "저장 버튼 클릭"
→ browser_click({ selector: 'button:has-text("저장")' })

자연어: "승인 버튼 클릭"
→ browser_click({ selector: 'button:has-text("승인")' })
```

### 요소 표시 확인
```
자연어: "필터 영역 표시 확인"
→ browser_snapshot()
→ 검증: snapshot에 filter 관련 요소 존재 확인

자연어: "테이블에 결과 표시"
→ browser_snapshot()
→ 검증: table 요소 존재 및 행 개수 확인
```

### 에러 메시지 확인
```
자연어: "'필수 항목입니다' 에러 메시지 표시"
→ browser_snapshot()
→ 검증: 에러 메시지 텍스트 존재 확인
```

---

## Selector 전략

### 우선순위
1. **name 속성**: `input[name="email"]`
2. **data-testid**: `[data-testid="submit-button"]`
3. **aria-label**: `button[aria-label="저장"]`
4. **텍스트**: `button:has-text("저장")`
5. **클래스**: `.submit-button` (최후의 수단)

### Admin 앱 (TanStack Router) 주요 Selector
```typescript
// FilterGrid
'.filter-grid'
'input[name="{fieldName}"]'
'select[name="{fieldName}"]'
'button[type="submit"]' // 적용하기 버튼

// DataGrid
'.data-grid'
'table'
'tbody tr'
'td[data-column="{columnId}"]'

// 버튼
'button:has-text("수정")'
'button:has-text("삭제")'
'button:has-text("상세보기")'
```

### B2C 앱 (Next.js) 주요 Selector
```typescript
// 필터
'input[name="{fieldName}"]'
'select[name="{fieldName}"]'

// 폼
'form'
'input[name="{fieldName}"]'
'button[type="submit"]'

// 버튼
'button:has-text("저장")'
'button:has-text("취소")'
```

---

## 검증 로직

### 요소 존재 확인
```typescript
// browser_snapshot() 결과에서 확인
const snapshot = await browser_snapshot();
if (snapshot.includes('filter-grid')) {
  console.log('✅ 필터 영역 표시됨');
} else {
  console.log('❌ 필터 영역 미표시');
}
```

### 텍스트 존재 확인
```typescript
const snapshot = await browser_snapshot();
if (snapshot.includes('필수 항목입니다')) {
  console.log('✅ 에러 메시지 표시됨');
} else {
  console.log('❌ 에러 메시지 미표시');
}
```

### 테이블 행 개수 확인
```typescript
const snapshot = await browser_snapshot();
const rowCount = (snapshot.match(/<tr/g) || []).length - 1; // 헤더 제외
console.log(`테이블 행 개수: ${rowCount}`);
```

---

## 시나리오 실행 예시

### List 페이지 시나리오
```markdown
### 001: 페이지 기본 로딩
**테스트 절차**:
1. 회원 관리 메뉴 클릭
**기대결과**:
- 필터 영역 표시
- 테이블 표시
```

**Playwright 실행**:
```typescript
// Step 1: 페이지 이동
await browser_navigate({
  url: 'http://localhost:5173/member-management'
});

// Step 2: 요소 표시 확인
const snapshot = await browser_snapshot();

// 검증
if (snapshot.includes('filter-grid') && snapshot.includes('data-grid')) {
  console.log('✅ 001: 페이지 기본 로딩 - 성공');
} else {
  console.log('❌ 001: 페이지 기본 로딩 - 실패');
  await browser_take_screenshot({ path: 'failure-001.png' });
}
```

### 필터 검색 시나리오
```markdown
### 002: 회원명 필터 검색
**테스트 절차**:
1. 회원명 필드에 "홍길동" 입력
2. 적용하기 버튼 클릭
**기대결과**:
- 테이블에 "홍길동" 포함 결과만 표시
```

**Playwright 실행**:
```typescript
// Step 1: 입력
await browser_fill_form({
  selector: 'input[name="name"]',
  value: '홍길동'
});

// Step 2: 버튼 클릭
await browser_click({
  selector: 'button[type="submit"]'
});

// 대기 (API 응답)
await new Promise(resolve => setTimeout(resolve, 1000));

// 검증
const snapshot = await browser_snapshot();
if (snapshot.includes('홍길동')) {
  console.log('✅ 002: 회원명 필터 검색 - 성공');
} else {
  console.log('❌ 002: 회원명 필터 검색 - 실패');
  await browser_take_screenshot({ path: 'failure-002.png' });
}
```

### 폼 검증 시나리오
```markdown
### 003: 이름 필드 필수 검증
**테스트 절차**:
1. 이름 필드 비워둠
2. 저장 버튼 클릭
**기대결과**:
- "필수 항목입니다" 에러 메시지 표시
```

**Playwright 실행**:
```typescript
// Step 1: 이름 필드 비워둠 (건너뛰기)

// Step 2: 저장 버튼 클릭
await browser_click({
  selector: 'button[type="submit"]'
});

// 대기 (검증 실행)
await new Promise(resolve => setTimeout(resolve, 500));

// 검증
const snapshot = await browser_snapshot();
if (snapshot.includes('필수 항목') || snapshot.includes('required')) {
  console.log('✅ 003: 이름 필드 필수 검증 - 성공');
} else {
  console.log('❌ 003: 이름 필드 필수 검증 - 실패');
  await browser_take_screenshot({ path: 'failure-003.png' });
}
```

---

## 에러 처리

### 요소를 찾을 수 없는 경우
```typescript
try {
  await browser_click({ selector: 'button:has-text("저장")' });
} catch (error) {
  console.log('❌ 요소를 찾을 수 없습니다: button:has-text("저장")');
  await browser_take_screenshot({ path: 'error-element-not-found.png' });

  // 대체 selector 시도
  try {
    await browser_click({ selector: 'button[type="submit"]' });
  } catch (error2) {
    console.log('❌ 대체 selector도 실패');
  }
}
```

### 타임아웃
```typescript
// 기본 타임아웃: 30초
// 긴 작업의 경우 재시도
let retries = 3;
while (retries > 0) {
  try {
    await browser_click({ selector: 'button:has-text("저장")' });
    break;
  } catch (error) {
    retries--;
    if (retries === 0) {
      console.log('❌ 타임아웃: 3번 재시도 후 실패');
      await browser_take_screenshot({ path: 'error-timeout.png' });
    }
  }
}
```

### 예상 결과 불일치
```typescript
const snapshot = await browser_snapshot();
const expected = '필터 영역 표시';
const actual = snapshot.includes('filter-grid') ? '필터 영역 표시됨' : '필터 영역 미표시';

if (actual !== expected) {
  console.log(`❌ 예상: ${expected}, 실제: ${actual}`);
  await browser_take_screenshot({ path: 'failure-mismatch.png' });
}
```

---

## 검증 리포트 생성

### 리포트 형식
```markdown
# Playwright 검증 리포트

- **검증 일시**: 2026-02-15 14:30:00
- **시나리오 파일**: admin-member-management-scenario.md
- **총 시나리오**: 10개
- **성공**: 8개
- **실패**: 2개

## 성공 시나리오
- ✅ 001: 페이지 기본 로딩
- ✅ 002: 회원명 필터 검색
- ✅ 003: 상태 필터 검색
...

## 실패 시나리오

### ❌ 005: INACTIVE 상태 수정 버튼 미표시
**실패 원인**: 수정 버튼이 여전히 표시됨
**스크린샷**: failure-005.png
**권장 조치**: 조건부 렌더링 로직 확인

### ❌ 008: 나이 최소값 검증
**실패 원인**: 에러 메시지 미표시
**스크린샷**: failure-008.png
**권장 조치**: Zod 스키마 검증 확인
```

---

## 브라우저 설정

### 브라우저 시작
```typescript
// headless 모드 (기본)
await browser_install(); // 필요 시

// 헤드리스 설정은 Playwright MCP가 자동 처리
```

### 브라우저 종료
```typescript
// 검증 완료 후
await browser_close();
```

---

## 주의사항

1. **API 응답 대기**: 버튼 클릭 후 API 응답을 기다려야 하는 경우 적절한 대기 시간 추가
2. **동적 데이터**: 테스트 데이터가 없으면 검증 실패 가능 → 사전에 데이터 준비 필요
3. **Selector 변경**: UI 변경 시 selector가 무효화될 수 있음
4. **타임아웃**: 네트워크 지연 시 타임아웃 발생 가능 → 재시도 로직 추가
5. **권한**: 권한별 시나리오는 계정 전환 필요 (현재 단계에서는 스킵 가능)

---

## 요약

- **선택적 기능**: 사용자가 원할 때만 실행
- **자연어 파싱**: 마크다운 시나리오를 Playwright 명령으로 변환
- **단계별 실행**: 각 시나리오를 순차적으로 실행
- **검증 및 리포트**: 성공/실패 기록 및 스크린샷 캡처
- **에러 처리**: 요소 미발견, 타임아웃, 결과 불일치 처리
