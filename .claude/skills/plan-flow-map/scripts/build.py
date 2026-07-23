#!/usr/bin/env python3
"""
Render a plan document (a list of typed blocks) into a self-contained dark/light HTML artifact.

Usage:
    python3 build.py <doc.json> <output.html> [template.html]

- <doc.json>    : { "meta": {...}, "blocks": [ {type, ...}, ... ] }  (see references/doc-schema.md)
- <output.html> : path to write the finished single-file artifact
- [template.html]: optional; defaults to ../assets/template.html next to this script

Why this shape: the runtime agent (often several subagents in parallel) only produces block JSON —
the fiddly, escaping-sensitive HTML assembly lives here, once, deterministically. Same palette as
architecture-flow-map, so styling never drifts between runs.
"""
import html as _html
import json
import pathlib
import re
import sys

METHODS = {"get", "post", "patch", "put", "delete"}
TONES = {"gate", "goal", "warn", "info"}


def die(msg):
    print(f"[build.py] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def esc(s):
    return _html.escape("" if s is None else str(s), quote=False)


def inline(s):
    """Escape, then honor a tiny markdown subset: `code`, **bold**. Safe for untrusted plan text."""
    s = esc(s)
    s = re.sub(r"`([^`]+)`", lambda m: "<code>" + m.group(1) + "</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", lambda m: "<b>" + m.group(1) + "</b>", s)
    return s


def as_paragraphs(text):
    if isinstance(text, list):
        items = text
    else:
        items = re.split(r"\n\s*\n", str(text).strip())
    return "".join(f"<p class='blk-p'>{inline(p)}</p>" for p in items if str(p).strip())


_JSON_TOK = re.compile(
    r'(?P<str>"(?:[^"\\]|\\.)*")'
    r'|(?P<num>-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    r'|(?P<lit>true|false|null)'
    r'|(?P<punc>[{}\[\],:])'
    r'|(?P<ws>\s+)'
    r'|(?P<other>.)'
)


def highlight_json(obj):
    """Pretty-print JSON and wrap tokens in Dracula-themed spans (keys/strings/numbers/literals)."""
    s = json.dumps(obj, ensure_ascii=False, indent=2)
    toks = list(_JSON_TOK.finditer(s))
    out = []
    for idx, m in enumerate(toks):
        kind, text = m.lastgroup, m.group()
        if kind == "str":
            is_key = False
            for j in range(idx + 1, len(toks)):
                if toks[j].lastgroup == "ws":
                    continue
                is_key = toks[j].group() == ":"
                break
            out.append(f"<span class='{'tok-key' if is_key else 'tok-str'}'>{esc(text)}</span>")
        elif kind in ("num", "lit", "punc"):
            out.append(f"<span class='tok-{kind}'>{esc(text)}</span>")
        else:
            out.append(esc(text))
    return "".join(out)


def code_html(v):
    """Safe HTML for a code block: Dracula-highlighted if it is (or parses as) JSON, else escaped plain."""
    obj = None
    if isinstance(v, (dict, list)):
        obj = v
    elif isinstance(v, str) and v.strip()[:1] in "{[":
        try:
            obj = json.loads(v)
        except (ValueError, TypeError):
            obj = None
    return highlight_json(obj) if obj is not None else esc(str(v))


# ---------- per-block renderers ----------

def r_heading(b):
    lvl = b.get("level", 2)
    tag, cls = ("h3", "blk-h3") if lvl == 3 else ("h2", "blk-h")
    idattr = f" id='{b['_id']}'" if b.get("_id") else ""
    return f"<{tag}{idattr} class='{cls}'>{inline(b.get('text', ''))}</{tag}>"


def r_prose(b):
    return as_paragraphs(b.get("text", b.get("html", "")))


def _bullet_items(items):
    """Render bullet items; an item may be a string (leaf) or {text, items:[...]} (nested)."""
    out = []
    for it in items:
        if isinstance(it, dict):
            sub = f"<ul class='blk-list'>{_bullet_items(it.get('items', []))}</ul>" if it.get("items") else ""
            out.append(f"<li>{inline(it.get('text', ''))}{sub}</li>")
        else:
            out.append(f"<li>{inline(it)}</li>")
    return "".join(out)


def r_bullets(b):
    tag = "ol" if b.get("ordered") else "ul"
    cls = "blk-list mono" if b.get("mono") else "blk-list"
    sub = f"<div class='blk-sub'>{inline(b['title'])}</div>" if b.get("title") else ""
    return f"{sub}<{tag} class='{cls}'>{_bullet_items(b.get('items', []))}</{tag}>"


def r_callout(b):
    tone = b.get("tone", "info")
    if tone not in TONES:
        tone = "info"
    title = f"<div class='ct-title'>{inline(b['title'])}</div>" if b.get("title") else ""
    body = as_paragraphs(b.get("body", b.get("text", "")))
    return f"<div class='callout tone-{tone}'>{title}<div class='ct-body'>{body}</div></div>"


def r_compare(b):
    cols = b.get("columns", [])
    cards = []
    for i, c in enumerate(cols):
        accent = " accent" if c.get("accent") or i == len(cols) - 1 and b.get("accentLast", True) and len(cols) > 1 else ""
        lis = "".join(f"<li>{inline(x)}</li>" for x in c.get("items", []))
        cards.append(f"<div class='cmp-card{accent}'><div class='cmp-head'>{inline(c.get('label',''))}</div><ul>{lis}</ul></div>")
    return f"<div class='compare'>{''.join(cards)}</div>"


def r_table(b):
    heads = b.get("headers", [])
    thead = ("<thead><tr>" + "".join(f"<th>{inline(h)}</th>" for h in heads) + "</tr></thead>") if heads else ""
    rows = []
    for row in b.get("rows", []):
        rows.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in row) + "</tr>")
    sub = f"<div class='blk-sub'>{inline(b['title'])}</div>" if b.get("title") else ""
    return f"{sub}<div class='table-wrap'><table class='blk-table'>{thead}<tbody>{''.join(rows)}</tbody></table></div>"


