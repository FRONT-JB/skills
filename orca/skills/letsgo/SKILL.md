---
name: letsgo
description: >
  Run the user-defined Orca orchestration mode pack "letsgo" (supervised).
  Trigger when user says /letsgo, letsgo, lets-go, 이해 리뷰, explain-diff,
  or wants code-understanding explainer HTML for a change range.
  Coordinator=Grok. Pipeline: Codex research → dual verify (Claude∥Codex)
  ↔ research fix (max 3) → Claude docs → Claude design/html
  (Revolut DESIGN.md + templates/explainer.shell.html)
  → Grok review gate → human confirm → FINAL in Korean.
  Loads $HOME/.orca/letsgo/PLAYBOOK.md.
---

# letsgo mode (lets-go)

User-owned Orca mode pack. Engine = `orchestration` skill. This skill loads the pack and runs the supervised loop.

**Source pack (repo-relative):** `skills/orca/orchestration/letsgo-orchestration-pack.md`  
**Install root:** `$HOME/.orca/letsgo/`  
**Grok runtime skill:** `$HOME/.grok/skills/letsgo/SKILL.md`  
**Public package (this folder):** `skills/orca/skills/letsgo/`

> Path policy: use `$HOME/...` or **repo-relative** paths only.  
> Never commit absolute machine paths (`<absolute-home>/...`).

### Skill file sync (mandatory)

Grok letsgo `SKILL.md` 를 수정하면 **아래를 모두 동일 내용으로 갱신**한다 (한쪽만 고치지 않음):

| 역할 | 경로 |
|------|------|
| Grok 런타임 | `$HOME/.grok/skills/letsgo/SKILL.md` |
| 공용 패키지 (폴더) | `skills/orca/skills/letsgo/` (레포 루트 기준) |
| 공용 패키지 (파일) | `skills/orca/skills/letsgo/SKILL.md` |

```bash
# REPO = 이 skills monorepo 루트 (환경마다 다름 — 절대경로 하드코딩 금지)
REPO="${LETSGO_SKILLS_REPO:-$PWD}"   # 또는 본인 clone 경로를 일시 지정

# 권장: 런타임 정본 수정 후 공용 패키지로
cp "$HOME/.grok/skills/letsgo/SKILL.md" \
   "$REPO/skills/orca/skills/letsgo/SKILL.md"
# install 산출 전체 미러 (경로 마스킹 후 — 아래 Portable install)
rsync -a --delete --exclude 'SKILL.md' \
  "$HOME/.orca/letsgo/" \
  "$REPO/skills/orca/skills/letsgo/"
cp "$HOME/.grok/skills/letsgo/SKILL.md" \
   "$REPO/skills/orca/skills/letsgo/SKILL.md"
# 미러 meta 경로가 $HOME 형태인지 확인 (절대 홈 디렉터리 절대경로 금지)
```

## When invoked (`/letsgo` or aliases)

1. Read **required**:
   - `$HOME/.orca/letsgo/PLAYBOOK.md`
   - `$HOME/.orca/letsgo/meta.json`
   - `$HOME/.orca/letsgo/DESIGN.md` (Revolut · must exist)
   - `$HOME/.orca/letsgo/templates/explainer.shell.html` (design shell · must exist)
   - skim `$HOME/.orca/letsgo/LESSONS.md` (**do this every run**)
2. If the current repo has `.orca/letsgo.md` or `.orca/PLAYBOOK.md`, also follow as overlay. Read `AGENTS.md` when present.
3. Follow engine skill `orchestration` for all `orca orchestration …` — including **Coordinator Efficiency**, **post-inject liveness**, **hung recovery**.
4. Confirm `orca status --json` (runtime ready). Experimental → Orchestration must be ON.
5. **Residual tasks:** list existing tasks. Never dispatch by fuzzy title match. Only use **task ids created in this run** (store from `task-create` response). Do not touch unrelated `ready`/`dispatched` work from prior goals.
6. **Goal gate:** require a **change range** (one of: `base..HEAD` / PR URL / commit range). If missing, ask once and do not start.
7. Resolve branch → `$OUT=$HOME/Desktop/letsgo/<sanitized-branch>/` (`mkdir -p`). Record `RUN_ID` (timestamp or uuid) and put it in every task title/spec prefix: `[letsgo:$RUN_ID]`.
8. Act as **Grok coordinator** (supervised DAG):

