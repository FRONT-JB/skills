# 계획 초안: zealot (Grok-free / Claude coordinator) 형제 팩

**상태:** draft **v3.2.2** · 6차 Codex P1 최소 패치 (N 독립 산출 · Z8 templates/vendor · Z3 .agents)  
**날짜:** 2026-07-20  
**기준 팩:** scv packVersion **1.3.9** (build-time base only)  
**의도:** Grok 한도 압박 시 동일 파이프라인을 Claude 팀장으로 돌리는 **형제 팩**. 기존 `scv` 유지.

**폐기 명칭:** `scv-cc`, `scv-claude`, `prove`

---

## 0. 한 줄 제안

**`zealot`** = Claude 팀장 · Grok 런타임 0 · Claude↔Codex 교차검증 유지.  
대사 = SC1 **Zealot** 위키 정본 (`zealot_line`).  
패키징 = build-time scv@1.3.9 snapshot + 허용 Delta · runtime 완전 해결 트리.

| | scv | zealot |
|--|-----|--------|
| Coordinator | Grok | **Claude Code** |
| 트리거 | `scv`, `/scv` | **`/zealot` only** (SKILL.md 강제) |
| Install | `~/.orca/scv/` | `~/.orca/zealot/` |
| Skill | `~/.grok/skills/scv/` | `~/.claude/skills/zealot/` |
| Orchestration install | (공유 가능) | **`~/.claude/skills/zealot-orchestration/` only** — 공유 `…/orchestration` **절대 미사용** |
| State | `.scv/state/` | `.zealot/state/` |
| packVersion | 1.3.9 | **1.0.0** |

---

## 1. 형제 팩 원칙

- scv 1.3.9 · 공유 Claude orchestration 스킬 **회귀/오염 0**  
- 런타임 상속 / `inheritsPlaybookFrom` 금지  
- 공유 경로 `~/.claude/skills/orchestration` · `~/.agents/skills/orchestration` **읽기·쓰기·교체 금지**

---

## 2. 역할 · dual-role

| 역할 | command/agent |
|------|----------------|
| coordinator | Claude Code 세션 |
| init / plan / code-review / release | `claude --model opus --dangerously-skip-permissions` |
| plan-review / implement / review-fix | Codex gpt-5.6-sol (high/xhigh/high) |
| audit | fresh Claude ∥ Codex |

교차검증: plan Claude→Codex · code Codex→Claude.

### D1–D5 + fixtures (전부 필수 · S2)

| ID | 불변식 | fixture |
|----|--------|---------|
| D1 | coordinator ∉ worker `terminals[]` / reclaim allowlist | `fixtures/d1-run.json` |
| D2 | init/plan/code-review/release distinct handles | `fixtures/d2-role-handles.json` |
| D3 | coordinator path allowlist only | `fixtures/d3-coord-allowlist.sh` |
| D4 | 인라인 대행 금지 · 예외 키 | `fixtures/d4-decisions-keys.md` |
| D5 | session reuse 1.3.7 · Audit fresh | `fixtures/d5-session-policy.md` |

**S2 = 1차 성공 기준 필수** (D1–D5 assert 전부 PASS).

---

## 3. 패키징

### 3.1 Build vs runtime

| 단계 | 도구 | scv 필요 |
|------|------|----------|
| freeze | `freeze-zealot-from-scv.sh` | 예 |
| runtime selfcheck | `zealot-selfcheck.sh` | 아니오 (`$ZEALOT_HOME` + zealot-orch pin) |

### 3.2 Digest (자기참조 없음 · 단일 알고리즘)

**공통 함수 `tree_digest(root)` (freeze/runtime/orch pin 동일):**

1. 정규 파일 집합 `F` (symlink follow 금지).  
2. **제외:** `MANIFEST.sha256`, `.DS_Store`, `*.log`.  
3. **meta.json:** hash 입력 시 `baseDigestSha256`·`treeDigestSha256`·`orchestrationVendorDigest` 값을 placeholder `"0"*64` 로 치환. (`meta` 제외 옵션 **폐기** — placeholder만.)  
4. 경로 정규화 · 정렬 · `sha256(content)  relpath` 줄 → `MANIFEST.sha256` (이 파일은 F 제외).  
5. `digest = sha256(MANIFEST.sha256 bytes)`.  

