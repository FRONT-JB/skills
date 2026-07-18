# letsgo HTML templates

| File | Role |
|------|------|
| `explainer.shell.html` | Revolut-styled self-contained shell (CSS + landmarks + SLOT markers) |

## Design worker flow

```bash
OUT="$HOME/Desktop/letsgo/<branch>"
cp "$HOME/.orca/letsgo/templates/explainer.shell.html" "$OUT/explainer.html"
# Then fill SLOTs / sections from $OUT/explainer.md using DESIGN.md tokens already in :root
```

**Do not** regenerate the `<style>` block from scratch. Fill content only.

Optional filled reference: `$HOME/Desktop/letsgo/<branch>/explainer.html` (structure only).

DESIGN tokens: `$HOME/.orca/letsgo/DESIGN.md` (Revolut).

Path policy: `$HOME` / repo-relative only — never absolute `<absolute-home>/...`.
