# 코드 분석 가이드

이 문서는 페이지 파일과 관련 컴포넌트/서비스를 분석하여 테스트 시나리오 생성에 필요한 정보를 추출하는 전략을 정의합니다.

## 분석 목표

코드베이스를 분석하여 다음 정보를 추출합니다:

1. **UI 구조**: 필터, 테이블, 폼, 버튼 등
2. **조건부 로직**: if/else, switch, 삼항 연산자, 상태별 분기
3. **검증 규칙**: Zod 스키마, 유효성 검사 로직
4. **권한 체크**: 역할별 UI 노출 조건
5. **상태 전이**: useState, 버튼 활성화 조건
6. **데이터 타입**: enum, 상수, 타입 정의

---

## 파일 읽기 순서

### 1. 페이지 파일 (`page.tsx`)

**목적**: 페이지의 전체 구조와 import 문 파악

**추출 정보**:
- Import 문 (컴포넌트, 서비스, 타입)
- 페이지 타입 (List/Detail/Create/Custom)
- 조건부 렌더링
- 전역 상태 사용 여부

**분석 패턴**:
```typescript
// Import 추출
import { MemberFilter } from './components/MemberFilter';
import { MemberTable } from './components/MemberTable';
import { userService } from '@services/user';

→ 읽어야 할 파일 목록:
  - ./components/MemberFilter.tsx
  - ./components/MemberTable.tsx
  - {projectRoot}/apps/{app}/src/services/user/
```

### 2. 로컬 컴포넌트 (`./components/*.tsx`)

**목적**: UI 요소와 사용자 인터랙션 추출

**주요 컴포넌트 타입**:

#### 2.1 FilterGrid 컴포넌트
```typescript
<FilterGrid
  formList={[
    {
      label: "회원명",
      name: "name",
      formType: "text",
      placeholder: "회원명을 입력하세요"
    },
    {
      label: "상태",
      name: "status",
      formType: "select",
      options: [
        { label: "전체", value: "" },
        { label: "활성", value: "ACTIVE" },
        { label: "비활성", value: "INACTIVE" }
      ]
    },
    {
      label: "가입일",
      name: "signupDate",
      formType: "dateRange"
    }
  ]}
/>
```

**추출 정보**:
- 필터 필드 목록
- 각 필드의 타입 (text, select, dateRange, etc.)
- Select 필드의 options (enum 값)
- Placeholder, validation

**시나리오 생성**:
- 각 필터 필드별 검색 시나리오
- Select 옵션별 필터링 시나리오
- 날짜 범위 검색 시나리오

#### 2.2 DataGrid/Table 컴포넌트
```typescript
<DataGrid
  columns={[
    { id: "seq", header: "회원 ID", accessorKey: "seq" },
    { id: "name", header: "회원명", accessorKey: "name" },
    {
      id: "status",
      header: "상태",
      accessorKey: "status",
      cell: ({ row }) => (
        <Badge variant={row.status === 'ACTIVE' ? 'success' : 'default'}>
          {row.status}
        </Badge>
      )
    },
    {
      id: "actions",
      header: "관리",
      cell: ({ row }) => (
        <>
          {row.status === 'ACTIVE' && (
            <EditButton onClick={() => navigate(`/member/${row.id}`)} />
          )}
          {hasPermission('DELETE') && (
            <DeleteButton onClick={() => handleDelete(row.id)} />
          )}
        </>
      )
    }
  ]}
/>
```

**추출 정보**:
- 테이블 컬럼 목록
- 조건부 렌더링 (상태별 표시)
- 액션 버튼과 조건
- 권한 체크

**시나리오 생성**:
- 테이블 컬럼 표시 확인
- 조건부 버튼 표시 시나리오
- 권한별 버튼 노출 시나리오

#### 2.3 Form 컴포넌트
```typescript
const schema = z.object({
  name: z.string().min(1, "필수 항목").max(50, "최대 50자"),
  email: z.string().email("유효하지 않은 이메일"),
  phone: z.string().regex(/^\d{3}-\d{4}-\d{4}$/, "형식: 000-0000-0000"),
  age: z.number().min(18, "18세 이상").max(100).optional(),
  type: z.enum(['PERSONAL', 'BUSINESS']),
  agree: z.boolean().refine(val => val === true, "필수 동의")
});

<FormField
  name="name"
  label="회원명"
  rules={schema.shape.name}
/>
```

**추출 정보**:
- 필드별 검증 규칙
- Required vs Optional
- Min/Max 제약
- Regex 패턴
- Enum 값
- Custom validation