| 필드 | 값 |
|------|-----|
| `treeDigestSha256` | `tree_digest($ZEALOT_HOME)` |
| `baseDigestSha256` | freeze 시 scv@1.3.9 source의 동 함수 결과 (runtime 재검증 안 함 · provenance) |
| `orchestrationVendorDigest` | `tree_digest(vendor/orchestration)` — **동일 함수** |

`baseDigest`는 provenance-only · treeDigest가 base 바이트를 보증하지 않음 (문서 명시).

### 3.3 허용 Delta

1–14: v3.1과 동일 (zealot 치환 · Claude workers · paths · UX · gates · MANIFEST 규칙)  
**추가 15:** `orchestrationSkill` / install → **`zealot-orchestration` 전용 경로** · 공유 `orchestration` 금지  
**추가 16:** notes 프로즈에서 Coordinator Grok only / grok mirror 문장 제거·치환  

meta **구조 블록 전부 보존** + **top-level 스칼라 보존:**  
`maxConcurrent`, `waitTimeoutMs`, `waitRollingTimeoutMs`, `implementSoftBudgetMs`, `postInjectLivenessMs`, `postInjectLivenessMode`, `hangRetryMaxPerRole`, `worktreePolicy`, `planPathPattern`, `defaultDocsLanguage`, `stateRoot`(값만 zealot 치환).

### 3.4 레이아웃

```text
skills/zealot/
  SKILL.md
  meta.json
  PLAYBOOK.md · UX.md · LESSONS.md · BASE.md
  MANIFEST.sha256
  CHECK_MATRIX.md
  CHECK_MATRIX.source-ids.txt   # freeze 고정 · id + exclude_reason · N 산출 SSOT
  fixtures/
    d1-run.json
    d2-role-handles.json
    d3-coord-allowlist.sh
    d4-decisions-keys.md
    d5-session-policy.md
    triggers.md
    gates-option-ids.json
  vendor/orchestration/          # pin 스냅샷 SSOT
  zealot-selfcheck.sh
  freeze-zealot-from-scv.sh
  sync-from-source.sh
  prompts/quick-command.txt
  prompts/quick-command.CANONICAL.txt
  templates/

Install pack:   $HOME/.orca/zealot/
Skill:          $HOME/.claude/skills/zealot/
Orch install:   $HOME/.claude/skills/zealot-orchestration/   # 전용 · 공유 orchestration 미사용
```

### 3.5 경로 격리

| 규칙 | 내용 |
|------|------|
| state | `.zealot/state/$RUN_ID/` |
| Z3 FAIL | `.orca/scv`, `.grok/skills/scv`, `.scv/state` 설정 잔존 |
| Z3 FAIL | 활성 설정/스크립트/meta가 공유 orch 를 **참조·설치 타깃**으로 쓰면 FAIL: `~/.claude/skills/orchestration` **또는** `~/.agents/skills/orchestration` |
| Z3 예외 | stage-deny 리터럴 `.scv/**` · BASE provenance · “금지 목록에 공유 경로를 적어 둔” 문서 줄 |
| orch pin 검증 예외 | `$HOME/.claude/skills/zealot-orchestration` 만 읽기 허용 |

---

## 4. meta 스케치 (축소 금지)

```json
{
  "modeName": "zealot",
  "displayName": "zealot",
  "packVersion": "1.0.0",
  "basePackVersion": "1.3.9",
  "baseDigestSha256": "<freeze provenance>",
  "treeDigestSha256": "<tree_digest ZEALOT_HOME>",
  "orchestrationVendorDigest": "<tree_digest vendor/orchestration>",
  "coordination": "supervised",
  "coordinator": { "agent": "claude" },
  "taskTitlePrefix": "[zealot:$RUN_ID]",
  "stateRoot": ".zealot/state/$RUN_ID/",
  "templatesDir": "$HOME/.orca/zealot/templates/",
  "skillCanonical": "$HOME/.claude/skills/zealot/SKILL.md",
  "orchestrationSkill": "$HOME/.claude/skills/zealot-orchestration/SKILL.md",
  "runtimeRequires": ["claude", "codex", "orca"],
  "triggers": {
    "strong": ["/zealot"],
    "bare": "disabled",
    "forbidSubstring": true,
    "enforcement": ["skill.md", "selfcheck-Z10"]
  },
  "ui": { "uxDoc": "$HOME/.orca/zealot/UX.md", "lineKey": "zealot_line" },
  "workers": [ "/* scv workers[] 복사 후 init/release→claude · 상주 7 · audit 비포함 */" ]
}
```

