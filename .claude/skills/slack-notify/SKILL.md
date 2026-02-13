---
name: slack-notify
description: JSON 템플릿 기반 Slack 알림 메시지 전송 스킬. Block Kit 형식의 구조화된 메시지를 지원하며, 템플릿 추가 및 커스터마이징이 가능합니다.
user-invocable: true
---

# Purpose

JSON 템플릿 파일을 사용하여 Slack으로 구조화된 알림 메시지를 전송합니다. Block Kit 형식으로 가독성 높은 메시지를 제공합니다.

## 주요 기능

- ✅ **JSON 템플릿 시스템**: 외부 JSON 파일로 템플릿 관리 및 확장 가능
- 📝 **Slack Block Kit 포맷**: 구조화된 메시지, 버튼, 필드 지원
- 🔄 **자동 재시도**: Slack 전송 실패 시 1회 재시도
- 🎨 **템플릿 커스터마이징**: JSON 파일 수정만으로 메시지 포맷 변경 가능
- 🔗 **Slack API 직접 호출**: curl을 통한 안정적인 메시지 전송

# Workflow

## Step 1: Slack 설정 로드

`slack-config.json` 파일에서 Slack 설정을 로드합니다.

**설정 파일 위치**: `.claude/skills/slack-notify/slack-config.json`

**구현 방법**: 설정 파일 읽기

```typescript
// slack-config.json 파일 경로
const configPath = ".claude/skills/slack-notify/slack-config.json";

// 설정 파일 읽기
const config = JSON.parse(await readFile(configPath));

// 필수 값 추출
const botToken = config.botToken;
const defaultChannel = config.defaultChannel;
const retryCount = config.retryCount || 1;
const timeout = config.timeout || 10000;

// 검증
if (!botToken || !botToken.startsWith("xoxb-")) {
  throw new Error("유효한 Slack Bot Token이 설정되지 않았습니다.");
}
```

**설정 파일 구조**:

```json
{
  "botToken": "xoxb-YOUR-BOT-TOKEN-HERE",
  "defaultChannel": "YOUR_CHANNEL_ID",
  "retryCount": 1,
  "timeout": 10000,
  "teamId": "YOUR_TEAM_ID"
}
```

**참고**: 실제 설정은 `slack-config.json` 파일에 저장하고, 이 파일은 `.gitignore`에 추가되어 Git에 커밋되지 않습니다.

**에러 처리**:

- 설정 파일이 없는 경우: 설정 파일 생성 가이드 제공
- Bot Token이 없는 경우: 명확한 설정 가이드 제공
- 잘못된 형식인 경우: JSON 파싱 에러 메시지 표시

**검증 기준**:

- Bot Token이 `xoxb-`로 시작하는 유효한 형식
- 설정 파일이 존재하고 올바른 JSON 구조를 가짐
- defaultChannel이 C로 시작하는 11자리 ID

## Step 2: 파라미터 파싱

사용자 입력을 파싱하고 검증합니다.

**입력 형식**:

```bash
/slack-notify <template_name> --context '<key>:<value>,<key>:<value>' [--channel <channel_id>]
```

**파싱 대상**:

1. **템플릿 이름** (필수): 첫 번째 위치 인자 (templates/ 디렉토리의 JSON 파일명)
2. **Context** (필수): `--context` 플래그 이후의 문자열
3. **채널 ID** (선택): `--channel` 플래그 이후의 문자열. 생략 시 `slack-config.json`의 `defaultChannel` 사용

**채널 ID 결정 로직**:

```typescript
// --channel 플래그가 있으면 사용, 없으면 defaultChannel 사용
const channelId = args.channel || config.defaultChannel;

if (!channelId) {
  throw new Error("채널 ID가 지정되지 않았고, slack-config.json에도 defaultChannel이 설정되지 않았습니다.");
}
```

**유효성 검사**:

- 템플릿 파일이 존재하는지 확인 (`templates/{template_name}.json`)
- 채널 ID가 제공되었거나 defaultChannel이 설정되어 있는지 확인
- 채널 ID가 올바른 형식인지 확인 (C로 시작하는 11자리 ID)

**에러 메시지**:

```
❌ 템플릿 파일을 찾을 수 없습니다: test-scenario-failed.json

사용 가능한 템플릿:
  • test-scenario-failed - 테스트 시나리오 실패 알림
  • ui-issue - UI 이슈 알림
  • performance-issue - 성능 이슈 알림
  • crash-report - 크래시 리포트
  • data-validation-error - 데이터 검증 오류

예시 1 (채널 ID 지정):
  /slack-notify test-scenario-failed --context 'scenario_id:MBR-012,...' --channel YOUR_CHANNEL_ID

예시 2 (defaultChannel 사용):
  /slack-notify test-scenario-failed --context 'scenario_id:MBR-012,...'
```

