#!/usr/bin/env python3
"""
Hybrid pipeline · stage 1 (deterministic, NO LLM).

Convert a plan markdown file into the plan-block schema (`{meta, blocks:[...]}`) using only
structural parsing — headings, markdown tables (file tables → tree, else table), fenced code,
blockquotes → callouts, lists → bullets, paragraphs → prose. Produces a lossless, structurally
correct doc.json with ZERO tokens. What it does NOT do (leave to a light LLM pass): compress prose,
synthesize the hero summary, or make semantic block upgrades (e.g. prose that is really an API).

Usage:
    python3 parse_md.py <plan.md> <out.doc.json> [--hero <hero_blocks.json>] [--title "..."]

`--hero` prepends an already-produced hero block array (so a cached/LLM hero can ride on top of the
free deterministic body).
"""
import json
import re
import sys
import pathlib

TONE_KEYS = [
    ("gate", ("게이트", "gate", "완료 조건", "완료조건", "acceptance", "done when", "통과 기준")),
    ("warn", ("경고", "주의", "위험", "risk", "pitfall", "caution", "금지")),
    ("goal", ("목표", "goal", "objective")),
]


def tone_of(text):
    t = text.lower()
    for tone, keys in TONE_KEYS:
        if any(k.lower() in t for k in keys):
            return tone
    return "info"


def strip_bt(s):
    return s.strip().strip("`").strip()


def is_table_row(line):
    return line.lstrip().startswith("|")


def is_table_sep(line):
    return bool(re.match(r"^\s*\|?[\s:|-]*-{2,}[\s:|-]*\|?\s*$", line)) and "-" in line


