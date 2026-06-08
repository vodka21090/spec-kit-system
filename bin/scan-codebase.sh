#!/usr/bin/env bash
# Scan a git repository -> TSV manifest: path, token estimate (bytes/4), content
# hash (git hash-object), top-level module. .gitignore is respected via git ls-files.
# Usage: scan-codebase.sh [sub-path] [out-file]   (default scope: whole repo)
#   With out-file, writes the manifest there (UTF-8/LF). Without it, prints to stdout.
# Requires a git repository. No Python/uv. Emits LF line endings.
set -euo pipefail

SCOPE="${1:-.}"
OUT="${2:-}"

case "$SCOPE" in
  *..*) echo "ERROR: scope must not contain '..': $SCOPE" >&2; exit 2 ;;
  /*)   echo "ERROR: scope must not be absolute: $SCOPE" >&2; exit 2 ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not a git repository -- scanner requires git ls-files" >&2
  exit 3
fi

SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

prefix=""
[ "$SCOPE" != "." ] && prefix="${SCOPE%/}/"

# Exclude map-codebase's own generated outputs — docs/codebase/ (the 8 docs plus this
# manifest) and AGENTS.md (map-codebase upserts its block there every run). Scanning them
# would make the map look changed on every regenerate and stop the incremental no-op
# short-circuit from ever firing. AGENTS.md is also newly-created on first run (untracked
# at scan time, tracked after the user commits) — excluding it avoids that false "added".
body="$(
  git -c core.quotePath=false ls-files -- "$SCOPE" ':(exclude)docs/codebase/' ':(exclude)AGENTS.md' | while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    bytes=$(wc -c < "$f")
    tokens=$(( bytes / 4 ))
    hash=$(git hash-object "$f")
    rel="${f#"$prefix"}"
    case "$rel" in
      */*) module="${rel%%/*}" ;;
      *)   module="(root)" ;;
    esac
    printf '%s\t%s\t%s\t%s\n' "$f" "$tokens" "$hash" "$module"
  done | LC_ALL=C sort -t"$(printf '\t')" -k1,1
)"

if [ -z "$body" ]; then
  total_files=0
  total_tokens=0
else
  total_files=$(printf '%s\n' "$body" | wc -l | tr -d ' ')
  total_tokens=$(printf '%s\n' "$body" | awk -F'\t' '{s+=$2} END{print s+0}')
fi

emit() {
  printf '# scan_version: 1\n'
  printf '# source_sha: %s\n' "$SHA"
  printf '# scan_scope: %s\n' "$SCOPE"
  printf '# total_files: %s\n' "$total_files"
  printf '# total_tokens: %s\n' "$total_tokens"
  printf 'path\ttokens\thash\tmodule\n'
  [ -n "$body" ] && printf '%s\n' "$body"
}

if [ -n "$OUT" ]; then
  emit > "$OUT"
else
  emit
fi