`wait`/`rpcIdPaths`/`speed`/`audit`/`reclaim`/`midRunReclaim`/`intake`/`finalSections`/`crossReview`/`notes`/**`workers`**/**top-level 스칼라** = scv 복사 후 치환.  
**금지:** `inheritsPlaybookFrom`, Grok skillMirror 필수, `orchestrationSkill` → 공유 `…/orchestration`.

---

## 5. UX · `zealot_line`

정본: `https://starcraft.fandom.com/wiki/Zealot_(StarCraft)` · SC1.

| 분류 | 라인 |
|------|------|
| Trained | `My life for Aiur!` |
| Selected | `What battle calls?` · `Issah'tu!` · `I long for combat!` · `Gee'hous!` |
| Confirm | `Gau'gurah!` · `Thus I serve!` · `Honor guide me!` · `For Adun!` |
| Pissed | `En Taro Adun!` · `Doom to all who threaten the homeworld!` |

**미사용:** Empire 라인 · `Life for Aiur!` · Doom 마침표 버전 · 비정본 철자.

| 이벤트 | phase | line |
|--------|--------|------|
| preflight/init/hang | 초기화/재시도 | `My life for Aiur!` |
| seed/승인/fix/review/abandon | 접수·대기·수정·중단 | `What battle calls?` |
| plan | 계획 작성 | `I long for combat!` |
| plan-review | 계획 검토 | `Issah'tu!` |
| implement | 구현 | `Thus I serve!` |
| gate/AUDIT/wait | 인수·감사·대기 | `Honor guide me!` |
| review-fix | 리뷰 수정 | `For Adun!` |
| release | 릴리스 | `Gau'gurah!` |
| RECLAIM/FINAL | 회수·완료 | `En Taro Adun!` |
| blocked | 차단 | `Doom to all who threaten the homeworld!` |

포맷: `**【phase 】** "line" — 요약 · 다음: …`  
**엔진타입→한글 라벨 표는 scv UX 1.3.9를 zealot UX.md에 인라인 이식** (참조만 금지 · Z6b 실대상).

---

## 6. AskUser · optionId / resultCode

| gateId | optionIds | resultCodes |
|--------|-----------|-------------|
| plan_approve | approve / revise / abort | PLAN_APPROVED / PLAN_REVISE / ABORTED |
| scope_expand | keep_scope / defer / expand_now | SCOPE_KEEP / SCOPE_DEFER / SCOPE_EXPAND |
| risk_p0p1 | accept_risk / fix_resume / abort | RISK_ACCEPTED / RISK_FIX / ABORTED |
| dirty_branch | split_commit / stash / abort | DIRTY_SPLIT / DIRTY_STASH / ABORTED |
| push_release | push / hold / abort | PUSH_GO / PUSH_HOLD / ABORTED |
| reclaim_optin | reclaim / keep | RECLAIM_YES / RECLAIM_NO |
| hang_giveup | retry / abort | HANG_RETRY / ABORTED |

SSOT: `fixtures/gates-option-ids.json` · structured ≡ fallback 동일 코드 · unresolved 시 dispatch 금지.  
fallback-text-once 일 때만 본문 선택지 1회 허용.

---

## 7. 트리거

| 레이어 | 역할 |
|--------|------|
| **SKILL.md** | 실강제: `/zealot` only · bare 미기동 |
| meta + Z10 | 회귀 assert |

Fixtures T+1..3 · T−1..8 (인용·펜스·URL `/zealot` 미기동 포함).

---

## 8. selfcheck · CHECK_MATRIX

### 8.1 Z 목록 (번호 연속)

| ID | 내용 |
|----|------|
| Z1 | MANIFEST·treeDigest · placeholder |
| Z2 | **상주 workers=7** (init·plan·plan-review·implement·code-review·review-fix·release; **audit 제외**) · command에 `grok` 없음 |
| Z3 | 경로 누수 · 공유 orch (`~/.claude/skills/orchestration` **·** `~/.agents/skills/orchestration`) 를 설치 타깃 **또는 활성 참조**로 쓰면 FAIL |
| Z4 | zealot skill + **zealot-orchestration** pin digest match · anchors |
| Z5 | no inheritsPlaybookFrom |
| Z6 | zealot_line 정본 · Doom `!` |
| Z6b | UX 인라인 엔진 한글 라벨 표 |
| Z7 | 격리 HOME PASS |
| Z8 | 런타임 prose에 Grok-coordinator/Grok-mirror **의존** 문장 없음 (대상 목록 §8.2) |
| Z9 | D1–D5 fixture assert PASS |
| Z10 | T± · SKILL 트리거 문구 |
| Z11 | SKILL packVersion/RPC/task-title/UX |
| Z12 | quick-command sync |
| Z13 | CHECK_MATRIX **non-Grok `scv_check_id` 집합 1:1** (§8.3) |

