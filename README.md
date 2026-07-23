# Agent Skills

Orca 조율 모드 팩을 관리하는 레포지토리.

## 구성

### Orca 조율 모드

| 모드 | 설명 |
|------|------|
| [scv](./orca/skills/scv/) | 기능 출하 하네스: prompt-first intake → Claude plan / Codex plan-review → Codex implement → Claude code-review → release → AUDIT → RECLAIM |

배포용 단일 문서:

- [scv-orchestration-pack.md](./orca/orchestration/scv-orchestration-pack.md)

## 디렉토리 구조

```
.claude/
└── statusline.sh
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

### Orca 모드 설치

레포지토리 루트에서 공용 패키지를 Orca와 Grok 런타임 경로로 복사합니다.

**scv**

```bash
mkdir -p "$HOME/.orca/scv" "$HOME/.grok/skills/scv"
rsync -a ./orca/skills/scv/ "$HOME/.orca/scv/"
cp ./orca/skills/scv/SKILL.md "$HOME/.grok/skills/scv/SKILL.md"
```

이후 `prompts/quick-command.txt`를 Orca 전역 Quick Command로 등록하고 `scv`, `/scv`, `scv-harness` 중 하나로 실행합니다. 자세한 설정과 실행 규칙은 [scv README](./orca/skills/scv/README.md)를 참고하세요.
