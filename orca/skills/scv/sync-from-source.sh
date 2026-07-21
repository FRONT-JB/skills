#!/usr/bin/env bash
# Sync repo SSOT → install root + OpenCode SKILL mirror, then self-check.
# Source: $HOME/Desktop/project/jb/skills/orca/skills/scv/  (override with SCV_SOURCE)
set -euo pipefail
SOURCE="${SCV_SOURCE:-$HOME/Desktop/project/jb/skills/orca/skills/scv}"
DEST="${SCV_HOME:-$HOME/.orca/scv}"
MIRROR="${SCV_SKILL_MIRROR:-$HOME/.config/opencode/skills/scv/SKILL.md}"

if [[ ! -d "$SOURCE" ]]; then
  echo "missing source: $SOURCE" >&2
  exit 1
fi
if [[ ! -f "$SOURCE/PLAYBOOK.md" || ! -f "$SOURCE/meta.json" ]]; then
  echo "source does not look like scv pack: $SOURCE" >&2
  exit 1
fi

mkdir -p "$DEST" "$(dirname "$MIRROR")"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.DS_Store' \
  "$SOURCE/" "$DEST/"
cp "$DEST/SKILL.md" "$MIRROR"
echo "synced: $SOURCE → $DEST"
echo "mirror: $MIRROR"
"$DEST/scv-selfcheck.sh"
