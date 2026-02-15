# 마크다운 출력 형식 가이드

이 문서는 테스트 시나리오를 마크다운으로 출력할 때의 표준 형식을 정의합니다.

**핵심 원칙**:
- ✅ **마크다운 구조만 통일** (섹션, 필드명, 레이아웃)
- ✅ **내용은 코드 분석 결과에 따라 동적 생성**
- ❌ **고정된 템플릿 사용하지 않음**

---

## 파일 구조

```markdown
# {App} - {Route} 테스트 시나리오

## 메타데이터
[프로젝트 정보]

## 사전 설정
[테스트 계정, URL]

## 테스트 시나리오
[001부터 순차적으로 생성된 시나리오]

## 코드 분석 결과 (참고용)
[분석 결과 요약]
```

---

## 1. 메타데이터 섹션

### 형식
```markdown
## 메타데이터
- **App**: {Admin | B2C}
- **Route**: {경로}
- **생성일**: {YYYY-MM-DD}
- **페이지 타입**: {List | Detail | Create | Custom}
- **분석 파일**:
  - Page: {page.tsx 경로}
  - Components: {개수}개
  - Services: {개수}개
```

### 예시
```markdown
## 메타데이터
- **App**: Admin
- **Route**: /member-management
- **생성일**: 2026-02-15
- **페이지 타입**: List
- **분석 파일**:
  - Page: apps/admin/src/app/member-management/page.tsx
  - Components: 2개 (MemberFilter, MemberTable)
  - Services: 1개 (user)
```

---

## 2. 사전 설정 섹션

### 형식
```markdown
## 사전 설정

### 테스트 계정
- Email: {config.testAccounts에서 가져온 이메일}
- Password: {config.testAccounts에서 가져온 패스워드}

### 테스트 URL
- Base URL: {config.apps[app].baseUrl}
- Full URL: {baseUrl + route}
```

### 예시
```markdown
## 사전 설정

### 테스트 계정
- Email: admin@example.com
- Password: test1234

### 테스트 URL
- Base URL: http://localhost:5173
- Full URL: http://localhost:5173/member-management
```

---

## 3. 테스트 시나리오 섹션

### 핵심 원칙
- **고정 템플릿 없음**: 코드 분석 결과에 따라 매번 다르게 생성
- **번호는 001부터 순차적**: Notion ID가 아님
- **UI 기준 작성**: API 엔드포인트/파라미터 명시하지 않음
- **하나의 목적**: 각 시나리오는 하나의 검증 목적만

### 형식
```markdown
## 테스트 시나리오

### 001: {시나리오명}

**사전조건**:
- {조건 1}
- {조건 2}

**테스트 절차**:
1. {단계 1}
2. {단계 2}
3. ...

**기대결과**:
- {결과 1}
- {결과 2}
- ...

---

### 002: {시나리오명}
...
```

### 시나리오 생성 전략

#### List 페이지 (예시)
코드 분석 결과:
- FilterGrid: name, status, signupDate 필드
- DataGrid: 5개 컬럼, 상태별 액션 버튼
- 페이지네이션 있음

→ 생성되는 시나리오 (예시, 실제는 다를 수 있음):
```markdown
### 001: 페이지 기본 로딩
**사전조건**: 로그인 완료
**테스트 절차**:
1. 회원 관리 메뉴 클릭
**기대결과**:
- 필터 영역 표시
- 테이블 표시
- 페이지네이션 표시

### 002: 회원명 필터 검색
**사전조건**: 001 완료
**테스트 절차**:
1. 회원명 필드에 "홍길동" 입력
2. 적용하기 버튼 클릭
**기대결과**:
- 테이블에 "홍길동" 포함 결과만 표시

### 003: 상태 필터 검색 (ACTIVE)
**사전조건**: 001 완료
**테스트 절차**:
1. 상태 선택박스에서 "활성" 선택
2. 적용하기 버튼 클릭
**기대결과**:
- 테이블에 활성 상태 회원만 표시

### 004: ACTIVE 상태 수정 버튼 표시
**사전조건**: 003 완료
**테스트 절차**:
1. ACTIVE 상태 행 확인
**기대결과**:
- 수정 버튼 표시됨

### 005: INACTIVE 상태 수정 버튼 미표시
**사전조건**: 001 완료
**테스트 절차**:
1. 상태 선택박스에서 "비활성" 선택
2. 적용하기 버튼 클릭
3. INACTIVE 상태 행 확인
**기대결과**:
- 수정 버튼 미표시
```

#### Detail 페이지 (예시)
코드 분석 결과:
- 동적 라우트 /$id
- 조건부 액션: PENDING → 승인/거부, APPROVED → 취소
- 권한 체크: DELETE 권한

