# Agent Skills

Claude Code 프로젝트 스킬과 Orca 조율 모드 팩을 관리하는 레포지토리.

## 구성

### Claude Code 프로젝트 스킬

| 스킬 | 설명 | 출력 |
|------|------|------|
| [architecture-flow-map](./.claude/skills/architecture-flow-map/) | 현재 코드베이스를 분석해 전체 구조, 유저 액션 flow, 실제 함수·파일 기준 단계를 3패널 인터랙티브 지도로 시각화 | `cache/<slug>.html` |
| [plan-flow-map](./.claude/skills/plan-flow-map/) | 플랜·계획·로드맵·구현계획을 요약, 비교표, API·엔티티 카드, 구현순서, 파일 트리로 구성된 리치 HTML 문서로 시각화 | `cache/<slug>.html` |

두 스킬 모두 결과물을 게시하지 않고 스킬별 `cache/`에 self-contained HTML로 저장하며, 다크·라이트 모드를 지원합니다.

### Orca 조율 모드

| 모드 | 설명 |
|------|------|
| [scv](./orca/skills/scv/) | 기능 출하 하네스: prompt-first intake → Claude plan / Codex plan-review → Codex implement → Claude code-review → release → AUDIT → RECLAIM |

배포용 단일 문서:

- [scv-orchestration-pack.md](./orca/orchestration/scv-orchestration-pack.md)

## 디렉토리 구조

```
.claude/
├── statusline.sh
└── skills/
    ├── architecture-flow-map/
    │   ├── SKILL.md
    │   ├── assets/
    │   │   ├── example-data.json
    │   │   └── template.html
    │   ├── references/
    │   │   └── data-schema.md
    │   └── scripts/
    │       └── build.py
    └── plan-flow-map/
        ├── SKILL.md
        ├── assets/
        │   ├── example-doc.json
        │   └── template.html
        ├── references/
        │   ├── doc-schema.md
        │   └── reshaping-rubric.md
        └── scripts/
            └── build.py
orca/
├── orchestration/
│   └── scv-orchestration-pack.md
└── skills/
    └── scv/
        ├── SKILL.md
        ├── PLAYBOOK.md
        ├── LESSONS.md
        ├── meta.json
        ├── README.md
        ├── prompts/
        │   └── quick-command.txt
        └── templates/
            ├── ARCHITECTURE.ko.md
            └── plan.ko.md
```

## 사용법

### Claude Code 프로젝트 스킬

이 저장소를 Claude Code에서 연 뒤 다음과 같이 요청합니다.

- `architecture-flow-map`: “아키텍처 지도 만들어줘”, “코드베이스 flow 다이어그램 만들어줘”
- `plan-flow-map`: “이 구현 계획을 시각화해줘”, “plan.md를 HTML 문서로 보여줘”

각 스킬의 상세 트리거, 입력 규칙 및 빌드 절차는 해당 `SKILL.md`를 참고하세요. 생성된 `cache/` 디렉터리는 Git에서 제외됩니다.

### Orca 모드 설치

레포지토리 루트에서 공용 패키지를 Orca와 Grok 런타임 경로로 복사합니다.

**scv**

```bash
mkdir -p "$HOME/.orca/scv" "$HOME/.grok/skills/scv"
rsync -a ./orca/skills/scv/ "$HOME/.orca/scv/"
cp ./orca/skills/scv/SKILL.md "$HOME/.grok/skills/scv/SKILL.md"
```

이후 `prompts/quick-command.txt`를 Orca 전역 Quick Command로 등록하고 `scv`, `/scv`, `scv-harness` 중 하나로 실행합니다. 자세한 설정과 실행 규칙은 [scv README](./orca/skills/scv/README.md)를 참고하세요.
