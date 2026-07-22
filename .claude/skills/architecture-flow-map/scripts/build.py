#!/usr/bin/env python3
"""
Inject a project's architecture data into the template and emit a self-contained HTML artifact.

Usage:
    python3 build.py <data.json> <output.html> [template.html]

- <data.json>   : the project you analyzed, in the schema described in references/data-schema.md
- <output.html> : path to write the finished single-file artifact
- [template.html]: optional; defaults to ../assets/template.html next to this script

The script validates referential integrity (every node.cat is a declared column; every flow
step from/to points at a real node id) and fails loudly on problems, so a broken map never ships.
"""
import json
import pathlib
import sys


def die(msg):
    print(f"[build.py] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) < 3:
        die("usage: build.py <data.json> <output.html> [template.html]")

    data_path = pathlib.Path(sys.argv[1])
    out_path = pathlib.Path(sys.argv[2])
    here = pathlib.Path(__file__).resolve().parent
    tpl_path = pathlib.Path(sys.argv[3]) if len(sys.argv) > 3 else here.parent / "assets" / "template.html"

    if not tpl_path.exists():
        die(f"template not found: {tpl_path}")
    if not data_path.exists():
        die(f"data.json not found: {data_path}")

    try:
        data = json.loads(data_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        die(f"data.json is not valid JSON: {e}")

    # ---- structural validation ----
    for key in ("meta", "cats", "cols", "nodes", "flows"):
        if key not in data:
            die(f"data.json is missing top-level key: {key!r}")
    if not isinstance(data["cols"], list) or not data["cols"]:
        die("`cols` must be a non-empty array of category keys (column order)")
    if not isinstance(data["nodes"], list) or not data["nodes"]:
        die("`nodes` must be a non-empty array")
    if not data.get("meta", {}).get("title"):
        die("`meta.title` is required (used for <title>, header, and the artifact name)")

    cols = data["cols"]
    cats = data["cats"]
    for c in cols:
        if c not in cats:
            die(f"column {c!r} has no entry in `cats` (need cats[{c!r}] = {{\"label\": ...}})")

    node_ids = set()
    for n in data["nodes"]:
        for f in ("id", "cat", "lab"):
            if f not in n:
                die(f"node missing {f!r}: {n}")
        if n["id"] in node_ids:
            die(f"duplicate node id: {n['id']!r}")
        node_ids.add(n["id"])
        if n["cat"] not in cols:
            die(f"node {n['id']!r} has cat {n['cat']!r} which is not in `cols` {cols}")

    flow_ids = set()
    for fl in data["flows"]:
        for f in ("id", "name", "steps"):
            if f not in fl:
                die(f"flow missing {f!r}: {fl.get('id', fl)}")
        if fl["id"] in flow_ids:
            die(f"duplicate flow id: {fl['id']!r}")
        flow_ids.add(fl["id"])
        for i, s in enumerate(fl["steps"], 1):
            for f in ("from", "to", "ttl"):
                if f not in s:
                    die(f"flow {fl['id']!r} step {i} missing {f!r}")
            for endpoint in ("from", "to"):
                if s[endpoint] not in node_ids:
                    die(f"flow {fl['id']!r} step {i} {endpoint}={s[endpoint]!r} is not a known node id")

    # ---- inject ----
    tpl = tpl_path.read_text(encoding="utf-8")
    if '"__ARCHITECTURE_DATA__"' not in tpl:
        die("template is missing the \"__ARCHITECTURE_DATA__\" marker")
    json_text = json.dumps(data, ensure_ascii=False)
    html = tpl.replace('"__ARCHITECTURE_DATA__"', json_text).replace("__TITLE__", data["meta"]["title"])

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(html, encoding="utf-8")

    ncols = len(cols)
    nnodes = len(data["nodes"])
    nflows = len(data["flows"])
    nsteps = sum(len(f["steps"]) for f in data["flows"])
    print(f"[build.py] OK -> {out_path}")
    print(f"[build.py] {ncols} columns · {nnodes} nodes · {nflows} flows · {nsteps} steps · {len(html):,} bytes")


if __name__ == "__main__":
    main()