**시나리오 생성**:
- 필수 필드 미입력 시나리오
- 최소/최대 길이 초과 시나리오
- 형식 오류 시나리오
- Enum 값별 시나리오
- 유효값 제출 성공 시나리오

### 3. 서비스 레이어 (`@services/{domain}/`)

**목적**: API 엔드포인트, 데이터 타입, enum 확인 (참고용)

**주요 파일**:

#### 3.1 `services.ts`
```typescript
export const userService = {
  getUsers: (params: GetUsersParams) => api.get('/users', { params }),
  getUser: (id: string) => api.get(`/users/${id}`),
  createUser: (data: CreateUserDto) => api.post('/users', data),
  updateUser: (id: string, data: UpdateUserDto) => api.put(`/users/${id}`, data),
  deleteUser: (id: string) => api.delete(`/users/${id}`)
};
```

**추출 정보**:
- API 메서드 목록 (참고용, 시나리오에 명시하지 않음)
- 파라미터 타입

#### 3.2 `type.ts`
```typescript
export enum UserStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  PENDING = 'PENDING',
  BLOCKED = 'BLOCKED'
}

export enum UserType {
  PERSONAL = 'PERSONAL',
  BUSINESS = 'BUSINESS'
}

export type User = {
  id: string;
  name: string;
  email: string;
  status: UserStatus;
  type: UserType;
  createdAt: string;
};
```

**추출 정보**:
- Enum 값 목록
- 필드 타입 (string, number, boolean)
- Optional 여부

#### 3.3 `schema.ts`
```typescript
export const createUserSchema = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
  phone: z.string().regex(/^\d{3}-\d{4}-\d{4}$/),
  age: z.number().min(18).max(100).optional(),
  type: z.enum(['PERSONAL', 'BUSINESS']),
  password: z.string()
    .min(8, "최소 8자")
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, "대소문자, 숫자 포함")
});
```

**추출 정보**:
- 필드별 검증 규칙 상세
- 에러 메시지
- 복잡한 validation 로직

---

## 조건부 로직 분석

### 패턴 1: if/else 분기
```typescript
if (status === 'PENDING') {
  return (
    <>
      <Button onClick={approve}>승인</Button>
      <Button onClick={reject}>거부</Button>
    </>
  );
} else if (status === 'APPROVED') {
  return <Button onClick={cancel}>취소</Button>;
} else {
  return <span>처리 완료</span>;
}
```

**추출 정보**:
- 상태별 가능한 액션
- 각 상태에서 표시되는 UI

**시나리오 생성**:
```
- PENDING 상태에서 승인 버튼 클릭
- PENDING 상태에서 거부 버튼 클릭
- APPROVED 상태에서 취소 버튼 클릭
- APPROVED 상태에서 승인/거부 버튼 미표시 확인
- REJECTED 상태에서 모든 액션 버튼 미표시 확인
```

### 패턴 2: switch 문
```typescript
switch (type) {
  case 'PERSONAL':
    return <PersonalForm />;
  case 'BUSINESS':
    return <BusinessForm />;
  default:
    return <DefaultForm />;
}
```

**시나리오 생성**:
```
- 개인회원 타입 선택 시 개인 폼 표시
- 사업자회원 타입 선택 시 사업자 폼 표시
```

### 패턴 3: 조건부 렌더링
```typescript
{hasPermission('EDIT') && <EditButton />}
{role === 'ADMIN' && <DeleteButton />}
{status === 'DRAFT' && <SaveButton />}
```

**시나리오 생성**:
```
- EDIT 권한 있을 때 수정 버튼 표시
- EDIT 권한 없을 때 수정 버튼 미표시
- ADMIN 역할일 때 삭제 버튼 표시
- DRAFT 상태일 때 저장 버튼 표시
```

### 패턴 4: 상태 전이
```typescript
const [step, setStep] = useState(1);

// step 1 → 2 → 3
<Button onClick={() => setStep(2)} disabled={!isStep1Valid}>
  다음
</Button>
```

**시나리오 생성**:
```
- Step 1 유효값 입력 후 다음 버튼 활성화
- Step 1 무효값일 때 다음 버튼 비활성화
- Step 2로 이동 확인
- Step 3까지 진행 완료
```

---

## Zod 검증 규칙 분석

### 기본 타입
```typescript
z.string()     // 문자열
z.number()     // 숫자
z.boolean()    // 불린
z.date()       // 날짜
```