scv 회귀 = **CI job** (Z 표 밖).

### 8.2 Z8 prose 대상 (명시 목록 · 짧고 고정)

| 경로 (ZEALOT_HOME 상대) | 비고 |
|-------------------------|------|
| `PLAYBOOK.md` | 필수 · Grok coordinator 잔문 금지 |
| `UX.md` | 필수 |
| `LESSONS.md` | 필수 |
| `SKILL.md` | 필수 |
| `meta.json` (`notes` 문자열 포함) | 필수 |
| `prompts/quick-command.txt` | 필수 |
| `prompts/quick-command.CANONICAL.txt` | 필수 |
| `BASE.md` | provenance `scv@1.3.9` **허용** · 런타임 coordinator=grok 지시 FAIL |
| `templates/**` (텍스트) | 필수 · 복사 템플릿 Grok 지시 금지 |
| `vendor/orchestration/**` (텍스트) | 필수 · vendor 스냅샷 안 Grok-mirror **필수 지시** 금지 (엔진 문서 일반 언급 OK if 비의존) |
| `fixtures/*.md` | 필수 |

**FAIL 예시 패턴 (의존 지시):** `Coordinator Grok only` · `You are Grok coordinator` · `command -v grok` 를 **필수 preflight**로 요구 · skillMirror를 **런타임 필수**로 요구.  
**허용:** BASE/changelog 출처 한 줄 (`based on scv@1.3.9`), 교차검증 표의 역사 설명 아닌 현재 계약.

### 8.3 CHECK_MATRIX · Z13 (1:1 set · 재현 가능)

컬럼: `scv_check_id` · `scv_what` · `zealot_target` · `assertion` · `exclude_reason` · `fixture`.

**`scv_check_id` + `N` 독립 SSOT (CHECK_MATRIX에서 역산 금지):**

1. 입력: 핀된 `scv@1.3.9` 의 `scv-selfcheck.sh` (+ 참조 앵커).  
2. freeze가 **`CHECK_MATRIX.source-ids.txt`** 를 패키지에 기록 (layout 필수 파일).  
   - **행 형식 (TSV, 헤더 1줄):** `scv_check_id\texclude_reason\tshort_what`  
   - `scv_check_id` = `scv-selfcheck.sh:<line>:<short_slug>` (assert/ok/fail **시작 줄**; 다줄 Python 블록=첫 줄 한 id; `a && b`=한 id).  
   - `exclude_reason` = `grok-only` 또는 **빈 칸**.  
   - 분류 규칙 (freeze **자동**, 사람 임의 부여 금지): 해당 검사 본문이 **오직** `.grok/` mirror · `skillMirror` · `command -v grok` 필수에만 해당하면 `grok-only`, 아니면 빈 칸.  
3. **`N` = source-ids.txt 에서 exclude_reason 빈 칸인 scv_check_id 집합** (CHECK_MATRIX.md를 읽지 않음).  
4. **`M` = CHECK_MATRIX.md 에서 exclude_reason 빈 칸 행의 scv_check_id 집합**.  
5. Z13이 `N`을 matrix 분류로 재구성하면 **스펙 위반** (순환 검증 금지).

**Z13 PASS (집합 1:1, `>=` 금지):**

```text
N ⊆ M  AND  M ⊆ N
```

basePackVersion 상향 시에만 source-ids.txt 재생성·Z13 재베이스.

최소 범주(각 ≥1 non-Grok 행): 필수파일 · packVersion · RPC · wait · worker_done · AskUser · session · audit/reclaim · mid-run · handoff · LESSONS · meta structural · UX · stuck/re-inject · task labels.

---

## 9. 스모크

| | 범위 | 필수 |
|--|------|------|
| S1 | plan 승인 게이트 · implement 0 | 필수 |
| S2 | D1–D5 전부 | 필수 |
| S3 | release 경로 | 1차 비필수 · 성공기준에 “미검증” 명시 |

