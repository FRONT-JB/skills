#!/usr/bin/env bash
set -euo pipefail
FIXTURE="${1:?usage: d3-coord-allowlist.sh <d1-run.json>}"
python3 - "$FIXTURE" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
coordinator = data["coordinatorHandle"]
worker_handles = [item["handle"] for item in data["terminals"]]
assert coordinator not in worker_handles
assert coordinator not in data["reclaimAllowlist"]
assert len(worker_handles) == len(set(worker_handles)) == 7
print("D3 PASS")
PY