def _param_table(p):
    heads = p.get("headers") or ["필드", "타입", "필수", "설명"]
    return r_table({"headers": heads, "rows": p.get("rows", [])})


def r_endpoint(b):
    method = str(b.get("method", "other")).lower()
    mcls = method if method in METHODS else "other"
    tag = f"<span class='ep-tag'>{esc(b['tag'])}</span>" if b.get("tag") else ""
    summ = f"<span class='ep-summary'>{inline(b['summary'])}</span>" if b.get("summary") else ""
    chev = "<svg class='ep-chev' width='13' height='13' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><path d='M9 6l6 6-6 6'/></svg>"
    head = (f"<summary>{chev}<span class='method {mcls}'>{esc(b.get('method','')).upper()}</span>"
            f"<span class='ep-path'>{esc(b.get('path',''))}</span>{tag}{summ}</summary>")

    body = []
    if b.get("desc"):
        body.append(as_paragraphs(b["desc"]))
    if b.get("params"):
        body.append("<div class='blk-sub'>파라미터</div>" + _param_table(b["params"]))
    if b.get("request") is not None:
        body.append("<div class='blk-sub'>요청</div><pre class='code'>" + code_html(b["request"]) + "</pre>")
    if b.get("response") is not None:
        body.append("<div class='blk-sub'>응답</div><pre class='code'>" + code_html(b["response"]) + "</pre>")
    if b.get("note"):
        body.append(r_callout({"tone": "info", "body": b["note"]}))
    openattr = " open" if b.get("open") else ""
    return f"<details class='endpoint'{openattr}>{head}<div class='ep-body'>{''.join(body)}</div></details>"


def r_entity(b):
    head = f"<div class='ent-head'><div class='ent-name'>{esc(b.get('name',''))}</div>"
    if b.get("sub"):
        head += f"<div class='ent-sub'>{inline(b['sub'])}</div>"
    head += "</div>"
    fields = []
    for f in b.get("fields", []):
        note = f"<div class='ent-fnote'>{inline(f['note'])}</div>" if f.get("note") else ""
        fields.append(
            f"<div class='ent-field'><span class='ent-fname'>{esc(f.get('name',''))}</span>"
            f"<span class='ent-ftype'>{esc(f.get('type',''))}</span>{note}</div>"
        )
    rel = ""
    if b.get("relations"):
        rel = "<div class='ent-rel'><b>Relations</b>" + inline(" · ".join(b["relations"])) + "</div>"
    return f"<div class='entity'>{head}{''.join(fields)}{rel}</div>"