---

## 10. Orchestration pin (v3.2 · 공유 경로 금지)

| 항목 | 계약 |
|------|------|
| Vendor SSOT | `zealot/vendor/orchestration/` |
| Install | **`$HOME/.claude/skills/zealot-orchestration/`** 에만 byte copy |
| meta.orchestrationSkill | `$HOME/.claude/skills/zealot-orchestration/SKILL.md` |
| Pin | `orchestrationVendorDigest = tree_digest(vendor/orchestration)` · install 동일 함수 |
| Z4 | install digest == vendor · anchors: worker_done structured, wait types, RPC |
| **금지** | `~/.claude/skills/orchestration` 읽기/쓰기/교체 · 심링크 follow-write · Grok orch 의존 |
| 기존 공유 스킬 | 존재해도 **무시** · zealot은 전용 경로만 사용 |

---

## 11. 구현 단계

1. freeze scv@1.3.9 + MANIFEST  
2. Delta · meta 스칼라/블록 보존  
3. UX 인라인 · SKILL 트리거 · gates JSON  
4. vendor orch · **zealot-orchestration** sync  
5. CHECK_MATRIX 자동초안 + Z1–Z13  
6. fixtures D1–D5  
7. S1+S2 PASS  
8. scv README 링크 · scv/공유 orch 무수정  

---

## 12. 성공 기준

**Positive:** Z7 · scv CI · S1 · **S2** · 정본 대사 · MANIFEST · T± · orch pin on **zealot-orchestration only** · optionId 동등.  
**Negative FAIL:** 공유 orch 설치 · bare zealot 기동 · S2 스킵 · Grok notes 잔존 · scv 경로 누수.

| 상황 | 선택 |
|------|------|
| Grok 여유 | `/scv` |
| Grok 한도 | **`/zealot`** |

---

## 13. R 재결

R1 snapshot · R2 `.zealot` · R3 S2 필수 · R4 교차검증 · R5 MANIFEST · R6 `/zealot` · R7 optionId · R8 scv+공유 orch 비파괴.

---

## 14. v3.1 → v3.2 (4차 반영)

| 이슈 | 조치 |
|------|------|
| Claude P1 공유 orch 충돌 | install = **`zealot-orchestration` only** |
| Codex P2 digest 정규화 | orch pin = **동일 tree_digest()** |
| D2–D5 fixture 미열거 | layout에 5파일 명시 |
| Z8 번호 공백 | Z8 = notes/prose Grok 금지 |
| meta 스칼라 | 보존 목록 명시 |
| CHECK_MATRIX 행 수 | non-Grok 산정 알고리즘 |
| placeholder 2택 | placeholder only |
| UX 엔진 라벨 | 인라인 이식 필수 |
| stuck recovery 앵커 | CHECK_MATRIX 최소 범주 |

## 14b. v3.2 → v3.2.1 (5차 Codex P1 · 최소)

| 이슈 | 조치 |
|------|------|
| CHECK_MATRIX `>=` / dry-parse 모호 | **`scv_check_id` 고정 목록** + Z13 **N⊆M ∧ M⊆N** 집합 1:1 |
| Z8 범위 좁음 | 대상에 **PLAYBOOK.md · UX · LESSONS · meta notes** 등 명시 목록 |
| Z3 공유 orch | 설치 타깃 **또는 활성 참조** FAIL |
| workers / 7 | 상주 7=audit 제외 · meta 복사 목록에 workers |

## 14c. v3.2.1 → v3.2.2 (6차 Codex P1 · 최소)

| 이슈 | 조치 |
|------|------|
| N 순환 검증 | `source-ids.txt`에 **id+exclude_reason** · **N은 source-ids만** · layout 포함 |
| Z8 누락 경로 | **templates/** · **vendor/orchestration/** · fixtures/*.md |
| Z3 .agents | 공유 금지에 **`~/.agents/skills/orchestration` 활성 참조** 포함 |

---

## 15. 리뷰어 부탁 (7차 · v3.2.2)

파일: `…/zealot-plan-draft.md` (**v3.2.2**)

정체성: v3.2.2 · N 독립 SSOT · Z8 templates/vendor · Z3 .agents.  
판정: APPROVE | APPROVE_WITH_NITS | REQUEST_CHANGES.  
**P0/P1 없어야 함.** 수정 금지 · 한국어.  
 
 