→ 생성되는 시나리오:
```markdown
### 001: 상세 페이지 로딩
**사전조건**: 로그인 완료, 회원 ID 존재
**테스트 절차**:
1. 회원 목록에서 특정 회원 클릭
**기대결과**:
- 상세 정보 표시 (이름, 이메일, 전화번호 등)
- 상태 표시

### 002: PENDING 상태 승인 버튼 클릭
**사전조건**: PENDING 상태 회원 상세 페이지
**테스트 절차**:
1. 승인 버튼 클릭
2. 확인 다이얼로그에서 확인 클릭
**기대결과**:
- 상태가 APPROVED로 변경
- 성공 메시지 표시

### 003: PENDING 상태 거부 버튼 클릭
**사전조건**: PENDING 상태 회원 상세 페이지
**테스트 절차**:
1. 거부 버튼 클릭
2. 확인 다이얼로그에서 확인 클릭
**기대결과**:
- 상태가 REJECTED로 변경
- 성공 메시지 표시

### 004: APPROVED 상태 취소 버튼 표시
**사전조건**: APPROVED 상태 회원 상세 페이지
**테스트 절차**:
1. 페이지 로딩 확인
**기대결과**:
- 취소 버튼만 표시
- 승인/거부 버튼 미표시

### 005: DELETE 권한 있을 때 삭제 버튼 표시
**사전조건**: DELETE 권한 있는 계정으로 로그인
**테스트 절차**:
1. 회원 상세 페이지 접속
**기대결과**:
- 삭제 버튼 표시

### 006: DELETE 권한 없을 때 삭제 버튼 미표시
**사전조건**: DELETE 권한 없는 계정으로 로그인
**테스트 절차**:
1. 회원 상세 페이지 접속
**기대결과**:
- 삭제 버튼 미표시
```

#### Create/Edit 페이지 (예시)
코드 분석 결과:
- Zod 스키마: name (min 1, max 50), email (email 형식), age (min 18, max 100, optional)
- type: enum ['PERSONAL', 'BUSINESS']

→ 생성되는 시나리오:
```markdown
### 001: 생성 페이지 로딩
**사전조건**: 로그인 완료
**테스트 절차**:
1. 회원 생성 버튼 클릭
**기대결과**:
- 생성 폼 표시 (이름, 이메일, 나이, 타입 필드)
- 저장 버튼 표시

### 002: 이름 필드 필수 검증
**사전조건**: 001 완료
**테스트 절차**:
1. 이름 필드 비워둠
2. 저장 버튼 클릭
**기대결과**:
- "필수 항목입니다" 에러 메시지 표시

### 003: 이름 필드 최대 길이 검증
**사전조건**: 001 완료
**테스트 절차**:
1. 이름 필드에 51자 입력
2. 저장 버튼 클릭
**기대결과**:
- "최대 50자까지 입력 가능합니다" 에러 메시지 표시

### 004: 이메일 형식 검증
**사전조건**: 001 완료
**테스트 절차**:
1. 이메일 필드에 "invalid-email" 입력
2. 저장 버튼 클릭
**기대결과**:
- "유효하지 않은 이메일 형식입니다" 에러 메시지 표시

### 005: 나이 최소값 검증
**사전조건**: 001 완료
**테스트 절차**:
1. 나이 필드에 "17" 입력
2. 저장 버튼 클릭
**기대결과**:
- "18세 이상만 가입 가능합니다" 에러 메시지 표시

### 006: 나이 최대값 검증
**사전조건**: 001 완료
**테스트 절차**:
1. 나이 필드에 "101" 입력
2. 저장 버튼 클릭
**기대결과**:
- "100세 이하만 입력 가능합니다" 에러 메시지 표시

### 007: 개인회원 타입 선택
**사전조건**: 001 완료
**테스트 절차**:
1. 타입 선택박스에서 "개인회원" 선택
**기대결과**:
- 개인회원 관련 추가 필드 표시 (있다면)

### 008: 사업자회원 타입 선택
**사전조건**: 001 완료
**테스트 절차**:
1. 타입 선택박스에서 "사업자회원" 선택
**기대결과**:
- 사업자회원 관련 추가 필드 표시 (있다면)

### 009: 유효값 제출 성공 (개인회원)
**사전조건**: 001 완료
**테스트 절차**:
1. 이름: "홍길동" 입력
2. 이메일: "test@example.com" 입력
3. 나이: "25" 입력
4. 타입: "개인회원" 선택
5. 저장 버튼 클릭
**기대결과**:
- 성공 메시지 표시
- 목록 페이지로 이동 또는 생성된 회원 상세 페이지로 이동

### 010: 유효값 제출 성공 (사업자회원)
**사전조건**: 001 완료
**테스트 절차**:
1. 이름: "홍길동" 입력
2. 이메일: "test@example.com" 입력
3. 나이: 비워둠 (optional)
4. 타입: "사업자회원" 선택
5. 저장 버튼 클릭
**기대결과**:
- 성공 메시지 표시
- 목록 페이지로 이동 또는 생성된 회원 상세 페이지로 이동
```

