# Claude Code Skills

Claude Code에서 사용하는 커스텀 스킬 모음 레포지토리.

## Skills 목록

| 스킬 | 설명 |
|------|------|
| [test-scenario-generator](./.claude/skills/test-scenario-generator/) | Playwright로 웹 페이지를 분석하고 E2E 테스트 시나리오를 자동 생성하여 Notion DB에 등록 |
| [feature-planner](./.claude/skills/feature-planner/) | TDD 기반의 단계별 기능 구현 계획 생성. Red-Green-Refactor 사이클을 따르며 품질 게이트로 각 단계 검증 |

## 디렉토리 구조

```
.claude/
├── statusline.sh
└── skills/
    ├── feature-planner/
    │   ├── SKILL.md
    │   └── references/
    │       └── plan-template.md
    └── test-scenario-generator/
        ├── SKILL.md
        └── references/
            ├── scenario-patterns.md
            └── db-schema.md
```

## 스킬 구조

각 스킬은 아래 구조를 따릅니다.

```
.claude/skills/<skill-name>/
├── SKILL.md              # 스킬 정의 (메타데이터 + 워크플로우)
└── references/           # 참조 자료 (스키마, 패턴, 템플릿 등)
```

| 파일 | 역할 |
|------|------|
| `SKILL.md` | Claude Code가 스킬을 인식하고 실행하는 진입점 (상단에 `---`로 감싼 name, description 메타데이터 필수) |
| `references/` | 스킬 실행 시 참조하는 보조 자료 (데이터베이스 스키마, 템플릿 등) |

## 사용법

이 repository는 `.claude` 폴더에 skills가 이미 구성되어 있습니다.

### 다른 프로젝트에서 사용하기

1. 이 레포지토리를 클론합니다.
2. 필요한 스킬을 다른 프로젝트의 `.claude/skills/` 경로에 복사하거나 심볼릭 링크합니다.
   ```bash
   ln -s /path/to/this/repo/.claude/skills/feature-planner /path/to/your/project/.claude/skills/feature-planner
   ```
3. 각 스킬의 SKILL.md를 참고하여 필요한 MCP 서버 및 설정을 완료합니다.