# handoff (≤40 lines · no transcript dump)

Copy into `.scv/state/$RUN_ID/handoff/<from>-to-<to>.md` and point the **new** session `--spec` at this path only.

```text
## meta
- runId:
- fromRole / toRole:
- phase:
- writtenAt:

## must-read paths
- plan:
- decisions / freeze (hash·scope·gate):
- gate summary:
- batch / review report:
- prior findings (same-role resume only):
- implementer notes (same-role resume only):

## scope
- in:
- out:
- open risks:

## do-not
- Do not rely on prior pane transcript.
- Do not reopen closed phase without user + re-pass rules.
```