## Step 3: 템플릿 파일 로드

지정된 템플릿 이름에 해당하는 JSON 파일을 로드합니다.

**템플릿 파일 경로**: `.claude/skills/slack-notify/templates/{template_name}.json`

**검증 로직**:

```typescript
const templatePath = `.claude/skills/slack-notify/templates/${templateName}.json`;

// 파일 존재 확인
if (!fs.existsSync(templatePath)) {
  throw new Error(`템플릿 파일을 찾을 수 없습니다: ${templateName}.json`);
}

// JSON 파일 읽기
const templateContent = await readFile(templatePath);
const template = JSON.parse(templateContent);

// 템플릿 구조 검증
if (!template.blocks || !Array.isArray(template.blocks)) {
  throw new Error(
    `템플릿 파일 형식이 올바르지 않습니다: blocks 배열이 필요합니다.`,
  );
}
```

**템플릿 JSON 구조**:

```json
{
  "name": "template-name",
  "description": "템플릿 설명",
  "fallbackText": "fallback 텍스트 (변수: {variable_name})",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "헤더 텍스트"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*라벨:*\n{variable_name}"
        }
      ]
    }
  ]
}
```

**에러 처리**:

- 파일이 없는 경우: 사용 가능한 템플릿 목록 표시
- JSON 파싱 실패: 파일 형식 오류 안내
- 필수 필드 누락: 구조 검증 실패 메시지

## Step 4: Context 변수 추출

Context 문자열을 파싱하여 변수로 변환합니다.

**Context 형식**: `key1:value1,key2:value2,key3:value3`

**파싱 로직**:

```typescript
const contextMap: Record<string, string> = {};

if (context) {
  const pairs = context.split(",");
  for (const pair of pairs) {
    const [key, ...valueParts] = pair.split(":");
    const value = valueParts.join(":"); // 값에 콜론이 있을 수 있음
    contextMap[key.trim()] = value.trim();
  }
}
```

**공통 변수**:

```typescript
const branch = contextMap.branch || "unknown";
const buildTime = contextMap.time || "N/A";
const commitMsg = contextMap.commit || "N/A";
const errorMsg = contextMap.error || "N/A";
const env = contextMap.env || "production";
const customMsg = contextMap.message || "";
```

**테스트 시나리오 관련 변수**:

```typescript
const scenarioId = contextMap.scenario_id || "N/A";
const scenarioName = contextMap.scenario_name || "N/A";
const category = contextMap.category || "N/A";
const errorType = contextMap.error_type || "버그";
const notionLink = contextMap.notion_link || "";
const priority = contextMap.priority || ""; // 선택적, 없으면 error_type 기반 자동 판단
```

**Custom 템플릿 검증**:

```typescript
if (templateType === "custom" && !customMsg) {
  throw new Error(
    "custom 템플릿은 --context에 'message' 키가 필요합니다.\n\n예시:\n  /slack-notify custom --context 'message:작업이 완료되었습니다!' --channel C0AECLWF92B",
  );
}
```

## Step 5: 템플릿 변수 치환 및 메시지 생성

JSON 템플릿의 변수를 실제 값으로 치환하여 Slack Block Kit 메시지를 생성합니다.

**변수 치환 규칙**:

- 템플릿 JSON의 `{variable_name}` 형식을 Context 값으로 치환
- fallbackText와 blocks 내 모든 text 필드에 적용
- 조건부 블록 처리 (예: notion_link가 없으면 actions 블록 제거)

### 5.1 변수 준비 및 추가 처리

Context에서 추출한 변수를 템플릿에 맞게 준비하고, 필요시 추가 처리를 수행합니다.

**test-scenario-failed 템플릿의 예시**:

