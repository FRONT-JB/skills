#!/usr/bin/env bash
# Sync $HOME/.orca/scv/prompts/quick-command.txt → Orca UI terminalQuickCommands (label=scv).
# Prefer: fully quit Orca first, then run this, then reopen Orca.
set -euo pipefail
QC="$HOME/.orca/scv/prompts/quick-command.txt"
DATA="$HOME/Library/Application Support/orca/profiles/local-default/orca-data.json"
if [[ ! -f "$QC" ]]; then
  echo "missing $QC" >&2
  exit 1
fi
if [[ ! -f "$DATA" ]]; then
  echo "missing $DATA" >&2
  exit 1
fi
if pgrep -x Orca >/dev/null 2>&1 || pgrep -if 'Orca\.app' >/dev/null 2>&1; then
  echo "WARNING: Orca appears to be running — it may overwrite this change from memory."
  echo "         Quit Orca completely, re-run this script, then open Orca again."
fi
python3 - "$QC" "$DATA" <<'PY'
import json, os, sys, time
from pathlib import Path
qc_path, data_path = map(Path, sys.argv[1:3])
new = qc_path.read_text(encoding="utf-8").strip()
p = data_path
bak = p.with_name(p.name + f".bak-scv-sync-{int(time.time())}")
bak.write_bytes(p.read_bytes())
data = json.loads(p.read_text(encoding="utf-8"))
found = False
for qc in data.get("settings", {}).get("terminalQuickCommands", []):
    if qc.get("label") == "scv" or "scv mode" in qc.get("prompt", ""):
        qc["prompt"] = new
        found = True
if not found:
    raise SystemExit("scv quick command not found in orca-data.json")
tmp = p.with_suffix(".json.tmp-sync")
tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
os.replace(tmp, p)
# verify
data2 = json.loads(p.read_text(encoding="utf-8"))
t = next(x["prompt"] for x in data2["settings"]["terminalQuickCommands"] if x.get("label") == "scv" or "scv mode" in x.get("prompt", ""))
assert t.strip() == new, "write verification failed"
print("OK synced scv quick-command")
print("  file:", qc_path)
print("  orca:", data_path)
print("  backup:", bak.name)
print("  len:", len(t))
print("  ends:", repr(t[-100:]))
PY
