#!/usr/bin/env bash
# zealot v3.2.2 contract selfcheck — Z1 through Z13
set -euo pipefail

ROOT="${ZEALOT_HOME:-$HOME/.orca/zealot}"
SKILL_CANON="${ZEALOT_SKILL_CANON:-$HOME/.claude/skills/zealot/SKILL.md}"
ORCH_INSTALL="${ZEALOT_ORCH_INSTALL:-$HOME/.claude/skills/zealot-orchestration}"

python3 - "$ROOT" "$SKILL_CANON" "$ORCH_INSTALL" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

root = Path(sys.argv[1]).resolve()
skill_canon = Path(sys.argv[2]).resolve()
orch_install = Path(sys.argv[3]).resolve()
zero = "0" * 64
digest_fields = ("baseDigestSha256", "treeDigestSha256", "orchestrationVendorDigest")
failures = []

def check(value, zid, label):
    if value:
        print(f"OK  {zid} {label}")
    else:
        print(f"FAIL {zid} {label}")
        failures.append(f"{zid} {label}")

def regular_files(tree: Path):
    files = []
    for dirpath, dirnames, filenames in os.walk(tree, followlinks=False):
        current = Path(dirpath)
        dirnames[:] = sorted(name for name in dirnames if not (current / name).is_symlink())
        for name in sorted(filenames):
            path = current / name
            if path.is_symlink() or name in {"MANIFEST.sha256", ".DS_Store"} or name.endswith(".log"):
                continue
            if path.is_file():
                files.append(path)
    return sorted(files, key=lambda p: p.relative_to(tree).as_posix())

def normalized_content(tree: Path, path: Path):
    data = path.read_bytes()
    if path.relative_to(tree).as_posix() != "meta.json":
        return data
    text = data.decode("utf-8")
    for field in digest_fields:
        text = re.sub(
            rf'("{field}"\s*:\s*")[0-9a-fA-F]{{64}}(")',
            rf'\g<1>{zero}\g<2>',
            text,
        )
    return text.encode("utf-8")

def tree_digest(tree: Path):
    rows = []
    for path in regular_files(tree):
        rel = path.relative_to(tree).as_posix()
        digest = hashlib.sha256(normalized_content(tree, path)).hexdigest()
        rows.append(f"{digest}  {rel}\n")
    manifest = "".join(rows).encode("utf-8")
    return hashlib.sha256(manifest).hexdigest(), manifest

required = [
    "SKILL.md", "meta.json", "PLAYBOOK.md", "UX.md", "LESSONS.md", "BASE.md",
    "MANIFEST.sha256", "CHECK_MATRIX.md", "CHECK_MATRIX.source-ids.txt",
    "zealot-selfcheck.sh", "freeze-zealot-from-scv.sh", "sync-from-source.sh",
    "prompts/quick-command.txt", "prompts/quick-command.CANONICAL.txt",
    "fixtures/d1-run.json", "fixtures/d2-role-handles.json",
    "fixtures/d3-coord-allowlist.sh", "fixtures/d4-decisions-keys.md",
    "fixtures/d5-session-policy.md", "fixtures/triggers.md",
    "fixtures/gates-option-ids.json", "vendor/orchestration/SKILL.md",
]
check(all((root / item).is_file() for item in required), "Z1", "required files")
meta = json.loads((root / "meta.json").read_text(encoding="utf-8"))
digest, manifest = tree_digest(root)
manifest_file = (root / "MANIFEST.sha256").read_bytes()
base_doc = (root / "BASE.md").read_text(encoding="utf-8")
check(manifest_file == manifest, "Z1", "MANIFEST exact regular-file set")
check(meta.get("treeDigestSha256") == digest, "Z1", "treeDigestSha256")
check(re.fullmatch(r"[0-9a-f]{64}", meta.get("baseDigestSha256", "")) is not None and meta["baseDigestSha256"] != zero, "Z1", "base provenance digest")
check(meta.get("baseDigestSha256") in base_doc, "Z1", "BASE/meta provenance match")

workers = meta.get("workers", [])
roles = [item.get("role") for item in workers]
check(len(workers) == 7 and roles == ["init", "plan", "plan-review", "implement", "code-review", "review-fix", "release"], "Z2", "resident workers=7")
check(all("grok" not in item.get("command", "").lower() for item in workers), "Z2", "worker commands have no Grok runtime")
check(meta.get("coordinator", {}).get("agent") == "claude", "Z2", "Claude coordinator")

active_files = [root / "meta.json", root / "PLAYBOOK.md", root / "SKILL.md", root / "LESSONS.md"]
active_files += [root / "prompts/quick-command.txt", root / "prompts/quick-command.CANONICAL.txt"]
active_files += list((root / "templates").glob("**/*"))
active_text = "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in active_files if path.is_file())
legacy_leaks = (".orca/scv", ".grok/skills/scv", ".scv/state")
shared_targets = (".claude/skills/orchestration", ".agents/skills/orchestration")
check(not any(item in active_text for item in legacy_leaks), "Z3", "no active base-path leakage")
check(not any(item in active_text for item in shared_targets), "Z3", "no active shared orchestration reference")
check(meta.get("stateRoot") == ".zealot/state/$RUN_ID/", "Z3", "isolated state root")

