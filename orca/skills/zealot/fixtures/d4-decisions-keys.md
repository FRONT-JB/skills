# D4 coordinator exception keys

The coordinator must not perform a worker deliverable inline. A last-resort exception requires exactly one of these keys in `decisions.md`, with reason and affected files:

- `init:coordinator-exception`
- `plan:coordinator-exception`
- `code-review:coordinator-exception`
- `release:coordinator-exception`

No exception permits the coordinator handle to become a worker dispatch target or reclaim candidate.
