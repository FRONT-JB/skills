# zealot 조율 모드 팩 (사용자 맞춤)

> **버전:** packVersion **1.0.0** · basePackVersion **1.3.9** (scv snapshot + Claude coordinator · Grok-free)  
> **파일 SSOT (repo):** `$HOME/Desktop/jb/skills/orca/skills/zealot/`  
> **Install:** `$HOME/.orca/zealot/` · Claude skill `$HOME/.claude/skills/zealot/` · orch pin `$HOME/.claude/skills/zealot-orchestration/`  
> **계획 초안:** `$HOME/Desktop/jb/skills/orca/skills/zealot-plan-draft.md` (v3.2.2)

이 문서는 **설치 포인터**입니다. 행동 계약 본문은 소스 트리에 있습니다.

| 파일 | 역할 |
|------|------|
| `PLAYBOOK.md` | 행동 계약 SSOT (완전 해결본) |
| `UX.md` | 사용자 대면 연출 · `zealot_line` |
| `meta.json` | 워커·wait·speed·audit·ui 설정 |
| `LESSONS.md` | 런타임 하드 리스트 |
| `SKILL.md` | Claude 스킬 엔트리 (`/zealot` only) |
| `BASE.md` | scv@1.3.9 provenance · digests |
| `MANIFEST.sha256` / digests | tree integrity |
| `CHECK_MATRIX.md` · `CHECK_MATRIX.source-ids.txt` | scv selfcheck 이식 매트릭스 |
| `fixtures/` | D1–D5 · gates · triggers · S1 |
| `vendor/orchestration/` | 전용 orch skill pin SSOT |
| `prompts/quick-command.txt` | Orca Quick Command (≡ CANONICAL) |
| `zealot-selfcheck.sh` | 설치 검증 (Z1–Z13) |
| `freeze-zealot-from-scv.sh` | scv@1.3.9 → zealot freeze |
| `sync-from-source.sh` | repo → install paths |

## 설치

```bash
"$HOME/Desktop/jb/skills/orca/skills/zealot/sync-from-source.sh"
```

동기화 대상 (전용 경로만 · **공유 orch 금지**):

| 대상 | 경로 |
|------|------|
| pack | `$HOME/.orca/zealot/` |
| skill | `$HOME/.claude/skills/zealot/` |
| orchestration | `$HOME/.claude/skills/zealot-orchestration/` only |

**금지:** `$HOME/.claude/skills/orchestration` · `$HOME/.agents/skills/orchestration` 읽기/쓰기/교체.

검증:

```bash
"$HOME/.orca/zealot/zealot-selfcheck.sh"
# 또는
ZEALOT_HOME="$HOME/.orca/zealot" \
  "$HOME/Desktop/jb/skills/orca/skills/zealot/zealot-selfcheck.sh"
```

## 요약 (불변)

| 항목 | 값 |
|------|-----|
| 표시 이름 | zealot |
| packVersion | 1.0.0 |
| 팀장 | **Claude Code** · supervised |
| Grok 런타임 | **0** |
| 트리거 | **`/zealot` only** (bare `zealot` 미기동) |
| 채팅 연출 | `UX.md` · `**【 한글 】** "zealot_line" — 요약 · 다음: …` |
| 교차 검증 | plan Claude→Codex · code Codex→Claude |
| Human gate | AskUser 1회 · optionId/resultCode · fallback 동등 |
| 말미 | AUDIT → RECLAIM → CLOSING → FINAL |
| scv | 형제 팩 · scv 동작 무수정 |

**상세 규칙·CLI·run.json 스키마는 `PLAYBOOK.md`를 연다.** 이 파일에 PLAYBOOK 전문을 복제하지 않는다.
