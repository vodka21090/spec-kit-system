#!/usr/bin/env bash
# Bootstrap a project with spec-kit convention by copying assets/specify → ./.specify
# Usage: init-project.sh [target_dir]
# Idempotent: skips files that already exist unless --force is passed.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SOURCE_DIR="$PLUGIN_ROOT/assets/specify"
TARGET_DIR="${1:-$PWD}/.specify"
FORCE="${FORCE:-0}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: source payload not found at $SOURCE_DIR" >&2
  exit 1
fi

if [[ -d "$TARGET_DIR" && "$FORCE" != "1" ]]; then
  echo "INFO: $TARGET_DIR already exists — leaving it untouched. Set FORCE=1 to overwrite."
  exit 0
fi

mkdir -p "$TARGET_DIR"
cp -R "$SOURCE_DIR/." "$TARGET_DIR/"
echo "OK: bootstrapped .specify at $TARGET_DIR (from $SOURCE_DIR)"
