#!/usr/bin/env bash
# scv pack self-check — run from anywhere
set -euo pipefail
ROOT="${SCV_HOME:-$HOME/.orca/scv}"
SKILL="${SCV_SKILL:-$HOME/.grok/skills/scv/SKILL.md}"
err=0

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; err=1; }

echo "scv self-check · root=$ROOT"

# required files
for f in PLAYBOOK.md meta.json LESSONS.md prompts/quick-command.txt prompts/quick-command.CANONICAL.txt \
  templates/plan.ko.md templates/ARCHITECTURE.ko.md; do
  if [[ -f "$ROOT/$f" ]]; then ok "file $f"; else fail "missing $f"; fi
done

# meta JSON
if python3 -c "import json; json.load(open('$ROOT/meta.json'))" 2>/dev/null; then
  ok "meta.json parses"
  ver=$(python3 -c "import json; print(json.load(open('$ROOT/meta.json')).get('packVersion',''))")
  [[ -n "$ver" ]] && ok "packVersion=$ver" || fail "packVersion missing"
else
  fail "meta.json invalid JSON"
fi

# QC byte-identical
if cmp -s "$ROOT/prompts/quick-command.txt" "$ROOT/prompts/quick-command.CANONICAL.txt"; then
  ok "quick-command ≡ CANONICAL"
else
  fail "quick-command drift vs CANONICAL"
fi

# PLAYBOOK must not document wrong task-create flag as primary
if grep -n 'task-create --title ' "$ROOT/PLAYBOOK.md" | grep -v task-title >/dev/null 2>&1; then
  # allow only if --task-title also present nearby; flag bare --title usage
  if grep -E 'task-create \\$|--title "' "$ROOT/PLAYBOOK.md" | grep -v task-title >/dev/null 2>&1; then
    fail "PLAYBOOK may still show task-create --title (use --task-title)"
  else
    ok "task-create flag check (soft)"
  fi
else
  ok "no bare task-create --title"
fi

if grep -q -- '--task-title' "$ROOT/PLAYBOOK.md"; then
  ok "PLAYBOOK documents --task-title"
else
  fail "PLAYBOOK missing --task-title"
fi

# SKILL pointer
if [[ -f "$SKILL" ]]; then
  ok "SKILL.md present"
  grep -q 'resolvedDocsLanguage\|문서 언어' "$SKILL" && ok "SKILL docs language" || fail "SKILL missing docs language section"
  grep -q 'task-title' "$SKILL" && ok "SKILL task-title" || fail "SKILL missing task-title"
else
  fail "SKILL.md missing at $SKILL"
fi

# worker command count in meta
n=$(python3 -c "import json; print(len(json.load(open('$ROOT/meta.json')).get('workers',[])))")
[[ "$n" -eq 7 ]] && ok "workers count=7" || fail "workers count=$n expected 7"

# docs language notes
grep -q '문서 언어' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK 문서 언어" || fail "PLAYBOOK missing 문서 언어"
grep -q 'Scope manifest\|scope manifest\|범위 확장' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK scope" || fail "PLAYBOOK missing scope"
grep -q 'CLOSING\|closed' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK run close" || fail "PLAYBOOK missing run close"


# v1.2.0 flow rules
grep -q 'prompt-first\|seed prompt\|프롬프트 우선' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK prompt-first intake" || fail "PLAYBOOK missing prompt-first"
grep -q 'AUDIT → RECLAIM\|AUDIT.*RECLAIM' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit→reclaim order" || fail "PLAYBOOK missing AUDIT→RECLAIM order"
grep -q 'time \| stability\|time/stability\|time | stability' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit focus" || fail "PLAYBOOK missing audit time/stability"
grep -q '고도화 금지\|forbidEvolution\|evolution' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK no-evolution audit" || fail "PLAYBOOK missing evolution forbid"
python3 -c "import json; m=json.load(open('$ROOT/meta.json')); assert m.get('packVersion'); assert m.get('intake',{}).get('mode')=='prompt-first'; assert m.get('audit',{}).get('forbidEvolution') is True; assert len(m.get('workers',[]))==7" && ok "meta intake/audit/workers" || fail "meta intake/audit/workers invalid"

if [[ $err -eq 0 ]]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL"
  exit 1
fi
