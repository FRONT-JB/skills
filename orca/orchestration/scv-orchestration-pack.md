# scv 조율 모드 팩 (사용자 맞춤)

> **버전:** packVersion **1.3.4** (한 줄 연출 · 한글 task/wait · orchestration 동작 불변)  
> **파일 SSOT (repo):** `$HOME/Desktop/jb/skills/orca/skills/scv/`  
> **Install:** `$HOME/.orca/scv/` · Grok mirror `$HOME/.grok/skills/scv/SKILL.md`

이 문서는 **설치 포인터**입니다. 행동 계약 본문은 소스 트리에 있습니다.

| 파일 | 역할 |
|------|------|
| `PLAYBOOK.md` | 행동 계약 SSOT |
| `meta.json` | 워커·wait·speed·midRunReclaim 설정 |
| `LESSONS.md` | 런타임 하드 리스트 (짧게) |
| `LESSONS-archive.md` | 과거 사고 로그 (필독 아님) |
| `SKILL.md` | Grok 스킬 엔트리 (설치본과 mirror 동일) |
| `prompts/quick-command.txt` | Orca Quick Command (≡ CANONICAL) |
| `scv-selfcheck.sh` | 설치 검증 |
| `sync-from-source.sh` | repo → `~/.orca/scv` + mirror |

## 설치

```bash
"$HOME/Desktop/jb/skills/orca/skills/scv/sync-from-source.sh"
```

또는:

```bash
rsync -a --delete \
  "$HOME/Desktop/jb/skills/orca/skills/scv/" \
  "$HOME/.orca/scv/"
mkdir -p "$HOME/.grok/skills/scv"
cp "$HOME/.orca/scv/SKILL.md" "$HOME/.grok/skills/scv/SKILL.md"
"$HOME/.orca/scv/scv-selfcheck.sh"
```

Orca가 실행 중이면 Quick Command in-memory 덮어쓰기에 주의. UI 반영 시 Orca 완전 종료 후:

```bash
"$HOME/.orca/scv/sync-quick-command-to-orca.sh"
```

## 요약 (불변)

| 항목 | 값 |
|------|-----|
| 표시 이름 | scv |
| packVersion | 1.3.4 |
| 채팅 연출 | `**【 한글 】** "scv_line" — 요약 · 다음: …` |
| 탭 / display-name | 한글 고정 (`계획 작성` …) |
| wait Tasks | `계획 작성 완료 대기 (worker_done)` |
| 팀장 | Grok · supervised |
| 교차 검증 | plan Claude/Codex · code Codex/Claude |
| Intake | prompt-first |
| 말미 | AUDIT → RECLAIM → CLOSING → FINAL |
| Audit | time / stability only · 고도화 금지 |
| Speed | step-preserving only |

**상세 규칙·CLI·run.json 스키마는 `PLAYBOOK.md`를 연다.** 이 파일에 PLAYBOOK 전문을 복제하지 않는다.