def split_cells(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def col_index(headers, keys):
    for i, h in enumerate(headers):
        hl = h.lower()
        if any(k in hl for k in keys):
            return i
    return -1


def build_tree_lines(rows, path_i, change_i, desc_i):
    seen, lines = set(), []
    for cells in rows:
        path = strip_bt(cells[path_i]) if path_i < len(cells) else ""
        if not path:
            continue
        change = cells[change_i].strip() if 0 <= change_i < len(cells) else ""
        note = cells[desc_i].strip() if 0 <= desc_i < len(cells) else ""
        segs = [s for s in path.split("/") if s]
        for d in range(len(segs) - 1):
            prefix = "/".join(segs[: d + 1])
            if prefix not in seen:
                seen.add(prefix)
                lines.append({"depth": d, "name": segs[d] + "/", "kind": "dir"})
        leaf = {"depth": max(0, len(segs) - 1), "name": segs[-1] if segs else path, "kind": "file"}
        if change:
            leaf["change"] = change
        if note:
            leaf["note"] = note
        lines.append(leaf)
    return lines


def looks_like_dirtree(body):
    """Heuristic: a fenced block that is a directory listing (path tokens, ≥1 trailing-slash dir,
    optional `# comment`), NOT shell/JSON. Conservative — misfires stay as code."""
    raw = [ln for ln in body.split("\n") if ln.strip()]
    if len(raw) < 3:
        return False
    path_like, has_dir = 0, False
    for ln in raw:
        core = ln.split("#", 1)[0].strip()
        if not core:
            continue
        if any(c in core for c in "{}|;$=()`\""):
            return False  # shell / JSON / code, not a tree
        if re.match(r"^[\w./\-]+$", core):
            path_like += 1
            if core.endswith("/"):
                has_dir = True
    return has_dir and path_like >= max(3, int(len(raw) * 0.7))


def dirtree_block(body):
    raw = [ln for ln in body.split("\n") if ln.strip()]
    def ind(ln):
        return len(ln) - len(ln.lstrip())
    levels = {v: k for k, v in enumerate(sorted({ind(ln) for ln in raw}))}
    lines = []
    for ln in raw:
        core, _, comment = ln.partition("#")
        name = core.strip()
        item = {"depth": levels[ind(ln)], "name": name, "kind": "dir" if name.endswith("/") else "file"}
        if comment.strip():
            item["note"] = comment.strip()
        lines.append(item)
    return {"type": "tree", "lines": lines}


def table_block(headers, rows):
    # file-scope table (경로/glob + 변경 종류) → tree; otherwise a plain table
    path_i = col_index(headers, ("경로", "glob", "path", "파일"))
    change_i = col_index(headers, ("변경", "종류", "kind", "change"))
    if path_i != -1 and change_i != -1:
        desc_i = col_index(headers, ("설명", "desc", "비고", "note"))
        return {"type": "tree", "lines": build_tree_lines(rows, path_i, change_i, desc_i)}
    return {"type": "table", "headers": headers, "rows": rows}


def is_list(line):
    return bool(re.match(r"^\s*([-*]|\d+\.)\s+", line))


def list_item_text(line):
    return re.sub(r"^\s*([-*]|\d+\.)\s+", "", line).rstrip()


def looks_mono(items):
    hits = sum(1 for it in items if re.match(r"^\s*`?(pnpm|python3?|bash|git|npx|node|xdg-open|open|rg|grep) ", it) or (it.count("/") >= 1 and " " not in it.strip("`")))
    return hits >= max(2, (len(items) + 1) // 2)


def _indent(line):
    return len(line) - len(line.lstrip())


def collect_list(lines, start, n):
    """Collect a (possibly nested) list. Returns (items_tree, ordered, flat_texts, next_index).
    Indentation determines nesting; deeper-indented list items become children of the previous item."""
    entries = []  # [indent, text]
    j = start
    ordered = bool(re.match(r"^\s*\d+\.", lines[start]))
    while j < n:
        ln = lines[j]
        if is_list(ln):
            entries.append([_indent(ln), list_item_text(ln)])
            j += 1
        elif ln.strip() and _indent(ln) > 0 and entries:  # continuation of previous item's text
            entries[-1][1] += " " + ln.strip()
            j += 1
        else:
            break
    root = []
    stack = [(-1, root)]  # (indent, siblings-list)
    flat = []
    for indent, text in entries:
        flat.append(text)
        node = {"text": text, "_kids": []}
        while len(stack) > 1 and indent <= stack[-1][0]:
            stack.pop()
        stack[-1][1].append(node)
        stack.append((indent, node["_kids"]))

    def to_item(nd):
        if nd["_kids"]:
            return {"text": nd["text"], "items": [to_item(k) for k in nd["_kids"]]}
        return nd["text"]

    return [to_item(x) for x in root], ordered, flat, j


def parse(md_text):
    lines = md_text.split("\n")
    blocks = []
    title = None
    i, n = 0, len(lines)
    prev_bold_title = None  # a standalone **X** line right before a list becomes its title

    def flush_para(buf):
        text = " ".join(x.strip() for x in buf).strip()
        if text:
            blocks.append({"type": "prose", "text": text})

    while i < n:
        line = lines[i]
        s = line.strip()

        if not s:
            i += 1
            prev_bold_title = None
            continue

        # title / horizontal rule
        if s.startswith("# ") and title is None:
            title = s[2:].strip()
            i += 1
            continue
        if re.match(r"^-{3,}$", s):
            i += 1
            continue

        # heading
        m = re.match(r"^(#{2,6})\s+(.*)$", s)
        if m:
            level = 2 if len(m.group(1)) == 2 else 3
            blocks.append({"type": "heading", "level": level, "text": m.group(2).strip()})
            i += 1
            prev_bold_title = None
            continue

        # fenced code
        if s.startswith("```"):
            lang = s[3:].strip()
            j = i + 1
            body = []
            while j < n and not lines[j].strip().startswith("```"):
                body.append(lines[j])
                j += 1
            body_text = "\n".join(body)
            if lang.lower() in ("", "text", "txt", "tree") and looks_like_dirtree(body_text):
                blocks.append(dirtree_block(body_text))  # 디렉토리 구조 코드펜스 → tree 블록
            else:
                blk = {"type": "code", "text": body_text}
                if lang:
                    blk["lang"] = lang
                blocks.append(blk)
            i = j + 1
            continue

        # table
        if is_table_row(line) and i + 1 < n and is_table_sep(lines[i + 1]):
            headers = split_cells(line)
            j = i + 2
            rows = []
            while j < n and is_table_row(lines[j]):
                rows.append(split_cells(lines[j]))
                j += 1
            blocks.append(table_block(headers, rows))
            i = j
            prev_bold_title = None
            continue

        # blockquote → callout
        if s.startswith(">"):
            j = i
            buf = []
            while j < n and lines[j].strip().startswith(">"):
                buf.append(re.sub(r"^\s*>\s?", "", lines[j]))
                j += 1
            body = "\n".join(buf).strip()
            blocks.append({"type": "callout", "tone": tone_of(body), "body": body})
            i = j
            continue

        # list (nested-aware)
        if is_list(line):
            items, ordered, flat, j = collect_list(lines, i, n)
            blk = {"type": "bullets", "items": items}
            if ordered:
                blk["ordered"] = True
            if looks_mono(flat):
                blk["mono"] = True
            if prev_bold_title:
                blk["title"] = prev_bold_title
            blocks.append(blk)
            i = j
            prev_bold_title = None
            continue

        # standalone **bold** line → remember as possible next-list title, else prose
        bm = re.match(r"^\*\*(.+?)\*\*:?\s*$", s)
        if bm:
            prev_bold_title = bm.group(1).strip()
            i += 1
            continue

        # paragraph
        buf = [line]
        j = i + 1
        while j < n and lines[j].strip() and not lines[j].strip().startswith(("#", ">", "|", "```", "-", "*")) and not re.match(r"^\s*\d+\.", lines[j]):
            buf.append(lines[j])
            j += 1
        flush_para(buf)
        i = j
        prev_bold_title = None

    return title, blocks


def main():
    if len(sys.argv) < 3:
        print("usage: parse_md.py <plan.md> <out.doc.json> [--hero <hero.json>] [--title ...]", file=sys.stderr)
        sys.exit(1)
    src = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    hero_path = None
    title_override = None
    args = sys.argv[3:]
    for k in range(len(args)):
        if args[k] == "--hero" and k + 1 < len(args):
            hero_path = pathlib.Path(args[k + 1])
        if args[k] == "--title" and k + 1 < len(args):
            title_override = args[k + 1]

    title, blocks = parse(src.read_text(encoding="utf-8"))
    if hero_path and hero_path.exists():
        hero = json.loads(hero_path.read_text(encoding="utf-8"))
        blocks = hero + blocks

    meta = {
        "title": title_override or title or src.stem,
        "eyebrow": "구현 계획",
        "source": f"{src.name} · deterministic parse",
    }
    out.write_text(json.dumps({"meta": meta, "blocks": blocks}, ensure_ascii=False, indent=2), encoding="utf-8")
    counts = {}
    for b in blocks:
        counts[b["type"]] = counts.get(b["type"], 0) + 1
    print(f"[parse_md] OK -> {out}")
    print(f"[parse_md] {len(blocks)} blocks ({', '.join(f'{k}×{v}' for k,v in sorted(counts.items()))})")


if __name__ == "__main__":
    main()
