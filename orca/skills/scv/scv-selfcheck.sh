#!/usr/bin/env bash
# scv pack self-check — run from anywhere
set -euo pipefail
ROOT="${SCV_HOME:-$HOME/.orca/scv}"
SKILL_CANON="${SCV_SKILL_CANON:-$ROOT/SKILL.md}"
SKILL_MIRROR="${SCV_SKILL_MIRROR:-$HOME/.grok/skills/scv/SKILL.md}"
err=0

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; err=1; }

echo "scv self-check · root=$ROOT"

# --- files ---
for f in PLAYBOOK.md meta.json LESSONS.md prompts/quick-command.txt prompts/quick-command.CANONICAL.txt \
  templates/plan.ko.md templates/ARCHITECTURE.ko.md SKILL.md; do
  if [[ -f "$ROOT/$f" ]]; then ok "file $f"; else fail "missing $f"; fi
done

# --- meta ---
if python3 -c "import json; json.load(open('$ROOT/meta.json'))" 2>/dev/null; then
  ok "meta.json parses"
  ver=$(python3 -c "import json; print(json.load(open('$ROOT/meta.json')).get('packVersion',''))")
  [[ -n "$ver" ]] && ok "packVersion=$ver" || fail "packVersion missing"
  # pin: current ship version (behavior pack)
  [[ "$ver" == "1.3.2" ]] && ok "packVersion pin 1.3.2" || fail "packVersion want 1.3.2 got $ver"
else
  fail "meta.json invalid JSON"
  ver=""
fi

# --- quick-command ---
if cmp -s "$ROOT/prompts/quick-command.txt" "$ROOT/prompts/quick-command.CANONICAL.txt"; then
  ok "quick-command ≡ CANONICAL"
else
  fail "quick-command drift vs CANONICAL"
fi

# --- PLAYBOOK CLI flags ---
if grep -n 'task-create --title ' "$ROOT/PLAYBOOK.md" | grep -v task-title >/dev/null 2>&1; then
  if grep -E 'task-create \\$|--title "' "$ROOT/PLAYBOOK.md" | grep -v task-title >/dev/null 2>&1; then
    fail "PLAYBOOK may still show task-create --title (use --task-title)"
  else
    ok "task-create flag check (soft)"
  fi
else
  ok "no bare task-create --title"
fi
grep -q -- '--task-title' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK --task-title" || fail "PLAYBOOK missing --task-title"

# --- PLAYBOOK contracts (1.3.1+) ---
grep -q 'result.task.id' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK result.task.id" || fail "PLAYBOOK missing result.task.id"
grep -q 'result.split.handle' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK result.split.handle" || fail "PLAYBOOK missing split handle path"
grep -q 'wait·liveness fusion\|Wait · liveness fusion\|liveness fusion' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK wait·liveness fusion" || fail "PLAYBOOK missing wait·liveness fusion"
grep -q 'tasksById\|per-task\|per task' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK per-task dispatch" || fail "PLAYBOOK missing per-task dispatch"
grep -q '900000\|waitTimeoutMs\|전체.*budget\|budget 가이드' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK rolling vs budget" || fail "PLAYBOOK missing budget vs rolling"
grep -q 'decision_gate' "$ROOT/PLAYBOOK.md" && grep -q '유실' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK gate drain safety" || ok "PLAYBOOK gate drain (soft)"

# --- PLAYBOOK mid-run reclaim (1.3.2) ---
grep -q 'Mid-run Soft Reclaim\|mid-run soft reclaim\|8b. Mid-run' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK mid-run reclaim" || fail "PLAYBOOK missing mid-run reclaim"
grep -q 'evidence escrow\|Evidence escrow' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK evidence escrow" || fail "PLAYBOOK missing evidence escrow"
grep -q 'forbidTabClose\|--tab' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK no --tab reclaim" || fail "PLAYBOOK missing --tab forbid"

# --- flow ---
grep -q '문서 언어' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK 문서 언어" || fail "PLAYBOOK missing 문서 언어"
grep -q 'Scope manifest\|scope manifest\|범위 확장' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK scope" || fail "PLAYBOOK missing scope"
grep -q 'CLOSING\|closed' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK run close" || fail "PLAYBOOK missing run close"
grep -q 'prompt-first\|seed prompt\|프롬프트 우선' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK prompt-first" || fail "PLAYBOOK missing prompt-first"
grep -q 'AUDIT → RECLAIM\|AUDIT.*RECLAIM' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit→reclaim" || fail "PLAYBOOK missing AUDIT→RECLAIM"
grep -q 'time \| stability\|time/stability\|time | stability' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit focus" || fail "PLAYBOOK missing audit time/stability"
grep -q '고도화 금지\|forbidEvolution\|evolution' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK no-evolution audit" || fail "PLAYBOOK missing evolution forbid"

# --- SKILL canon + mirror ---
if [[ -f "$SKILL_CANON" ]]; then
  ok "canonical SKILL present"
  if [[ -n "${ver:-}" ]]; then
    grep -q "$ver" "$SKILL_CANON" && ok "SKILL mentions packVersion $ver" || fail "SKILL missing packVersion $ver"
  fi
  grep -q 'result.task.id\|RPC' "$SKILL_CANON" && ok "SKILL RPC/id" || fail "SKILL missing RPC contract"
  grep -q 'task-title' "$SKILL_CANON" && ok "SKILL task-title" || fail "SKILL missing task-title"
  grep -q 'resolvedDocsLanguage\|문서 언어' "$SKILL_CANON" && ok "SKILL docs language" || fail "SKILL missing docs language"
else
  fail "canonical SKILL missing at $SKILL_CANON"
fi
if [[ -f "$SKILL_MIRROR" ]]; then
  ok "mirror SKILL present"
  if cmp -s "$SKILL_CANON" "$SKILL_MIRROR"; then
    ok "SKILL canon ≡ mirror"
  else
    fail "SKILL canon/mirror drift — cp $SKILL_CANON $SKILL_MIRROR"
  fi
else
  fail "mirror SKILL missing at $SKILL_MIRROR"
fi

# --- meta structural (behavior pin) ---
n=$(python3 -c "import json; print(len(json.load(open('$ROOT/meta.json')).get('workers',[])))")
[[ "$n" -eq 7 ]] && ok "workers count=7" || fail "workers count=$n expected 7"

python3 -c "
import json
m=json.load(open('${ROOT}/meta.json'))
assert m.get('packVersion')=='1.3.2'
assert m.get('intake',{}).get('mode')=='prompt-first'
assert m.get('audit',{}).get('forbidEvolution') is True
assert len(m.get('workers',[]))==7
assert m.get('wait',{}).get('forbidHeartbeatInWaitTypes') is True
assert m.get('rpcIdPaths',{}).get('forbidRootIdAsTaskId') is True
assert m.get('speed',{}).get('stepPreservingOnly') is True
assert m.get('waitRollingTimeoutMs')==90000
assert m.get('waitTimeoutMs')==900000
assert m.get('midRunReclaim',{}).get('defaultAction')=='keep'
assert m.get('midRunReclaim',{}).get('forbidTabClose') is True
assert m.get('midRunReclaim',{}).get('requireEvidenceEscrow') is True
assert m.get('midRunReclaim',{}).get('isNewPhase') is False
" && ok "meta structural contracts" || fail "meta structural contracts invalid"

if [[ $err -eq 0 ]]; then
  echo "RESULT: PASS"
  exit 0
else
  echo "RESULT: FAIL"
  exit 1
fi