```text
research (Codex)
  → verify-claude ∥ verify-codex     # parallel; maxConcurrent uses 2 here
       ⇄ research fix                # maxRounds=3; pass = BOTH P0+P1==0
  → (fail after 3) stop + user confirm
  → docs (Claude) → design/html (Claude, separate terminal; copy shell then fill)
  → review gate (Grok) → human confirm → FINAL (Korean 6 sections)
```

### Design HTML (template)

```bash
cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
# design worker fills SLOTs + sections from explainer.md; do NOT rewrite <style>
```

Inputs: `explainer.md` + `DESIGN.md` (Revolut) + shell.  
Optional filled sample: `$HOME/Desktop/letsgo/<branch>/explainer.html` (구조 참고 · 내용 복붙 금지).

### Hard rules (from production failures)

| Rule | Value |
|------|--------|
| Worker commands | **exact** from `meta.json` only — no invented models/flags |
| Hang recovery | **max 1 retry per role per task** then **user confirm** (no infinite restarts) |
| Same taskId | while `dispatched`, **never** re-dispatch; do not spawn parallel assignees |
| Late `worker_done` | if task already `completed`, **ignore** (do not re-open phase) |
| `check --wait` | **exactly one** owner loop; never stack parallel waits |
| Task selection | dispatch **only** ids returned by this run's `task-create` |
| Claude model | `sonnet` + skip-permissions (see meta) — **not** `claude-sonnet-5` |
| design hang | retry Claude **once**; **no Grok HTML**, **no silent Codex design** without user OK |
| App code | **no production edits**; artifacts only under `$OUT` + notes |
| Secrets | mask in notes/HTML |

- Prefer `--worktree active` for reading the change.
- **Do not** pre-spawn the whole worker pool; advance phase-by-phase (except dual-verify which is intentionally parallel).
- Claude docs vs html: **separate terminals** (`claude-docs`, `claude-html`).
- Dual verify outputs: `verify-claude.md` + `verify-codex.md`; coordinator (or last pass worker) writes merge summary `verify-report.md` only after both done.

9. On completion (after human confirm), synthesize **FINAL** (한글):

1. 요약  
2. 이해 (5축)  
3. 파이프라인 결과  
4. 퀴즈 커버리지  
5. HTML 경로  
6. 잔여 리스크와 다음 질문  

## Worker commands (from meta — keep in sync)

| role | agent | command | ownership |
|------|-------|---------|-----------|
| research | codex | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | edit (notes only) |
| test-claude | claude | `claude --model sonnet --dangerously-skip-permissions` | review-only |
| test-codex | codex | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` | review-only (notes: verify file only) |
| docs | claude | `claude --model sonnet --dangerously-skip-permissions` | edit |
| design | claude | `claude --model sonnet --dangerously-skip-permissions` | edit |
| review | grok | `grok -m grok-4.5 --reasoning-effort high` | review-only |

## Outputs

```text
~/Desktop/letsgo/<branch>/
  research-notes.md
  verify-claude.md
  verify-codex.md
  verify-report.md      # merge: both PASS required
  explainer.md
  explainer.html        # final: shell + filled content, Revolut tokens, Korean body
  gate-report.md        # optional review artifact
```

## Skip

Single-file trivial change → ask user whether to skip full pipeline.

## Anti-patterns

- Fire-and-forget handoff (this pack is **supervised**).
- `--model` on `orca orchestration dispatch`.
- Parallel `check --wait` loops.
- Single-agent verify when dual-verify is required.
- verify without **both** agents pass before docs/html.
- Same Claude session for docs + html.
- design inventing technical claims not in explainer.md.
- design rewriting shell `<style>` / inventing Vercel mesh look.
- Treating test/review `worker_done` as edit authority.
- Editing app production sources under this mode.
- Fuzzy task-title dispatch (e.g. any task containing "design").
- Re-dispatching a completed task because a late `worker_done` arrived.
- >1 hang recovery per role without asking the user.
- Inventing CLI models after hang (`claude-sonnet-5` → random aliases) outside meta.