---

## 4. 코드 분석 결과 섹션 (참고용)

### 형식
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
- **Page**: {page.tsx 경로}
- **Components**:
  - {Component1.tsx 경로}
  - {Component2.tsx 경로}
- **Services**:
  - {service1 경로}

### UI 요소 분석
{페이지 타입에 따라 다름}

### 조건부 로직 분석
{발견된 조건문이 있으면}

### 검증 규칙 (Zod 스키마)
{발견된 스키마가 있으면}

### 상태/Enum 값
{발견된 enum이나 상태 값이 있으면}
```

### List 페이지 예시
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
- **Page**: apps/admin/src/app/member-management/page.tsx
- **Components**:
  - apps/admin/src/app/member-management/components/MemberFilter.tsx
  - apps/admin/src/app/member-management/components/MemberTable.tsx
- **Services**:
  - apps/admin/src/services/user/services.ts
  - apps/admin/src/services/user/type.ts

### UI 요소 분석

**필터 필드**:
- name (text): 회원명
- phone (text): 전화번호
- status (select): 상태 [전체, 활성, 비활성]
- signupDateHead (date): 가입일 (시작)
- signupDateTail (date): 가입일 (종료)

**테이블 컬럼**:
- seq: 회원 ID
- name: 회원명
- email: 이메일
- phone: 전화번호
- status: 상태
- signupDate: 가입일
- actions: 관리 (조건부 버튼)

**액션 버튼**:
- 수정 버튼 (조건: status === 'ACTIVE')
- 삭제 버튼 (조건: hasPermission('DELETE'))

### 조건부 로직 분석
- **상태별 수정 버튼**: ACTIVE 상태일 때만 수정 버튼 표시
- **권한별 삭제 버튼**: DELETE 권한 있을 때만 삭제 버튼 표시

### 상태/Enum 값
- **UserStatus**: ACTIVE, INACTIVE, PENDING, BLOCKED
```

### Detail 페이지 예시
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
- **Page**: apps/admin/src/app/member-management/$id/page.tsx
- **Components**:
  - apps/admin/src/app/member-management/$id/components/UserInfo.tsx
  - apps/admin/src/app/member-management/$id/components/UserHistory.tsx

### UI 요소 분석

**표시 필드**:
- 회원 ID
- 이름
- 이메일
- 전화번호
- 상태
- 가입일

**액션 버튼**:
- 승인 버튼 (조건: status === 'PENDING')
- 거부 버튼 (조건: status === 'PENDING')
- 취소 버튼 (조건: status === 'APPROVED')
- 삭제 버튼 (조건: hasPermission('DELETE'))

### 조건부 로직 분석
- **PENDING 상태**: 승인/거부 버튼 표시
- **APPROVED 상태**: 취소 버튼만 표시
- **REJECTED/BLOCKED 상태**: 액션 버튼 없음
- **DELETE 권한**: 권한 있을 때만 삭제 버튼 표시

### 상태/Enum 값
- **UserStatus**: ACTIVE, INACTIVE, PENDING, BLOCKED, APPROVED, REJECTED
```

### Create/Edit 페이지 예시
```markdown
## 코드 분석 결과 (참고용)

### 파일 구조
- **Page**: apps/admin/src/app/member-management/create/page.tsx
- **Services**:
  - apps/admin/src/services/user/schema.ts

### UI 요소 분석

**폼 필드**:
- name (text, required): 회원명
  - min: 1자
  - max: 50자
- email (email, required): 이메일
  - 형식: 이메일
- phone (text, optional): 전화번호
  - 형식: 000-0000-0000
- age (number, optional): 나이
  - min: 18
  - max: 100
- type (select, required): 회원 타입
  - 옵션: PERSONAL, BUSINESS

### 검증 규칙 (Zod 스키마)
- **name**:
  - 필수 항목
  - 최소 1자
  - 최대 50자
- **email**:
  - 필수 항목
  - 이메일 형식
- **phone**:
  - 선택 항목
  - 형식: 정규식 `^\d{3}-\d{4}-\d{4}$`
- **age**:
  - 선택 항목
  - 최소값: 18
  - 최대값: 100
- **type**:
  - 필수 항목
  - 가능한 값: PERSONAL, BUSINESS

### 상태/Enum 값
- **UserType**: PERSONAL, BUSINESS
```

---

## 요약

1. **마크다운 구조는 통일** (메타데이터, 사전 설정, 시나리오, 코드 분석 결과)
2. **시나리오 내용은 코드 분석 결과에 따라 매번 다르게 생성**
3. **번호는 001부터 순차적**
4. **UI 기준 작성**, API 상세 내용 제외
5. **하나의 시나리오 = 하나의 검증 목적**
