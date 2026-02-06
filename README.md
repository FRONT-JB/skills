# Claude Code Skills

Claude Code에서 사용하는 커스텀 스킬 모음 레포지토리.

## Skills 목록

| 스킬 | 설명 |
|------|------|
| [test-scenario-generator](./test-scenario-generator/) | Playwright로 웹 페이지를 분석하고 E2E 테스트 시나리오를 자동 생성하여 Notion DB에 등록 |

## 스킬 구조

각 스킬은 아래 구조를 따릅니다.

```
<skill-name>/
├── SKILL.md              # 스킬 정의 (트리거 조건, 워크플로우)
├── README.md             # 사용 가이드
└── references/           # 참조 자료 (스키마, 패턴 등)
```

| 파일 | 역할 |
|------|------|
| `SKILL.md` | Claude Code가 스킬을 인식하고 실행하는 진입점 |
| `README.md` | 사전 요구사항, 설정 방법, 사용 예시 |
| `references/` | 스킬 실행 시 참조하는 보조 자료 |

## 사용법

1. 이 레포지토리를 클론합니다.
2. 사용할 스킬 디렉토리를 프로젝트의 `.claude/skills/` 경로에 복사하거나 심볼릭 링크합니다.
3. 각 스킬의 README.md를 참고하여 필요한 MCP 서버 및 설정을 완료합니다.