def _change_class(text):
    """Map a change label (Korean or English) to a color variant for the tree badge."""
    t = str(text)
    if any(k in t for k in ("삭제", "제거", "del", "remove", "drop")):
        return "del"
    if any(k in t for k in ("신규", "추가", "add", "new")):
        return "add"
    if any(k in t for k in ("재생성", "regen", "생성물", "generated")):
        return "regen"
    return "mod"  # 수정 / 변경 / modify / update / 기본


def r_tree(b):
    sub = f"<div class='blk-sub'>{inline(b['title'])}</div>" if b.get("title") else ""
    rows = []
    for ln in b.get("lines", []):
        depth = int(ln.get("depth", 0))
        kind = "dir" if ln.get("kind") == "dir" else "file"
        pad = 6 + depth * 18
        change = ln.get("change")
        cls = _change_class(change) if change else ""
        row_cls = f"tree-row {kind}" + (f" {cls}" if cls else "")
        chg = f"<span class='tree-change {cls}'>{esc(change)}</span>" if change else ""
        tag = f"<span class='tree-tag'>{esc(ln['tag'])}</span>" if ln.get("tag") else ""
        note = f"<span class='tree-note'>{inline(ln['note'])}</span>" if ln.get("note") else ""
        rows.append(
            f"<div class='{row_cls}' style='padding-left:{pad}px'>"
            f"<span class='tree-name'>{esc(ln.get('name',''))}</span>{chg}{tag}{note}</div>"
        )
    return f"{sub}<div class='tree'>{''.join(rows)}</div>"


def r_code(b):
    title = f"<div class='code-title'>{esc(b['title'])}</div>" if b.get("title") else ""
    first = "" if title else " first"
    return f"{title}<pre class='code{first}'>{code_html(b.get('text', b.get('code', '')))}</pre>"


def r_stats(b):
    """At-a-glance metric chips: value + label. Used mostly in the summary hero."""
    cells = []
    for it in b.get("items", []):
        cells.append(
            f"<div class='stat'><div class='stat-v'>{inline(it.get('value',''))}</div>"
            f"<div class='stat-l'>{inline(it.get('label',''))}</div></div>"
        )
    return f"<div class='stats'>{''.join(cells)}</div>"


RENDERERS = {
    "heading": r_heading, "prose": r_prose, "bullets": r_bullets, "callout": r_callout,
    "compare": r_compare, "table": r_table, "endpoint": r_endpoint, "entity": r_entity,
    "tree": r_tree, "code": r_code, "stats": r_stats,
}


_SEC_CHEV = ("<svg class='sec-chev' width='14' height='14' viewBox='0 0 24 24' fill='none' "
             "stroke='currentColor' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'>"
             "<path d='M9 6l6 6-6 6'/></svg>")


def render_sections(blocks):
    """Group blocks by level-2 heading. The heading flagged `summary:true` renders as an always-open
    hero panel; every other section becomes a <details> that starts collapsed (progressive disclosure)."""
    groups, cur = [], None
    for b in blocks:
        if isinstance(b, dict) and b.get("type") == "heading" and b.get("level", 2) == 2:
            cur = {"h": b, "body": []}
            groups.append(cur)
        else:
            if cur is None:
                cur = {"h": None, "body": []}
                groups.append(cur)
            cur["body"].append(b)

    out = []
    for g in groups:
        body_html = "\n".join(render_block(b, i) for i, b in enumerate(g["body"]))
        h = g["h"]
        if h is None:
            out.append(body_html)
            continue
        title, sid = inline(h.get("text", "")), h.get("_id", "")
        if h.get("summary"):
            out.append(f"<section class='hero' id='{sid}'><h2 class='hero-h'>{title}</h2>{body_html}</section>")
        else:
            out.append(
                f"<details class='section' id='{sid}'>"
                f"<summary>{_SEC_CHEV}<span class='sec-h'>{title}</span></summary>"
                f"<div class='section-body'>{body_html}</div></details>"
            )
    return "\n".join(out)


