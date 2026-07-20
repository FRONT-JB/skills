#!/usr/bin/env bash
# scv pack self-check — run from anywhere
set -euo pipefail
ROOT="${SCV_HOME:-$HOME/.orca/scv}"
SKILL_CANON="${SCV_SKILL_CANON:-$ROOT/SKILL.md}"
SKILL_MIRROR="${SCV_SKILL_MIRROR:-$HOME/.grok/skills/scv/SKILL.md}"
ORCH_SKILL="${ORCH_SKILL:-$HOME/Desktop/jb/skills/orca/skills/orchestration/SKILL.md}"
ORCH_MIRROR="${ORCH_MIRROR:-$HOME/.grok/skills/orchestration/SKILL.md}"
err=0

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; err=1; }

echo "scv self-check · root=$ROOT"

# --- files ---
for f in PLAYBOOK.md UX.md meta.json LESSONS.md prompts/quick-command.txt prompts/quick-command.CANONICAL.txt \
  templates/plan.ko.md templates/ARCHITECTURE.ko.md SKILL.md; do
  if [[ -f "$ROOT/$f" ]]; then ok "file $f"; else fail "missing $f"; fi
done

# --- meta ---
if python3 -c "import json; json.load(open('$ROOT/meta.json'))" 2>/dev/null; then
  ok "meta.json parses"
  ver=$(python3 -c "import json; print(json.load(open('$ROOT/meta.json')).get('packVersion',''))")
  [[ -n "$ver" ]] && ok "packVersion=$ver" || fail "packVersion missing"
  [[ "$ver" == "1.3.5" ]] && ok "packVersion pin 1.3.5" || fail "packVersion want 1.3.5 got $ver"
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

# --- UX (1.3.5 · display SSOT) ---
grep -q 'UX.md' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK points to UX.md" || fail "PLAYBOOK missing UX.md pointer"
grep -q '【 계획 작성 】' "$ROOT/UX.md" && ok "UX padded phase label" || fail "UX missing 【 계획 작성 】"
grep -q '【 대기 】' "$ROOT/UX.md" && ok "UX padded wait label" || fail "UX missing 【 대기 】"
grep -q '완료 대기 (worker_done)' "$ROOT/UX.md" && ok "UX wait description Korean" || fail "UX missing wait description"
grep -q 'Rolling wait' "$ROOT/UX.md" && ok "UX forbids Rolling wait" || fail "UX missing Rolling wait forbid"
grep -q 'display-name' "$ROOT/UX.md" && grep -q '계획 작성' "$ROOT/UX.md" && ok "UX display-name Korean" || fail "UX missing display-name Korean"

# --- worker_done structured (1.3.5) ---
grep -q 'LIFECYCLE' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK LIFECYCLE block" || fail "PLAYBOOK missing LIFECYCLE"
grep -q '\-\-task-id' "$ROOT/PLAYBOOK.md" && grep -q '\-\-dispatch-id' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK structured worker_done CLI" || fail "PLAYBOOK missing structured send"
grep -q 'not both\|동시 사용' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK forbids payload+structured mix" || fail "PLAYBOOK missing not-both rule"

# --- orchestration skill (engine) ---
if [[ -f "$ORCH_SKILL" ]]; then
  grep -q '\-\-task-id' "$ORCH_SKILL" && grep -q 'structured' "$ORCH_SKILL" && ok "orchestration skill structured worker_done" || fail "orchestration skill missing structured worker_done"
  if grep -E 'worker_done.*--payload|heartbeat.*--payload' "$ORCH_SKILL" | grep -v 'NEVER\|Forbidden\|together\|either' >/dev/null 2>&1; then
    # allow mentions of --payload only in forbid context; fail if old canonical one-liner remains
    if grep -q "worker_done --subject.*--payload '{" "$ORCH_SKILL" 2>/dev/null; then
      fail "orchestration skill still has legacy --payload worker_done one-liner"
    else
      ok "orchestration skill no legacy payload one-liner"
    fi
  else
    ok "orchestration skill payload usage checked"
  fi
  if [[ -f "$ORCH_MIRROR" ]]; then
    if cmp -s "$ORCH_SKILL" "$ORCH_MIRROR"; then
      ok "orchestration SKILL repo ≡ grok mirror"
    else
      fail "orchestration SKILL drift — cp $ORCH_SKILL $ORCH_MIRROR"
    fi
  else
    fail "orchestration mirror missing at $ORCH_MIRROR"
  fi
else
  fail "orchestration skill missing at $ORCH_SKILL"
fi

# --- PLAYBOOK mid-run reclaim (1.3.2) ---
grep -q 'Mid-run Soft Reclaim\|mid-run soft reclaim\|8b. Mid-run' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK mid-run reclaim" || fail "PLAYBOOK missing mid-run reclaim"
grep -q 'evidence escrow\|Evidence escrow' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK evidence escrow" || fail "PLAYBOOK missing evidence escrow"
grep -q 'forbidTabClose\|--tab' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK no --tab reclaim" || fail "PLAYBOOK missing --tab forbid"

# --- PLAYBOOK high-risk semantic anchors ---
grep -q 'Ready-no-tools' "$ROOT/PLAYBOOK.md" && grep -q '≥90s' "$ROOT/PLAYBOOK.md" \
  && ok "PLAYBOOK Ready-no-tools ≥90s" || fail "PLAYBOOK missing Ready-no-tools ≥90s"