```typescript
// Context에서 추출한 값들
const variables = {
  scenario_id: contextMap.scenario_id || "N/A",
  scenario_name: contextMap.scenario_name || "N/A",
  category: contextMap.category || "N/A",
  error_type: contextMap.error_type || "버그",
  error: contextMap.error || "N/A",
  time: contextMap.time || "N/A",
  notion_link: contextMap.notion_link || "",
};

// 우선순위 자동 판단 (priority 값이 없는 경우)
if (!contextMap.priority) {
  variables.priority = determinePriorityFromErrorType(variables.error_type);
} else {
  variables.priority = contextMap.priority;
}

// 우선순위 라벨 매핑
variables.priority_label = getPriorityLabel(variables.priority);

// 헬퍼 함수들
function getPriorityLabel(priority: string): string {
  const labels = {
    P0: "긴급",
    P1: "높음",
    P2: "보통",
    P3: "낮음",
    P4: "매우 낮음",
  };
  return labels[priority] || "보통";
}

function determinePriorityFromErrorType(errorType: string): string {
  const normalized = errorType.toLowerCase();
  if (
    normalized.includes("javascript") ||
    normalized.includes("크래시") ||
    normalized.includes("crash")
  ) {
    return "P0";
  }
  if (
    normalized.includes("기능") ||
    normalized.includes("functional") ||
    normalized.includes("타임아웃")
  ) {
    return "P1";
  }
  if (
    normalized.includes("ui") ||
    normalized.includes("성능") ||
    normalized.includes("performance")
  ) {
    return "P2";
  }
  return "P1";
}
```

### 5.2 변수 치환 수행

템플릿 JSON의 모든 `{variable_name}` 패턴을 실제 값으로 치환합니다.

```typescript
// JSON 전체를 문자열로 변환 후 치환
let templateStr = JSON.stringify(template);

// 모든 변수 치환
for (const [key, value] of Object.entries(variables)) {
  const pattern = new RegExp(`\\{${key}\\}`, "g");
  templateStr = templateStr.replace(pattern, value);
}

// 다시 JSON으로 파싱
const processedTemplate = JSON.parse(templateStr);
```

### 5.3 조건부 블록 처리

특정 조건에 따라 블록을 제거하거나 추가합니다.

```typescript
// notion_link가 없으면 actions 블록 제거
if (!variables.notion_link) {
  processedTemplate.blocks = processedTemplate.blocks.filter(
    (block) => block.type !== "actions",
  );
}
```

### 5.4 최종 메시지 객체 생성

Slack API로 전송할 최종 메시지 객체를 생성합니다.

```typescript
const message = {
  text: processedTemplate.fallbackText, // 알림 미리보기용
  blocks: processedTemplate.blocks, // Block Kit 구조
};
```

## Step 6: 채널 ID 확인

채널 ID가 올바른 형식인지 확인합니다.

**Slack 채널 ID 형식**:

- C로 시작하는 11자리 ID (예: `C0AECLWF92B`)
- 또는 채널명 (예: `#general`) - MCP가 자동 변환

**검증 로직**:

```typescript
// 채널 ID 검증 (C로 시작하거나 #으로 시작)
if (!channelId || (!channelId.startsWith("C") && !channelId.startsWith("#"))) {
  console.warn(`⚠️ 채널 ID 형식이 올바르지 않을 수 있습니다: ${channelId}`);
  console.warn(
    `올바른 형식: C로 시작하는 11자리 ID (예: C0AECLWF92B) 또는 #채널명`,
  );
}
```

**참고**: Slack MCP는 채널명을 자동으로 채널 ID로 변환하므로, 형식이 다르더라도 전송을 시도합니다.

## Step 7: Slack 메시지 전송

Slack API를 curl로 직접 호출하여 메시지를 전송합니다.

**curl 호출**:

```bash
curl -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"channel\": \"${channelId}\",
    \"text\": \"${message}\"
  }"
```

**구현 방법**: `Bash` 도구 사용

```typescript
// Block Kit 형식의 메시지 payload 생성
const payload = JSON.stringify({
  channel: channelId,
  text: message.text, // fallback text (알림 미리보기)
  blocks: message.blocks, // Block Kit 구조
});

// curl 실행
const result = await Bash({
  command: `curl -s -X POST https://slack.com/api/chat.postMessage \\
    -H "Authorization: Bearer ${botToken}" \\
    -H "Content-Type: application/json" \\
    -d '${payload.replace(/'/g, "'\\''")}'`,
  description: "Slack API로 Block Kit 메시지 전송",
});
```

**응답 검증**:

```typescript
const response = JSON.parse(result);

if (response.ok) {
  console.log("✅ Slack 메시지 전송 완료");
  console.log(`📱 채널: ${channelId}`);
  console.log(`📋 템플릿: ${templateType}`);
  console.log(`🔗 메시지: ${response.message_link || "N/A"}`);
} else {
  throw new Error(
    `Slack 메시지 전송 실패: ${response.error || "Unknown error"}`,
  );
}
```

**에러 유형**:

- `channel_not_found`: 채널 ID가 잘못됨
- `not_in_channel`: Bot이 채널에 추가되지 않음
- `invalid_auth`: Bot Token이 유효하지 않음
- `account_inactive`: Slack Workspace가 비활성화됨

## Step 8: 에러 재시도

Slack 전송 실패 시 1회 재시도합니다.

**재시도 로직**:

```bash
# Bash에서 재시도 구현
MAX_RETRIES=1
RETRY_COUNT=0