def render_block(b, i):
    if not isinstance(b, dict) or "type" not in b:
        die(f"block #{i} is not an object with a `type`: {b!r}")
    t = b["type"]
    if t not in RENDERERS:
        die(f"block #{i} has unknown type {t!r}. Known: {', '.join(sorted(RENDERERS))}")
    return RENDERERS[t](b)


def render_toc(sections):
    """Compact 'on this page' nav — only when there are enough sections to be worth skimming."""
    if len(sections) < 3:
        return ""
    lis = "".join(f"<li><a href='#{sid}'>{inline(t)}</a></li>" for sid, t in sections)
    return ("<nav class='toc'><div class='toc-top'><div class='toc-label'>이 문서</div>"
            "<button id='expandAll' class='toc-exp' type='button'>모두 펼치기</button></div>"
            f"<ol>{lis}</ol></nav>")


def render_header(meta):
    out = ["<header class='doc-head'>"]
    if meta.get("eyebrow"):
        out.append(f"<div class='eyebrow'>{esc(meta['eyebrow'])}</div>")
    out.append(f"<h1 class='doc-title'>{inline(meta['title'])}</h1>")
    if meta.get("subtitle"):
        out.append(f"<p class='subtitle'>{inline(meta['subtitle'])}</p>")
    if meta.get("source"):
        icon = ("<svg viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' "
                "stroke-linecap='round' stroke-linejoin='round'><line x1='6' y1='3' x2='6' y2='15'/>"
                "<circle cx='18' cy='6' r='3'/><circle cx='6' cy='18' r='3'/><path d='M18 9a9 9 0 0 1-9 9'/></svg>")
        out.append(f"<div class='source-badge'>{icon}{inline(meta['source'])}</div>")
    out.append("</header><hr class='head-rule'>")
    return "".join(out)


def main():
    if len(sys.argv) < 3:
        die("usage: build.py <doc.json> <output.html> [template.html]")

    doc_path = pathlib.Path(sys.argv[1])
    out_path = pathlib.Path(sys.argv[2])
    here = pathlib.Path(__file__).resolve().parent
    tpl_path = pathlib.Path(sys.argv[3]) if len(sys.argv) > 3 else here.parent / "assets" / "template.html"

    if not tpl_path.exists():
        die(f"template not found: {tpl_path}")
    if not doc_path.exists():
        die(f"doc.json not found: {doc_path}")
    try:
        doc = json.loads(doc_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        die(f"doc.json is not valid JSON: {e}")

    meta = doc.get("meta", {})
    if not isinstance(meta, dict) or not meta.get("title"):
        die("`meta.title` is required")
    blocks = doc.get("blocks")
    if not isinstance(blocks, list) or not blocks:
        die("`blocks` must be a non-empty array")

    # assign anchor ids to top-level headings + collect a table of contents
    sections = []
    hn = 0
    for b in blocks:
        if isinstance(b, dict) and b.get("type") == "heading" and b.get("level", 2) == 2:
            hn += 1
            b["_id"] = f"sec-{hn}"
            if not b.get("summary"):  # the hero is always visible; don't list it in the TOC
                sections.append((b["_id"], b.get("text", "")))

    body = render_header(meta) + render_toc(sections) + render_sections(blocks)

    tpl = tpl_path.read_text(encoding="utf-8")
    for marker in ("__TITLE__", "__DOC_BODY__"):
        if marker not in tpl:
            die(f"template is missing the {marker} marker")
    htmlout = tpl.replace("__DOC_BODY__", body).replace("__TITLE__", esc(meta["title"]))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(htmlout, encoding="utf-8")

    counts = {}
    for b in blocks:
        counts[b["type"]] = counts.get(b["type"], 0) + 1
    summary = ", ".join(f"{k}×{v}" for k, v in sorted(counts.items()))
    print(f"[build.py] OK -> {out_path}")
    print(f"[build.py] {len(blocks)} blocks ({summary}) · {len(htmlout):,} bytes")


if __name__ == "__main__":
    main()