### 제약 조건
```typescript
// 문자열
z.string().min(1, "필수")           // 최소 길이
z.string().max(50, "최대 50자")     // 최대 길이
z.string().email("이메일 형식")      // 이메일
z.string().url()                   // URL
z.string().regex(/^[0-9]+$/)       // 정규식

// 숫자
z.number().min(18, "18세 이상")     // 최소값
z.number().max(100, "100세 이하")   // 최대값
z.number().int()                   // 정수
z.number().positive()              // 양수

// Optional
z.string().optional()              // 선택 항목
z.string().nullable()              // null 허용
z.string().nullish()               // null | undefined 허용

// Enum
z.enum(['A', 'B', 'C'])            // 열거형

// Refine (커스텀 검증)
z.boolean().refine(val => val === true, "필수 동의")
z.string().refine(val => !blacklist.includes(val), "사용 불가")
```

### 시나리오 생성 전략

#### 경계값 테스트
```typescript
z.string().min(2).max(10)

→ 시나리오:
- 1자 입력 → 에러 (min 위반)
- 2자 입력 → 성공 (min 경계)
- 10자 입력 → 성공 (max 경계)
- 11자 입력 → 에러 (max 위반)
```

#### 형식 검증
```typescript
z.string().email()

→ 시나리오:
- "test@example.com" → 성공
- "invalid-email" → 에러
- "test@" → 에러
- "@example.com" → 에러
```

#### Enum 검증
```typescript
z.enum(['PERSONAL', 'BUSINESS'])

→ 시나리오:
- "PERSONAL" 선택 → 성공
- "BUSINESS" 선택 → 성공
- (각 enum 값별 분기 로직 확인)
```

#### 복합 검증
```typescript
z.string()
  .min(8)
  .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)

→ 시나리오:
- "abc" → 에러 (min 위반)
- "abcdefgh" → 에러 (대문자, 숫자 없음)
- "Abcdefgh" → 에러 (숫자 없음)
- "Abcdefg1" → 성공
```

---

## 권한 체크 분석

### 패턴
```typescript
// 함수형 체크
{hasPermission('DELETE') && <DeleteButton />}

// 역할 체크
{user.role === 'ADMIN' && <AdminPanel />}

// 복합 조건
{(hasPermission('EDIT') || user.role === 'ADMIN') && <EditButton />}

// Hook 사용
const { canEdit } = usePermissions();
{canEdit && <EditButton />}
```

### 시나리오 생성
```
- DELETE 권한 있을 때 삭제 버튼 표시
- DELETE 권한 없을 때 삭제 버튼 미표시
- ADMIN 역할일 때 관리자 패널 표시
- 일반 사용자일 때 관리자 패널 미표시
```

---

## 컴포넌트 추적 알고리즘

```
1. page.tsx 읽기
2. import 문 추출
3. 각 import에 대해:
   a. 로컬 컴포넌트 (./components) → 읽기
   b. path alias (@components) → 절대 경로 변환 후 읽기
   c. 서비스 (@services) → services.ts, type.ts, schema.ts 읽기
4. 컴포넌트 파일에서 다시 import 추출 (재귀적)
5. 모든 파일에서 추출한 정보 통합
```

---

## 페이지 타입 판단

### List 페이지
**조건**:
- FilterGrid 또는 Filter 컴포넌트 존재
- DataGrid 또는 Table 컴포넌트 존재
- 페이지네이션 존재 (선택)

**예시**:
```typescript
<FilterGrid formList={...} />
<DataGrid columns={...} data={...} />
```

### Detail 페이지
**조건**:
- 동적 라우트 (`$id`, `[id]`)
- 단일 데이터 표시
- 섹션 구조 (정보, 이력, 관련 데이터 등)

**예시**:
```typescript
// Route: /member/$id
<UserInfo data={user} />
<UserHistory userId={id} />
```

### Create/Edit 페이지
**조건**:
- Form 컴포넌트 존재
- Zod 스키마 사용
- 제출 버튼

**예시**:
```typescript
<Form schema={createUserSchema}>
  <FormField name="name" />
  <FormField name="email" />
  <SubmitButton />
</Form>
```

### Custom 페이지
**조건**:
- 위의 패턴에 해당하지 않는 경우
- 대시보드, 통계, 설정 등

---

## 요약 체크리스트

분석 완료 시 다음 정보를 확보해야 합니다:

- [ ] 페이지 타입 (List/Detail/Create/Custom)
- [ ] UI 요소 목록 (필터, 테이블, 폼, 버튼)
- [ ] 조건부 로직 (if/else, switch, 조건부 렌더링)
- [ ] Zod 검증 규칙 (필드별)
- [ ] 권한 체크 (역할별 UI 노출)
- [ ] 상태 전이 (useState, 버튼 활성화 조건)
- [ ] Enum/상수 값
- [ ] 파일 경로 목록

이 정보를 바탕으로 마크다운 시나리오를 동적으로 생성합니다.