while [ $RETRY_COUNT -le $MAX_RETRIES ]; do
  RESPONSE=$(curl -s -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"channel\":\"${CHANNEL_ID}\",\"text\":\"${MESSAGE}\"}")

  if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Slack 메시지 전송 완료"
    echo "$RESPONSE" | grep -o '"ts":"[^"]*"'
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
      echo "❌ Slack 메시지 전송 실패 (재시도 ${MAX_RETRIES}회 초과)"
      echo "에러: $(echo "$RESPONSE" | grep -o '"error":"[^"]*"')"
      exit 1
    else
      echo "⚠️ 전송 실패, 재시도 중... (${RETRY_COUNT}/${MAX_RETRIES})"
      sleep 1
    fi
  fi
done
```

**TypeScript 구현 (권장)**:

```typescript
let retryCount = 0;
const MAX_RETRIES = 1;

while (retryCount <= MAX_RETRIES) {
  try {
    const curlResult = await Bash({
      command: `curl -s -X POST https://slack.com/api/chat.postMessage \\
        -H "Authorization: Bearer ${botToken}" \\
        -H "Content-Type: application/json" \\
        -d '{"channel":"${channelId}","text":"${escapedMessage}"}'`,
    });

    const response = JSON.parse(curlResult);

    if (response.ok) {
      console.log("✅ Slack 메시지 전송 완료");
      break;
    } else {
      throw new Error(response.error || "Unknown error");
    }
  } catch (error) {
    retryCount++;
    if (retryCount > MAX_RETRIES) {
      console.error(`❌ Slack 메시지 전송 실패 (재시도 ${MAX_RETRIES}회 초과)`);
      console.error(`에러: ${error.message}`);
      throw error;
    } else {
      console.warn(`⚠️ 전송 실패, 재시도 중... (${retryCount}/${MAX_RETRIES})`);
      // 1초 대기 후 재시도
    }
  }
}
```

**재시도 조건**:

- 네트워크 일시적 오류
- Rate limit (429 에러)
- 기타 일시적 오류

**재시도 하지 않는 경우**:

- 채널 ID 오류 (`channel_not_found`)
- 권한 오류 (`not_in_channel`, `invalid_auth`)
- 영구적 오류

## Step 9: 성공 메시지 출력

최종 성공 메시지를 출력합니다.

**출력 형식**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Slack 알림 전송 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 템플릿: <template_type>
📱 채널: <channel_id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

# Usage Examples

## 예시 1: test-scenario-failed 템플릿 (채널 ID 지정)

```bash
/slack-notify test-scenario-failed \
  --context 'scenario_id:MBR-012,scenario_name:회원정보 수정,category:회원 관리,error_type:JavaScript 에러,error:Cannot read property id of undefined,time:8s,notion_link:https://www.notion.so/...' \
  --channel YOUR_CHANNEL_ID
```

## 예시 2: defaultChannel 사용 (채널 ID 생략)

```bash
/slack-notify test-scenario-failed \
  --context 'scenario_id:MBR-012,scenario_name:회원정보 수정,category:회원 관리,error_type:JavaScript 에러,error:Cannot read property id of undefined,time:8s,notion_link:https://www.notion.so/...'
```

**Slack 메시지 (Block Kit 형식):**

- **Header**: 🐛 테스트 실패 알림
- **Fields (2x2 layout)**:
  - 시나리오: `MBR-012 - 회원정보 수정`
  - 분류: `회원 관리 > JavaScript 에러`
  - 우선순위: `P0 - 긴급`
  - 환경: `🌐 웹`
- **문제 상황**: 코드 블록으로 에러 메시지 표시
- **버튼**: 📋 Notion 이슈 (클릭 시 Notion 페이지로 이동)

# 템플릿 추가 방법

새 템플릿을 추가하려면 `templates/` 디렉토리에 JSON 파일을 생성하세요:

```json
{
  "name": "new-template",
  "description": "새 템플릿 설명",
  "fallbackText": "fallback 텍스트 {variable}",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "헤더 텍스트"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*라벨:*\n{variable}"
        }
      ]
    }
  ]
}
```

사용법:

```bash
# 채널 ID 지정
/slack-notify new-template --context 'variable:값' --channel YOUR_CHANNEL_ID

# defaultChannel 사용
/slack-notify new-template --context 'variable:값'
```
