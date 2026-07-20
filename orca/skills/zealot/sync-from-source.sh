#!/usr/bin/env bash
# Sync repo SSOT to the three zealot-only install roots.
set -euo pipefail

SOURCE="${ZEALOT_SOURCE:-$HOME/Desktop/jb/skills/orca/skills/zealot}"
PACK_DEST="${ZEALOT_HOME:-$HOME/.orca/zealot}"
SKILL_DEST="${ZEALOT_SKILL_HOME:-$HOME/.claude/skills/zealot}"
ORCH_DEST="${ZEALOT_ORCH_INSTALL:-$HOME/.claude/skills/zealot-orchestration}"

require_exact_default_or_override() {
  local value="$1" default_value="$2" label="$3"
  if [[ -z "$value" || "$value" == "/" || "$value" == "$HOME" ]]; then
    echo "unsafe $label: $value" >&2
    exit 1
  fi
  if [[ -z "${ZEALOT_ALLOW_CUSTOM_INSTALLS:-}" && "$value" != "$default_value" ]]; then
    echo "$label must be $default_value (set ZEALOT_ALLOW_CUSTOM_INSTALLS=1 for isolated tests)" >&2
    exit 1
  fi
}

require_exact_default_or_override "$PACK_DEST" "$HOME/.orca/zealot" PACK_DEST
require_exact_default_or_override "$SKILL_DEST" "$HOME/.claude/skills/zealot" SKILL_DEST
require_exact_default_or_override "$ORCH_DEST" "$HOME/.claude/skills/zealot-orchestration" ORCH_DEST

for required in SKILL.md PLAYBOOK.md meta.json MANIFEST.sha256 vendor/orchestration/SKILL.md; do
  [[ -f "$SOURCE/$required" ]] || { echo "missing source file: $required" >&2; exit 1; }
done

mkdir -p "$PACK_DEST" "$SKILL_DEST" "$ORCH_DEST"
rsync -a --delete --exclude '.DS_Store' --exclude '*.log' "$SOURCE/" "$PACK_DEST/"
rsync -a --delete --exclude '.DS_Store' --exclude '*.log' "$SOURCE/" "$SKILL_DEST/"
rsync -a --delete --exclude '.DS_Store' --exclude '*.log' "$SOURCE/vendor/orchestration/" "$ORCH_DEST/"

echo "synced pack: $PACK_DEST"
echo "synced skill: $SKILL_DEST"
echo "synced dedicated orchestration: $ORCH_DEST"

if [[ "${ZEALOT_SYNC_SKIP_SELFCHECK:-0}" != "1" ]]; then
  ZEALOT_HOME="$PACK_DEST" \
  ZEALOT_SKILL_CANON="$SKILL_DEST/SKILL.md" \
  ZEALOT_ORCH_INSTALL="$ORCH_DEST" \
    "$PACK_DEST/zealot-selfcheck.sh"
fi