grep -q 're-inject 금지' "$ROOT/PLAYBOOK.md" \
  && ok "PLAYBOOK no re-inject stuck pane" || fail "PLAYBOOK missing re-inject forbid"
grep -q '바로 다음 역할' "$ROOT/PLAYBOOK.md" && grep -q 'warm pool' "$ROOT/PLAYBOOK.md" \
  && ok "PLAYBOOK warm next role only" || fail "PLAYBOOK missing warm next-role"
grep -q 'NDJSON' "$ROOT/PLAYBOOK.md" && grep -q '_keepalive' "$ROOT/PLAYBOOK.md" \
  && ok "PLAYBOOK NDJSON/keepalive parse" || fail "PLAYBOOK missing NDJSON parse anchors"
grep -q 'mid_reclaiming' "$ROOT/PLAYBOOK.md" && grep -q 'mid_reclaimed' "$ROOT/PLAYBOOK.md" \
  && ok "PLAYBOOK mid_reclaiming→mid_reclaimed" || fail "PLAYBOOK missing two-phase mid-run status"

# --- flow ---
grep -q '문서 언어' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK 문서 언어" || fail "PLAYBOOK missing 문서 언어"
grep -q 'Scope manifest\|scope manifest\|범위 확장' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK scope" || fail "PLAYBOOK missing scope"
grep -q 'CLOSING\|closed' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK run close" || fail "PLAYBOOK missing run close"
grep -q 'prompt-first\|seed prompt\|프롬프트 우선' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK prompt-first" || fail "PLAYBOOK missing prompt-first"
grep -q 'AUDIT → RECLAIM\|AUDIT.*RECLAIM' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit→reclaim" || fail "PLAYBOOK missing AUDIT→RECLAIM"
grep -q 'time \| stability\|time/stability\|time | stability' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK audit focus" || fail "PLAYBOOK missing audit time/stability"
grep -q '고도화 금지\|forbidEvolution\|evolution' "$ROOT/PLAYBOOK.md" && ok "PLAYBOOK no-evolution audit" || fail "PLAYBOOK missing evolution forbid"

# --- LESSONS hard cap soft ---
hard_n=$(grep -c '^[0-9]\+\. ' "$ROOT/LESSONS.md" || true)
if [[ "${hard_n:-0}" -le 15 ]]; then ok "LESSONS hard count=$hard_n (≤15)"; else fail "LESSONS hard count=$hard_n (>15)"; fi

# --- SKILL canon + mirror ---
if [[ -f "$SKILL_CANON" ]]; then
  ok "canonical SKILL present"
  if [[ -n "${ver:-}" ]]; then
    grep -q "$ver" "$SKILL_CANON" && ok "SKILL mentions packVersion $ver" || fail "SKILL missing packVersion $ver"
  fi
  grep -q 'result.task.id\|RPC' "$SKILL_CANON" && ok "SKILL RPC/id" || fail "SKILL missing RPC contract"
  grep -q 'task-title' "$SKILL_CANON" && ok "SKILL task-title" || fail "SKILL missing task-title"
  grep -q 'resolvedDocsLanguage\|문서 언어' "$SKILL_CANON" && ok "SKILL docs language" || fail "SKILL missing docs language"
  grep -q 'LIFECYCLE\|structured' "$SKILL_CANON" && ok "SKILL lifecycle/structured" || fail "SKILL missing lifecycle"
  grep -q 'UX.md' "$SKILL_CANON" && ok "SKILL UX.md" || fail "SKILL missing UX.md"
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

# --- meta structural ---
n=$(python3 -c "import json; print(len(json.load(open('$ROOT/meta.json')).get('workers',[])))")
[[ "$n" -eq 7 ]] && ok "workers count=7" || fail "workers count=$n expected 7"

python3 -c "
import json
m=json.load(open('${ROOT}/meta.json'))
assert m.get('packVersion')=='1.3.5'
assert m.get('ui',{}).get('bracketPadding')=='single-space-both-sides'
assert m.get('ui',{}).get('terminalTitles',{}).get('plan')=='계획 작성'
assert m.get('ui',{}).get('displayNameRequiredKorean') is True
assert m.get('ui',{}).get('forbidWaitDescriptionEnglish') is True
assert m.get('ui',{}).get('workerDoneStructuredOnly') is True
assert m.get('ui',{}).get('lifecycleSpecRequired') is True
assert 'worker_done' in m.get('ui',{}).get('waitDescriptionExamples',{}).get('plan','')
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
print('OK meta structural contracts')
" || fail "meta structural contracts"

# --- optional: Orca quick-command match (soft if missing) ---
QC_DATA="${HOME}/Library/Application Support/orca/profiles/local-default/orca-data.json"
if [[ -f "$QC_DATA" && -f "$ROOT/prompts/quick-command.txt" ]]; then
  python3 -c "
from pathlib import Path
import json
qc=Path('${ROOT}/prompts/quick-command.txt').read_text().strip()
data=json.loads(Path('''${QC_DATA}''').read_text())
prompt=next((x['prompt'] for x in data.get('settings',{}).get('terminalQuickCommands',[]) if x.get('label','').lower()=='scv' or 'scv mode' in x.get('prompt','')), None)
if prompt is None:
    print('SOFT orca-data has no scv quick-command')
elif prompt.strip()==qc:
    print('OK  orca-data scv quick-command ≡ install')
else:
    print('SOFT orca-data scv quick-command MISMATCH (run sync-quick-command-to-orca.sh after quitting Orca)')
" || true
fi

if [[ "$err" -ne 0 ]]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
