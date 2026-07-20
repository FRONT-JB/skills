#!/usr/bin/env bash
# Finalize a resolved zealot snapshot from the pinned read-only base provenance.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCV_SOURCE="${SCV_SOURCE:-$(cd "$ROOT/../scv" && pwd -P)}"

[[ -f "$SCV_SOURCE/meta.json" && -f "$SCV_SOURCE/scv-selfcheck.sh" ]] || {
  echo "missing pinned base source: $SCV_SOURCE" >&2
  exit 1
}

python3 - "$ROOT" "$SCV_SOURCE" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]).resolve()
base = Path(sys.argv[2]).resolve()
zero = "0" * 64
excluded_names = {"MANIFEST.sha256", ".DS_Store"}
digest_fields = ("baseDigestSha256", "treeDigestSha256", "orchestrationVendorDigest")

base_meta = json.loads((base / "meta.json").read_text(encoding="utf-8"))
if base_meta.get("packVersion") != "1.3.9":
    raise SystemExit(f"base packVersion must be 1.3.9, got {base_meta.get('packVersion')!r}")

def regular_files(tree: Path):
    files = []
    for dirpath, dirnames, filenames in os.walk(tree, followlinks=False):
        current = Path(dirpath)
        dirnames[:] = sorted(name for name in dirnames if not (current / name).is_symlink())
        for name in sorted(filenames):
            path = current / name
            if path.is_symlink() or name in excluded_names or name.endswith(".log"):
                continue
            if path.is_file():
                files.append(path)
    return sorted(files, key=lambda p: p.relative_to(tree).as_posix())

def normalized_content(tree: Path, path: Path) -> bytes:
    data = path.read_bytes()
    if path.relative_to(tree).as_posix() != "meta.json":
        return data
    text = data.decode("utf-8")
    for field in digest_fields:
        pattern = rf'("{re.escape(field)}"\s*:\s*")[0-9a-fA-F]{{64}}(")'
        text = re.sub(pattern, rf'\g<1>{zero}\g<2>', text)
    return text.encode("utf-8")

def manifest_bytes(tree: Path) -> bytes:
    rows = []
    for path in regular_files(tree):
        rel = path.relative_to(tree).as_posix()
        digest = hashlib.sha256(normalized_content(tree, path)).hexdigest()
        rows.append(f"{digest}  {rel}\n")
    return "".join(rows).encode("utf-8")

def tree_digest(tree: Path) -> tuple[str, bytes]:
    manifest = manifest_bytes(tree)
    return hashlib.sha256(manifest).hexdigest(), manifest

def slug(text: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return (value[:52] or "check")

def extract_source_ids(script: Path):
    lines = script.read_text(encoding="utf-8").splitlines()
    rows = []
    in_python = False
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("python3 -c \""):
            short = "python structural assertion"
            rows.append((f"scv-selfcheck.sh:{number}:{slug(short)}", "", short))
            in_python = True
            continue
        if in_python:
            if re.search(r'"\s*(?:\|\||&&)', stripped):
                in_python = False
            continue
        if not re.search(r"\b(?:ok|fail)\s+\"", line):
            continue
        match = re.search(r"\b(?:ok|fail)\s+\"([^\"]+)", line)
        short = match.group(1) if match else stripped
        lowered = short.lower()
        reason = "grok-only" if ("mirror" in lowered or ".grok" in lowered) else ""
        rows.append((f"scv-selfcheck.sh:{number}:{slug(short)}", reason, short))
    seen = set()
    unique = []
    for row in rows:
        if row[0] not in seen:
            seen.add(row[0])
            unique.append(row)
    return unique

def category(short: str) -> tuple[str, str]:
    low = short.lower()
    mappings = [
        (("file ", "missing "), "필수파일", "required file exists"),
        (("packversion",), "packVersion", "pack version and base pin"),
        (("result.task", "split handle", "rpc"), "RPC", "nested RPC id paths"),
        (("worker_done", "lifecycle", "structured"), "worker_done", "structured lifecycle completion"),
        (("askuser", "re-ask"), "AskUser", "human gate UI"),
        (("ready-no-tools", "re-inject", "stuck"), "stuck/re-inject", "hang recovery"),
        (("ndjson", "keepalive", "wait"), "wait", "single-owner wait and parsing"),
        (("handoff",), "handoff", "file handoff contract"),
        (("mid-run", "mid_reclaim"), "mid-run", "mid-run reclaim contract"),
        (("session", "phase-end"), "session", "session reuse contract"),
        (("audit", "reclaim"), "audit/reclaim", "audit and reclaim contracts"),
        (("lessons",), "LESSONS", "hard-rule list"),
        (("meta", "structural"), "meta structural", "structured metadata"),
        (("display-name", "task-title", "title"), "task labels", "task and display labels"),
        (("ux",), "UX", "display contract"),
    ]
    for needles, target, assertion in mappings:
        if any(item in low for item in needles):
            return target, assertion
    return "zealot-selfcheck", "resolved sibling equivalent"

source_rows = extract_source_ids(base / "scv-selfcheck.sh")
source_text = ["scv_check_id\texclude_reason\tshort_what\n"]
matrix_text = [
    "# CHECK_MATRIX\n\n",
    "Generated by `freeze-zealot-from-scv.sh` from the pinned base selfcheck. `CHECK_MATRIX.source-ids.txt` is the independent source for N.\n\n",
    "| scv_check_id | scv_what | zealot_target | assertion | exclude_reason | fixture |\n",
    "|--------------|----------|---------------|-----------|----------------|---------|\n",
]
for check_id, reason, short in source_rows:
    source_text.append(f"{check_id}\t{reason}\t{short}\n")
    target, assertion = category(short)
    fixture = "D1–D5/S1" if target in {"AskUser", "session", "audit/reclaim"} else ""
    safe_short = short.replace("|", "\\|")
    matrix_text.append(f"| `{check_id}` | {safe_short} | {target} | {assertion} | {reason} | {fixture} |\n")
(root / "CHECK_MATRIX.source-ids.txt").write_text("".join(source_text), encoding="utf-8")
(root / "CHECK_MATRIX.md").write_text("".join(matrix_text), encoding="utf-8")

base_digest, _ = tree_digest(base)
vendor_digest, _ = tree_digest(root / "vendor" / "orchestration")

base_doc = root / "BASE.md"
base_text = base_doc.read_text(encoding="utf-8")
base_text = re.sub(r"(?m)^- baseDigestSha256: `[0-9a-f]{64}`$", f"- baseDigestSha256: `{base_digest}`", base_text)
base_doc.write_text(base_text, encoding="utf-8")

meta_path = root / "meta.json"
meta = json.loads(meta_path.read_text(encoding="utf-8"))
meta["baseDigestSha256"] = base_digest
meta["orchestrationVendorDigest"] = vendor_digest
meta["treeDigestSha256"] = zero
meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

resolved_digest, manifest = tree_digest(root)
meta["treeDigestSha256"] = resolved_digest
meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
verified_digest, verified_manifest = tree_digest(root)
if verified_digest != resolved_digest:
    raise SystemExit("tree digest failed placeholder fixed-point check")
(root / "MANIFEST.sha256").write_bytes(verified_manifest)

print(f"baseDigestSha256={base_digest}")
print(f"orchestrationVendorDigest={vendor_digest}")
print(f"treeDigestSha256={resolved_digest}")
print(f"sourceChecks={len(source_rows)}")
PY
