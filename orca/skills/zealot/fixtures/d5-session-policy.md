# D5 session policy

- ALLOW: resume only for the same role and phase-loop.
- FORBID: cross-role, cross-phase, idle-pick, command-compatible warm, and coordinator-handle reuse.
- REQUIRE: init, plan, code-review, and release use distinct handles even though their command is the same.
- REQUIRE: Audit Claude and Audit Codex each start in a fresh handle and never reuse a prior role handle.
- REQUIRE: phase transitions use file handoff, not prior transcript context.
