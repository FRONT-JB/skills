# zealot build provenance

- Contract: draft v3.2.2
- Pack: `zealot@1.0.0`
- Build-time base: version `1.3.9`
- Base source: sibling `../scv/` or explicit `SCV_SOURCE`
- baseDigestSha256: `12c0b5f9ccc53011e25acec0d273563a96a67b0be9f1ca7bc88b73618232e9ee`

The base is read only by `freeze-zealot-from-scv.sh`. Runtime is a fully resolved tree and has no dependency on the base pack or Grok. `baseDigestSha256` records provenance only; it does not by itself prove that the resolved tree contains unchanged base bytes. `treeDigestSha256` and `MANIFEST.sha256` protect the resolved runtime tree.

Allowed deltas are limited to the mode name and isolated paths, Claude coordinator/init/release workers, `/zealot`-only trigger enforcement, canonical `zealot_line` UX, structured gate identifiers, dedicated vendored orchestration, fixtures, and digest/selfcheck packaging. The sibling base behavior is not modified.

The dedicated install is `$HOME/.claude/skills/zealot-orchestration/`. Shared orchestration install paths are forbidden and remain untouched.
