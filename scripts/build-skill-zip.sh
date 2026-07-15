#!/usr/bin/env bash
# Build the claude.ai-uploadable skill zip from the single source-of-truth skill folder.
# Output layout inside the zip: content-agent/{SKILL.md,references/,data/}
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/content_agent/skills/content-agent"
DIST="$REPO_ROOT/dist"
ZIP="$DIST/content-agent-skill.zip"
STAGE="$(mktemp -d)"

trap 'rm -rf "$STAGE"' EXIT

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: $SRC/SKILL.md not found" >&2
  exit 1
fi

mkdir -p "$DIST"
mkdir -p "$STAGE/content-agent"
# Copy SKILL.md plus the references/ and data/ directories, preserving structure.
cp "$SRC/SKILL.md" "$STAGE/content-agent/"
cp -R "$SRC/references" "$STAGE/content-agent/"
cp -R "$SRC/data" "$STAGE/content-agent/"

rm -f "$ZIP"
( cd "$STAGE" && zip -r -q "$ZIP" content-agent )

echo "built $ZIP"
( cd "$STAGE" && zip -sf "$ZIP" >/dev/null 2>&1 ) || true
echo "--- contents ---"
unzip -l "$ZIP"