vendor = root / "vendor" / "orchestration"
vendor_digest, _ = tree_digest(vendor)
install_digest, _ = tree_digest(orch_install) if orch_install.is_dir() else ("", b"")
check(skill_canon.is_file() and skill_canon.read_bytes() == (root / "SKILL.md").read_bytes(), "Z4", "zealot skill pin")
check(vendor_digest == meta.get("orchestrationVendorDigest"), "Z4", "vendor digest metadata")
check(install_digest == vendor_digest, "Z4", "dedicated orchestration install pin")
orch_text = (vendor / "SKILL.md").read_text(encoding="utf-8")
check(all(anchor in orch_text for anchor in ("worker_done", "--task-id", "worker_done,escalation,decision_gate", "result.task.id")), "Z4", "orchestration anchors")

check("inheritsPlaybookFrom" not in active_text, "Z5", "no runtime inheritance")

ux = (root / "UX.md").read_text(encoding="utf-8")
canon_lines = [
    "My life for Aiur!", "What battle calls?", "Issah'tu!", "I long for combat!",
    "Gee'hous!", "Gau'gurah!", "Thus I serve!", "Honor guide me!", "For Adun!",
    "En Taro Adun!", "Doom to all who threaten the homeworld!",
]
check(all(item in ux for item in canon_lines), "Z6", "canonical zealot_line inventory")
check("Life for Aiur!" not in ux and "Doom to all who threaten the homeworld.`" not in ux and "Doom to all who threaten the homeworld.\n" not in ux, "Z6", "noncanonical variants absent")
check("엔진 (내부·CLI)" in ux and all(item in ux for item in ("작업 완료", "작업 완료 대기", "생존 신호", "승인 대기")), "Z6b", "inline Korean engine label table")

with tempfile.TemporaryDirectory(prefix="zealot-z7-") as temp_home:
    env = os.environ.copy()
    for inherited in ("ZEALOT_HOME", "ZEALOT_SKILL_HOME", "ZEALOT_SKILL_CANON", "ZEALOT_ORCH_INSTALL"):
        env.pop(inherited, None)
    env.update({"HOME": temp_home, "ZEALOT_SOURCE": str(root), "ZEALOT_SYNC_SKIP_SELFCHECK": "1"})
    result = subprocess.run(["bash", str(root / "sync-from-source.sh")], env=env, text=True, capture_output=True)
    temp = Path(temp_home)
    isolated_ok = result.returncode == 0
    isolated_ok &= (temp / ".orca/zealot/SKILL.md").is_file()
    isolated_ok &= (temp / ".claude/skills/zealot/SKILL.md").is_file()
    isolated_ok &= (temp / ".claude/skills/zealot-orchestration/SKILL.md").is_file()
    isolated_ok &= not (temp / ".claude/skills/orchestration").exists()
    isolated_ok &= not (temp / ".agents/skills/orchestration").exists()
    isolated_ok &= not (temp / ".grok").exists()
    if not isolated_ok:
        print("Z7 sync stdout:", result.stdout)
        print("Z7 sync stderr:", result.stderr)
    check(isolated_ok, "Z7", "isolated HOME sync")

prose_paths = [root / name for name in ("PLAYBOOK.md", "UX.md", "LESSONS.md", "SKILL.md", "meta.json", "BASE.md")]
prose_paths += [root / "prompts/quick-command.txt", root / "prompts/quick-command.CANONICAL.txt"]
prose_paths += [p for p in (root / "templates").glob("**/*") if p.is_file()]
prose_paths += [p for p in (root / "vendor/orchestration").glob("**/*") if p.is_file()]
prose_paths += list((root / "fixtures").glob("*.md"))
bad_dependency = re.compile(r"Coordinator Grok only|You are Grok coordinator|command\s+-v\s+grok|skillMirror.{0,30}(?:required|필수)", re.I)
bad_hits = []
for path in prose_paths:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if bad_dependency.search(text):
        bad_hits.append(path.relative_to(root).as_posix())
check(not bad_hits, "Z8", "no Grok coordinator or mirror dependency prose")

