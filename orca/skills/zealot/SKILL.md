---
name: zealot
description: >
  Run the user-defined Orca orchestration mode pack "zealot", a Claude-led,
  Grok-free supervised feature-shipping harness. Invoke only when the user's
  operative command is the standalone slash command /zealot. Do not invoke for
  bare "zealot", substrings, quotations, fenced examples, or URLs containing
  /zealot. Coordinates Claude plan writing, Codex plan review and implementation,
  Claude code review, audit, reclaim, and release using the vendored dedicated
  zealot-orchestration skill.
---

# zealot mode

Run the plan → implement → quality gate → code-review → release → audit → reclaim → FINAL pipeline.

## Trigger contract

- Start only when `/zealot` is the operative standalone slash command.
- Treat bare `zealot`, `zealot-harness`, substrings, quoted text, fenced text, and URL occurrences as ordinary text.
- Extract any text following the valid command as the seed. If no seed remains, ask once for free text before creating `RUN_ID` or state.

## Load order

1. Read `$HOME/.orca/zealot/PLAYBOOK.md`, `UX.md`, `meta.json`, and `LESSONS.md`.
2. Read project overlays `.orca/zealot.md` and `AGENTS.md` when present.
3. Read `$HOME/.claude/skills/zealot-orchestration/SKILL.md` for all `orca orchestration` commands.
4. Never read, write, install, or replace a shared orchestration skill for this mode.

| Contract | Value |
|----------|-------|
| packVersion | `1.0.0` |
| Coordinator | current Claude Code session |
| State | `.zealot/state/$RUN_ID/` |
| Task title | `[zealot:$RUN_ID] 한글 phase · slug` |
| UX line key | `zealot_line` |
| Wait | one owner; `worker_done,escalation,decision_gate` |
| RPC task ID | `result.task.id` only |
| RPC dispatch ID | `result.dispatch.id` only |
| Worker completion | structured flags; one accepted `worker_done` |

## Fixed workers

Use the seven `meta.json` workers exactly. Keep coordinator and worker handles distinct; never dispatch a worker task to the coordinator handle.

| role | command |
|------|---------|
| init | `claude --model opus --dangerously-skip-permissions` |
| plan | `claude --model opus --dangerously-skip-permissions` |
| plan-review | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| implement | `codex -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -a never -s danger-full-access` |
| code-review | `claude --model opus --dangerously-skip-permissions` |
| review-fix | `codex -m gpt-5.6-sol -c model_reasoning_effort="high" -a never -s danger-full-access` |
| release | `claude --model opus --dangerously-skip-permissions` |

## Runtime rules

- Follow the resolved `PLAYBOOK.md`; do not inherit behavior from another pack at runtime.
- Prefix every worker spec with the `LIFECYCLE` block and resolved document language.
- Use AskUser exactly once per decision gate and map its `optionId` to the fixture-defined `resultCode`; do not dispatch while unresolved.
- Resume only the same role in the same phase loop. Use fresh handles across roles/phases and for both audit reviewers.
- Preserve plan Claude → Codex cross-review and code Codex → Claude cross-review.
- Keep `AUDIT → RECLAIM → CLOSING → FINAL`; never stage `.zealot/**` or use `git add -A`.
- Present progress, questions, and FINAL in Korean using `UX.md` and canonical `zealot_line` values.
