# Agent Skills

Orca 조율 모드 팩을 관리하는 레포지토리.

## 구성

### Orca 조율 모드

| 모드 | 설명 |
|------|------|
| [letsgo](./orca/skills/letsgo/) | 코드 변경 조사 → Claude·Codex 병렬 검증 → 문서화 → Revolut 스타일 HTML 생성 → Grok 리뷰를 수행하는 이해 중심 조율 모드 |
| [scv](./orca/skills/scv/) | 기능 출하 하네스: prompt-first intake → Claude plan / Codex plan-review → Codex implement → Claude code-review → release → AUDIT → RECLAIM |

배포용 단일 문서:

- [letsgo-orchestration-pack.md](./orca/orchestration/letsgo-orchestration-pack.md)
- [scv-orchestration-pack.md](./orca/orchestration/scv-orchestration-pack.md)

## 디렉토리 구조

```
.claude/
└── statusline.sh
orca/
├── orchestration/
│   ├── letsgo-orchestration-pack.md
│   └── scv-orchestration-pack.md
└── skills/
    ├── letsgo/
    │   ├── SKILL.md
    │   ├── PLAYBOOK.md
    │   ├── LESSONS.md
    │   ├── DESIGN.md
    │   ├── meta.json
    │   ├── prompts/
    │   │   └── quick-command.txt
    │   └── templates/
    │       ├── README.md
    │       └── explainer.shell.html
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

### Orca 모드 설치

레포지토리 루트에서 공용 패키지를 Orca와 Grok 런타임 경로로 복사합니다.

**letsgo**

```bash
mkdir -p "$HOME/.orca/letsgo" "$HOME/.grok/skills/letsgo"
rsync -a ./orca/skills/letsgo/ "$HOME/.orca/letsgo/"
cp ./orca/skills/letsgo/SKILL.md "$HOME/.grok/skills/letsgo/SKILL.md"
```

이후 `prompts/quick-command.txt`를 Orca 전역 Quick Command로 등록하고 `lets-go`, `letsgo`, `/letsgo`, `이해 리뷰`, `explain-diff` 중 하나로 실행합니다. 자세한 설정과 실행 규칙은 [letsgo README](./orca/skills/letsgo/README.md)를 참고하세요.

**scv**

```bash
mkdir -p "$HOME/.orca/scv" "$HOME/.grok/skills/scv"
rsync -a ./orca/skills/scv/ "$HOME/.orca/scv/"
cp ./orca/skills/scv/SKILL.md "$HOME/.grok/skills/scv/SKILL.md"
```

이후 `prompts/quick-command.txt`를 Orca 전역 Quick Command로 등록하고 `scv`, `/scv`, `scv-harness` 중 하나로 실행합니다. 자세한 설정과 실행 규칙은 [scv README](./orca/skills/scv/README.md)를 참고하세요.