d1 = json.loads((root / "fixtures/d1-run.json").read_text(encoding="utf-8"))
d2 = json.loads((root / "fixtures/d2-role-handles.json").read_text(encoding="utf-8"))
d1_handles = [item["handle"] for item in d1["terminals"]]
check(d1["coordinatorHandle"] not in d1_handles and d1["coordinatorHandle"] not in d1["reclaimAllowlist"], "Z9", "D1 coordinator excluded")
d2_handles = list(d2["roleHandles"].values())
check(len(d2_handles) == len(set(d2_handles)) == 4 and d2["coordinatorHandle"] not in d2_handles, "Z9", "D2 distinct dual-role handles")
d3 = subprocess.run(["bash", str(root / "fixtures/d3-coord-allowlist.sh"), str(root / "fixtures/d1-run.json")], text=True, capture_output=True)
check(d3.returncode == 0, "Z9", "D3 coordinator allowlist script")
d4 = (root / "fixtures/d4-decisions-keys.md").read_text(encoding="utf-8")
check(all(key in d4 for key in ("init:coordinator-exception", "plan:coordinator-exception", "code-review:coordinator-exception", "release:coordinator-exception")), "Z9", "D4 inline-delegation exception keys")
d5 = (root / "fixtures/d5-session-policy.md").read_text(encoding="utf-8")
check(all(item in d5 for item in ("same role and phase-loop", "cross-role", "Audit Claude", "fresh handle")), "Z9", "D5 session policy")
gates = json.loads((root / "fixtures/gates-option-ids.json").read_text(encoding="utf-8"))
expected_gates = {
    "plan_approve": {"approve": "PLAN_APPROVED", "revise": "PLAN_REVISE", "abort": "ABORTED"},
    "scope_expand": {"keep_scope": "SCOPE_KEEP", "defer": "SCOPE_DEFER", "expand_now": "SCOPE_EXPAND"},
    "risk_p0p1": {"accept_risk": "RISK_ACCEPTED", "fix_resume": "RISK_FIX", "abort": "ABORTED"},
    "dirty_branch": {"split_commit": "DIRTY_SPLIT", "stash": "DIRTY_STASH", "abort": "ABORTED"},
    "push_release": {"push": "PUSH_GO", "hold": "PUSH_HOLD", "abort": "ABORTED"},
    "reclaim_optin": {"reclaim": "RECLAIM_YES", "keep": "RECLAIM_NO"},
    "hang_giveup": {"retry": "HANG_RETRY", "abort": "ABORTED"},
}
check({key: value["options"] for key, value in gates["gates"].items()} == expected_gates, "Z9", "gate optionId/resultCode equivalence")
s1 = json.loads((root / "fixtures/s1-plan-gate.json").read_text(encoding="utf-8"))
check(s1["gateStatus"] == "unresolved" and s1["implementDispatchCount"] == 0, "Z9", "S1 plan gate blocks implement")

def triggers(text: str) -> bool:
    return re.fullmatch(r"[ \t]*/zealot(?:[ \t]+[^\r\n]*)?[ \t]*", text) is not None

positive = ["/zealot", "/zealot ship the login fix", "  /zealot audit this branch  "]
negative = ["zealot", "please run /zealot", "/zealotish", '"/zealot"', "`/zealot`", "```text /zealot ```", "https://example.test/docs//zealot", "quote: '/zealot ship it'"]
trigger_fixture = (root / "fixtures/triggers.md").read_text(encoding="utf-8")
skill = (root / "SKILL.md").read_text(encoding="utf-8")
check(all(triggers(item) for item in positive) and not any(triggers(item) for item in negative), "Z10", "T+ and T- parser")
check(all(f"T+{n}" in trigger_fixture for n in range(1, 4)) and all(f"T-{n}" in trigger_fixture for n in range(1, 9)), "Z10", "trigger fixture coverage")
check("standalone slash command /zealot" in skill and "bare \"zealot\"" in skill and "URLs" in skill, "Z10", "SKILL trigger enforcement")

check(all(item in skill for item in ("1.0.0", "result.task.id", "result.dispatch.id", "[zealot:$RUN_ID]", "zealot_line", "LIFECYCLE")), "Z11", "SKILL pack/RPC/task-title/UX")
check((root / "prompts/quick-command.txt").read_bytes() == (root / "prompts/quick-command.CANONICAL.txt").read_bytes(), "Z12", "quick-command sync")

source_lines = (root / "CHECK_MATRIX.source-ids.txt").read_text(encoding="utf-8").splitlines()
source_rows = [line.split("\t", 2) for line in source_lines[1:] if line.strip()]
N = {row[0] for row in source_rows if len(row) == 3 and row[1] == ""}
matrix_rows = []
for line in (root / "CHECK_MATRIX.md").read_text(encoding="utf-8").splitlines():
    if not line.startswith("| `scv-selfcheck.sh:"):
        continue
    cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
    if len(cells) >= 6:
        matrix_rows.append(cells)
M = {row[0].strip("`") for row in matrix_rows if row[4] == ""}
check(N == M and bool(N), "Z13", "N⊆M and M⊆N exact set")
matrix_text = (root / "CHECK_MATRIX.md").read_text(encoding="utf-8")
minimum_categories = ["필수파일", "packVersion", "RPC", "wait", "worker_done", "AskUser", "session", "audit/reclaim", "mid-run", "handoff", "LESSONS", "meta structural", "UX", "stuck/re-inject", "task labels"]
check(all(category in matrix_text for category in minimum_categories), "Z13", "minimum non-Grok categories")

if failures:
    print(f"RESULT: FAIL ({len(failures)})")
    raise SystemExit(1)
print("RESULT: PASS")
PY
