# 경로 매핑 규칙

이 문서는 사용자가 입력한 경로(`admin/member-management`, `b2c/product/[id]`)를 실제 파일 경로로 매핑하는 규칙을 정의합니다.

## Admin (TanStack Router)

### 기본 원칙
- **라우팅 방식**: TanStack Router (파일 기반)
- **동적 라우트**: `$id`, `$slug` 등 `$` prefix 사용
- **경로 매핑**: 직접 매핑 (Route Groups 없음)

### 매핑 예시

#### 정적 경로
```
입력: admin/member-management
파일: apps/admin/src/app/member-management/page.tsx
```

#### 동적 경로
```
입력: admin/products/$id
파일: apps/admin/src/app/products/$id/page.tsx
```

#### 중첩 경로
```
입력: admin/products/$id/detail
파일: apps/admin/src/app/products/$id/detail/page.tsx
```

### 매핑 알고리즘
1. 앱 prefix 추출 (`admin`)
2. config에서 `apps.admin.appPath` 로드
3. 경로 조합: `{projectRoot}/{appPath}/{route}/page.tsx`
4. 파일 존재 확인

---

## B2C (Next.js App Router)

### 기본 원칙
- **라우팅 방식**: Next.js App Router (파일 기반)
- **동적 라우트**: `[id]`, `[slug]` 등 대괄호 사용
- **Route Groups**: `(groupName)` 형태로 URL에 포함되지 않는 그룹
- **경로 매핑**: 직접 시도 → 실패 시 glob으로 Route Groups 탐색

### 매핑 예시

#### 정적 경로 (Route Groups 없음)
```
입력: b2c/product
파일: apps/b2c/src/app/product/page.tsx
```

#### 동적 경로
```
입력: b2c/product/[id]
파일: apps/b2c/src/app/product/[id]/page.tsx
```

#### Route Groups 포함 경로
```
입력: b2c/my-page/info/coupon
Glob: apps/b2c/src/app/my-page/**/info/coupon/page.tsx
발견: apps/b2c/src/app/my-page/(user-info)/info/coupon/page.tsx

URL에는 /my-page/info/coupon으로 접근
파일 경로에는 (user-info) 그룹 포함
```

### 매핑 알고리즘
1. 앱 prefix 추출 (`b2c`)
2. config에서 `apps.b2c.appPath` 로드
3. **직접 매핑 시도**: `{projectRoot}/{appPath}/{route}/page.tsx`
4. **파일 존재 확인**
5. **실패 시 glob 검색**:
   - 경로를 `/`로 분할
   - 각 세그먼트 사이에 `**/` 삽입
   - 패턴: `{appPath}/{seg1}/**/{seg2}/**/{segN}/page.tsx`
   - Route Groups `(*)` 자동 탐색
6. 발견된 파일 사용

### Route Groups 처리 예시

#### 예시 1: 단일 그룹
```
입력: b2c/my-page/info
Glob: apps/b2c/src/app/my-page/**/info/page.tsx
매칭: apps/b2c/src/app/my-page/(user-info)/info/page.tsx
```

#### 예시 2: 중첩 그룹
```
입력: b2c/product/category/detail
Glob: apps/b2c/src/app/product/**/category/**/detail/page.tsx
매칭: apps/b2c/src/app/product/(listing)/category/(item)/detail/page.tsx
```

#### 예시 3: 동적 경로 + Route Groups
```
입력: b2c/product/[id]/review
Glob: apps/b2c/src/app/product/[id]/**/review/page.tsx
매칭: apps/b2c/src/app/product/[id]/(detail)/review/page.tsx
```

---

## Path Alias 해석

### 원칙
- Import 문에서 `@alias` 형태의 경로를 실제 파일 경로로 변환
- config.json의 `pathAliases` 매핑 사용
- 프로젝트 루트와 앱 경로 기준으로 절대 경로 생성

### 해석 예시

#### Admin 앱
```typescript
// 코드에서
import { userService } from '@services/user';
import { Button } from '@components/ui/Button';

// config.json
"pathAliases": {
  "@services": "src/services",
  "@components": "src/components"
}

// 실제 파일 경로
→ /Users/jb/Desktop/company/ridenow-frontend/apps/admin/src/services/user
→ /Users/jb/Desktop/company/ridenow-frontend/apps/admin/src/components/ui/Button
```

#### B2C 앱
```typescript
// 코드에서
import { ProductService } from '@services/product';
import { useAuth } from '@hooks/useAuth';

// config.json
"pathAliases": {
  "@services": "src/services",
  "@hooks": "src/hooks"
}

// 실제 파일 경로
→ /Users/jb/Desktop/company/ridenow-frontend/apps/b2c/src/services/product
→ /Users/jb/Desktop/company/ridenow-frontend/apps/b2c/src/hooks/useAuth
```

### 해석 알고리즘
1. Import 문에서 `@alias/path` 추출
2. config에서 해당 alias의 실제 경로 찾기
3. 절대 경로 생성: `{projectRoot}/apps/{app}/{aliasPath}/{path}`
4. 확장자 추가 (`.ts`, `.tsx` 등) 및 파일 존재 확인

---

## 에러 처리

### 파일을 찾을 수 없는 경우
1. 입력 경로 검증 (앱 prefix 확인)
2. 직접 매핑 시도
3. glob 검색 (B2C의 경우)
4. 모두 실패 시 에러 메시지:
   ```
   ❌ 페이지 파일을 찾을 수 없습니다.
   입력 경로: {route}
   시도한 경로:
   - {directPath}
   - {globPattern}

   확인 사항:
   1. 경로가 올바른지 확인
   2. page.tsx 파일이 존재하는지 확인
   3. Route Groups이 있다면 glob 패턴 확인
   ```

### 잘못된 앱 prefix
```
입력: mobile/product
→ ❌ 지원하지 않는 앱입니다: mobile
→ 사용 가능한 앱: admin, b2c
```

### Path Alias 해석 실패
```
import from '@unknown/path'
→ ⚠️ 알 수 없는 alias: @unknown
→ config.json의 pathAliases에 추가 필요
```

---

## 요약

| 항목 | Admin | B2C |
|------|-------|-----|
| 라우터 | TanStack Router | Next.js App Router |
| 동적 경로 | `$id` | `[id]` |
| Route Groups | 없음 | `(groupName)` |
| 매핑 방식 | 직접 매핑 | 직접 → glob |
| Path Alias | 지원 | 지원 |
