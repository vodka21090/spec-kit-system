# Phase 2A — Scanner Primitive + Incremental Re-map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a git-driven, no-Python scanner (`bin/scan-codebase.{sh,ps1}`) that emits a TSV manifest, and wire `/spec-kit:map-codebase` to use it for an exact, no-op-skipping incremental re-map.

**Architecture:** A cross-platform script pair lists tracked files via `git ls-files` (gitignore-correct), estimates tokens as `bytes/4`, hashes content via `git hash-object`, and tags each file with its top-level module — emitting a sorted TSV to stdout. The skill persists this manifest at `docs/codebase/.manifest.tsv` (git-tracked) and, on re-run, diffs a fresh scan against it: empty diff → report "current" and stop; non-empty → suggest a conservative regen set the user confirms. Non-git repos degrade to the existing Phase 1 flow.

**Tech Stack:** Bash + PowerShell (Windows PowerShell 5.1-compatible), `git` plumbing (`ls-files`, `hash-object`, `rev-parse`). No package manager, no test framework (per CLAUDE.md) — verification is shell assertions run manually.

**Spec:** `docs/superpowers/specs/2026-06-01-phase2-scanner-incremental-design.md`

---

## File Structure

- **Create** `bin/scan-codebase.sh` — POSIX scanner (Task 1). One responsibility: emit the TSV manifest for a git repo.
- **Create** `bin/scan-codebase.ps1` — PowerShell scanner (Task 2). Byte-identical output to the `.sh` for the same repo state.
- **Modify** `skills/map-codebase/SKILL.md` — Step 1 recon uses the scanner + persists the manifest + sizes the guardrail from `total_tokens` (Task 3); Step 0(b) becomes exact manifest-diff incremental with no-op skip + conservative coverage table (Task 4); Notes mention the new files (Task 5).
- **Modify** `CLAUDE.md` — Plugin Layout adds `bin/scan-codebase.{sh,ps1}` and the `.manifest.tsv` artifact (Task 5).

Parity hazards controlled in Tasks 1–2: identical token formula (`floor(bytes/4)`), identical hash (`git hash-object`), ordinal/byte sort, LF line endings, line-based file listing (filenames containing newlines are an accepted limitation).

---

### Task 1: POSIX scanner `bin/scan-codebase.sh`

**Files:**
- Create: `bin/scan-codebase.sh`
- Verify: run against this repo (a git repo, ~122 files)

- [ ] **Step 1: Write a failing verification command**

Run (the script does not exist yet):

```bash
bash bin/scan-codebase.sh | head -6
```

Expected: FAIL — `bash: bin/scan-codebase.sh: No such file or directory`.

- [ ] **Step 2: Create the script**

Create `bin/scan-codebase.sh` with exactly:

```bash
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
# manifest) and AGENTS.md (map-codebase upserts its block there every run; also newly-
# created/untracked on first run). Scanning them would make the map look changed on every
# regenerate and stop the incremental no-op short-circuit from ever firing.
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
```

- [ ] **Step 3: Run it and inspect the header + columns**

Run:

```bash
bash bin/scan-codebase.sh > /tmp/scan.sh.tsv && head -8 /tmp/scan.sh.tsv
```

Expected: 5 `#` metadata lines (`scan_version`, `source_sha`, `scan_scope: .`, `total_files`, `total_tokens`), then a `path<TAB>tokens<TAB>hash<TAB>module` header, then TSV rows.

- [ ] **Step 4: Assert a known hash matches git**

Run:

```bash
expected=$(git hash-object bin/init-project.sh)
got=$(awk -F'\t' '$1=="bin/init-project.sh"{print $3}' /tmp/scan.sh.tsv)
test "$expected" = "$got" && echo "HASH OK" || echo "HASH MISMATCH: $expected != $got"
```

Expected: `HASH OK`.

- [ ] **Step 5: Assert total_files matches git ls-files**

Run:

```bash
hdr=$(awk -F': ' '/^# total_files/{print $2}' /tmp/scan.sh.tsv)
real=$(git ls-files | wc -l | tr -d ' ')
test "$hdr" = "$real" && echo "COUNT OK ($hdr)" || echo "COUNT MISMATCH: $hdr != $real"
```

Expected: `COUNT OK (...)`. (If the working tree has index-only deletions the two can legitimately differ; on a clean tree they match.)

- [ ] **Step 6: Assert the non-git precondition fails cleanly**

Run:

```bash
ROOT=$(pwd) && ( cd /tmp && rm -rf nogit-scan && mkdir nogit-scan && cd nogit-scan && bash "$ROOT/bin/scan-codebase.sh"; echo "exit=$?" )
```

Expected: stderr `ERROR: not a git repository ...` and `exit=3`. (Capture `$ROOT` before `cd` — a bare `$OLDPWD` gets reassigned by the second `cd`.)

- [ ] **Step 7: Commit**

```bash
git add bin/scan-codebase.sh
git commit -m "feat(map-codebase): POSIX git-driven scanner -> TSV manifest"
```

---

### Task 2: PowerShell scanner `bin/scan-codebase.ps1` (byte-parity)

**Files:**
- Create: `bin/scan-codebase.ps1`
- Verify: diff its output against `bin/scan-codebase.sh` output on this repo

- [ ] **Step 1: Write a failing parity command**

Run (PowerShell; script does not exist yet):

```powershell
pwsh -File bin/scan-codebase.ps1
```

Expected: FAIL — file not found.

- [ ] **Step 2: Create the script**

Create `bin/scan-codebase.ps1` with exactly:

```powershell
# Scan a git repository -> TSV manifest: path, token estimate (bytes/4), content
# hash (git hash-object), top-level module. .gitignore respected via git ls-files.
# Usage: scan-codebase.ps1 [-Scope <sub-path>] [-OutFile <path>]   (default scope: whole repo)
#   With -OutFile, writes the manifest there as UTF-8/no-BOM/LF. Without it, prints to stdout.
# Requires a git repository. No Python/uv. Emits LF line endings.
param([string]$Scope = '.', [string]$OutFile = '')

$ErrorActionPreference = 'Stop'

# Decode git's stdout as UTF-8 so non-ASCII filenames survive (Windows console
# defaults to an OEM codepage and would mangle them, mismatching the .sh output).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ($Scope -match '\.\.') { [Console]::Error.WriteLine("ERROR: scope must not contain '..': $Scope"); exit 2 }
if ($Scope.StartsWith('/')) { [Console]::Error.WriteLine("ERROR: scope must not be absolute: $Scope"); exit 2 }

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine("ERROR: not a git repository -- scanner requires git ls-files"); exit 3 }

$sha = (git rev-parse --short HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $sha) { $sha = 'unknown' }

$prefix = ''
if ($Scope -ne '.') { $prefix = ($Scope.TrimEnd('/')) + '/' }

# Exclude map-codebase's own generated outputs — docs/codebase/ (the 8 docs + this
# manifest) and AGENTS.md (its block is upserted every run; also newly-created/untracked
# on first run). Scanning them would make the map look changed on every regen and break
# the incremental no-op short-circuit.
$paths = (& git -c core.quotePath=false ls-files -- $Scope ':(exclude)docs/codebase/' ':(exclude)AGENTS.md') | Where-Object { $_ -ne '' }

$lines = New-Object System.Collections.Generic.List[string]
foreach ($f in $paths) {
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
    $bytes = (Get-Item -LiteralPath $f).Length
    $tokens = [int64][math]::Floor($bytes / 4)
    $hash = (git hash-object $f)
    $rel = $f
    if ($prefix -and $f.StartsWith($prefix)) { $rel = $f.Substring($prefix.Length) }
    if ($rel.Contains('/')) { $module = $rel.Substring(0, $rel.IndexOf('/')) } else { $module = '(root)' }
    $lines.Add(("{0}`t{1}`t{2}`t{3}" -f $f, $tokens, $hash, $module))
}

$arr = $lines.ToArray()
[System.Array]::Sort($arr, [System.StringComparer]::Ordinal)

$totalFiles = $arr.Count
$totalTokens = [int64]0
foreach ($l in $arr) { $totalTokens += [int64]($l -split "`t")[1] }

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("# scan_version: 1`n")
[void]$sb.Append("# source_sha: $sha`n")
[void]$sb.Append("# scan_scope: $Scope`n")
[void]$sb.Append("# total_files: $totalFiles`n")
[void]$sb.Append("# total_tokens: $totalTokens`n")
[void]$sb.Append("path`ttokens`thash`tmodule`n")
foreach ($l in $arr) { [void]$sb.Append($l + "`n") }
$text = $sb.ToString()

if ($OutFile) {
    if (-not [System.IO.Path]::IsPathRooted($OutFile)) { $OutFile = Join-Path (Get-Location).Path $OutFile }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutFile, $text, $utf8NoBom)
} else {
    [Console]::Out.Write($text)
}
```

- [ ] **Step 3: Generate the PowerShell manifest via -OutFile (no redirect)**

Run (PowerShell). Use `-OutFile` — NOT `>` or `Set-Content` (both re-encode on WinPS 5.1):

```powershell
pwsh -File bin/scan-codebase.ps1 -OutFile _scan.ps.tsv
Get-Content _scan.ps.tsv -TotalCount 8
```

If `pwsh` (PowerShell 7) is absent, Windows PowerShell 5.1 works and is the compatibility target — invoke it directly:
`/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -ExecutionPolicy Bypass -File bin/scan-codebase.ps1 -OutFile _scan.ps.tsv`

Expected: same 5 `#` lines + header as the `.sh` output, written to the repo-relative `_scan.ps.tsv`.

- [ ] **Step 4: Diff against the POSIX output (the parity gate)**

Run (Bash tool) — both scripts write repo-relative temp files via their out-arg, so the paths resolve identically for both tools:

```bash
bash bin/scan-codebase.sh . _scan.sh.tsv
diff _scan.sh.tsv _scan.ps.tsv && echo "PARITY OK" || echo "PARITY DIFF ^^"
xxd _scan.ps.tsv | head -1   # sanity: first bytes are '# sca...', i.e. NO BOM (no 'efbbbf') and NO UTF-16 (no '2300' nulls)
rm -f _scan.sh.tsv _scan.ps.tsv
```

Expected: `PARITY OK` (empty diff) and the `xxd` first line begins `23 20 73 63 61 6e` (`# scan`). If diffs appear, usual causes: BOM/UTF-16 (must use `-OutFile`, not redirect), sort collation (must be `Ordinal`), or token rounding (both must floor). Fix the `.ps1` until the diff is empty. Known accepted limitation: non-ASCII filenames may sort differently (UTF-8 bytes vs UTF-16 code units) — out of scope for 2A.

- [ ] **Step 5: Commit**

```bash
git add bin/scan-codebase.ps1
git commit -m "feat(map-codebase): PowerShell scanner with byte-parity to .sh"
```

---

### Task 3: Wire scanner into map-codebase Step 1 (recon + manifest persist)

**Files:**
- Modify: `skills/map-codebase/SKILL.md` (Step 1 — "Quick recon", lines ~53-66)

- [ ] **Step 1: Replace the Step 1 recon body**

In `skills/map-codebase/SKILL.md`, replace the entire `### Step 1 — Quick recon` section (from its heading down to "Do not read deeply here — that's the agents' job.") with:

````markdown
### Step 1 — Quick recon (you, on the main thread)

Do a lightweight pass so the agents share a baseline. Keep it cheap:
- Top-level layout: `Glob` the root and one level down.
- Stack signals: locate manifest/lockfiles (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.) and the primary language.
- Entry points and test directories.

**Run the scanner (git repos only).** First ensure `docs/codebase/` exists, then run the platform-appropriate scanner with the manifest path as its **out-file argument** (do not use shell redirection — it re-encodes on Windows). It respects `.gitignore`, captures `source_sha`, and gives a token budget:
- POSIX: `bash "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.sh" "<scope>" docs/codebase/.manifest.tsv`
- PowerShell: `pwsh -File "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.ps1" -Scope "<scope>" -OutFile docs/codebase/.manifest.tsv`

where `<scope>` is `.` (whole repo) or the sub-path argument. Read the `#`-comment header lines for `source_sha`, `total_files`, and `total_tokens`.

- **Use `source_sha`** from the header for every document's frontmatter (no separate `git rev-parse` needed).
- **Size guardrail (from the manifest).** If `total_tokens` is large (roughly > 400,000, i.e. the full map would overflow a focus agent) **warn the user** and recommend scoping with a sub-path (`/spec-kit:map-codebase <path>`) or mapping feature-by-feature with `/spec-kit:map-feature`. Proceed only after the user confirms. (Automatic token-budgeted scaling is a future Phase 2B.)

**If this is NOT a git repository,** skip the scanner and the manifest entirely: fall back to a `Glob`-based file count for the size guardrail, capture no `source_sha` (leave it `unknown`), and proceed with the full 4-focus map below. Incremental re-map (Step 0) is unavailable without git.

Do not read deeply here — that's the agents' job.
````

- [ ] **Step 2: Verify the section reads correctly and references real script paths**

Run:

```bash
grep -n "scan-codebase" skills/map-codebase/SKILL.md
```

Expected: at least two hits referencing `bin/scan-codebase.sh` and `bin/scan-codebase.ps1` inside Step 1.

- [ ] **Step 3: Dogfood the documented command on this repo**

Run:

```bash
mkdir -p docs/codebase && bash bin/scan-codebase.sh . docs/codebase/.manifest.tsv && head -6 docs/codebase/.manifest.tsv && rm docs/codebase/.manifest.tsv
```

Expected: the manifest header prints (via the out-file arg, not redirection); `total_tokens` is well under 400,000 (this repo is small) — i.e. no false size warning would fire. (The `rm` keeps the working tree clean; a real run persists it.)

- [ ] **Step 4: Commit**

```bash
git add skills/map-codebase/SKILL.md
git commit -m "feat(map-codebase): scanner-driven recon, manifest persist, token-based size guardrail"
```

---

### Task 4: map-codebase Step 0(b) — exact incremental + no-op skip

**Files:**
- Modify: `skills/map-codebase/SKILL.md` (Step 0 — "Scope and existing-map check", lines ~43-51)

- [ ] **Step 1: Replace the Step 0 existing-map branch**

In `skills/map-codebase/SKILL.md`, replace option **(b)** and its surrounding choice block (the `**If it does, do NOT overwrite silently.**` paragraph through the "Wait for the answer before proceeding." line) with:

````markdown
2. Check whether `docs/codebase/` already exists. **If it does, do NOT overwrite silently.** Report when it was generated (read the `analysis_date`/`source_sha` frontmatter in `README.md`).

   **Incremental detection (git repos with a saved manifest).** If `docs/codebase/.manifest.tsv` exists and this is a git repo, run the scanner again to a temporary manifest **outside the repo** (via the out-file arg — keep it out of `docs/codebase/` so it can't be committed by accident) and diff by `hash`:
   - POSIX: `bash "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.sh" . /tmp/map-codebase.manifest.new.tsv`
   - PowerShell: `pwsh -File "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.ps1" -OutFile "$env:TEMP\map-codebase.manifest.new.tsv"`

   Compare the data rows (ignore `#` header lines) of the new manifest against `docs/codebase/.manifest.tsv`. The **changed set** = rows whose `hash` differs (content changed), rows present only in the new manifest (added), and paths present only in the old manifest (removed).

   - **Changed set empty → report "Map is current at `<source_sha>`, nothing to do" and STOP.** Do not dispatch any agents. (This is the no-op short-circuit.)
   - **Changed set non-empty →** present the changed files grouped by `module`, plus a **suggested regeneration set** derived from the conservative coverage table below, then ask the user to choose:
     - **(a) Refresh all** — regenerate all 8 files.
     - **(b) Update suggested only** — regenerate just the suggested docs; leave the rest, but rewrite their `source_sha` and overwrite `.manifest.tsv`.
     - **(c) Skip** — leave the existing map untouched.

   If there is no `.manifest.tsv` (map predates this feature) or this is not a git repo, fall back to the previous behaviour: judge changed areas with `git log`/`git diff` if available, otherwise offer (a) Refresh all / (c) Skip.

   **Conservative coverage table (default on any uncertainty = full refresh):**

   | Change signal | Suggested docs |
   |---|---|
   | Lockfile/manifest (`package.json`, `*.lock`, `go.mod`, `pyproject.toml`, `Cargo.toml`) | TECH-STACK, INTEGRATIONS |
   | Test-only files (`*_test.*`, `*.spec.*`, `*.test.*`, `tests/`, `spec/`) | TESTING |
   | Top-level module added/removed | STRUCTURE, ARCHITECTURE, README |
   | CI/config/env (`.github/`, `Dockerfile`, `*.yml` CI, `.env.example`) | CONCERNS, INTEGRATIONS |
   | Changes spanning more than 3 modules, ambiguous, or general source churn | **Full refresh** (CONVENTIONS always resolves here) |

   Wait for the answer before proceeding. Delete the temporary new manifest after comparing. Whenever you regenerate any document, also overwrite `docs/codebase/.manifest.tsv` with the fresh scan so the next run diffs against current state. (The scanner already excludes `docs/codebase/` itself, so the generated docs never appear as changes.)
````

- [ ] **Step 2: Verify the table and no-op logic are present**

Run:

```bash
grep -n "no-op\|Map is current\|Conservative coverage\|Update suggested only" skills/map-codebase/SKILL.md
```

Expected: hits for the no-op stop line, the coverage table heading, and option (b).

- [ ] **Step 3: Trace the no-op path the DEPLOYED way (tracked manifest)**

This must mirror real use: the manifest lives at `docs/codebase/.manifest.tsv` and is git-tracked, so it appears in `git ls-files`. Testing with manifests outside the repo would hide the bug where the manifest scans *itself* and the no-op never fires — the `:(exclude)docs/codebase/` in the scanner is what prevents that. Stage (don't commit) the manifest so `git ls-files` sees it without mutating history:

```bash
mkdir -p docs/codebase
bash bin/scan-codebase.sh . docs/codebase/.manifest.tsv
git add docs/codebase/.manifest.tsv                      # staged → git ls-files now lists it
bash bin/scan-codebase.sh . /tmp/m2.tsv
# The scan must NOT contain docs/codebase rows, so an unchanged tree → empty changed set:
grep -c 'docs/codebase' /tmp/m2.tsv                      # expect 0
diff <(grep -v '^#' docs/codebase/.manifest.tsv) <(grep -v '^#' /tmp/m2.tsv) && echo "NO-OP FIRES (empty changed set)"
# A real source change is still detected:
printf '\n# scan-test marker\n' >> SPECKIT_VERSION
bash bin/scan-codebase.sh . /tmp/m3.tsv
diff <(grep -v '^#' docs/codebase/.manifest.tsv) <(grep -v '^#' /tmp/m3.tsv) | grep -q 'SPECKIT_VERSION' && echo "CHANGE DETECTED on SPECKIT_VERSION"
git checkout -- SPECKIT_VERSION
git rm --cached docs/codebase/.manifest.tsv >/dev/null; rm -rf docs/codebase /tmp/m2.tsv /tmp/m3.tsv   # clean (no commit, no reset)
```

Expected: `0`, then `NO-OP FIRES (empty changed set)`, then `CHANGE DETECTED on SPECKIT_VERSION`, working tree clean. Do NOT use `git commit`+`git reset --hard` to make the manifest tracked — a background `reset --hard` can wipe uncommitted work; staging via `git add` is enough and safe.

- [ ] **Step 4: Commit**

```bash
git add skills/map-codebase/SKILL.md
git commit -m "feat(map-codebase): exact manifest-diff incremental with no-op skip + coverage table"
```

---

### Task 5: Register new files in CLAUDE.md + skill Notes

**Files:**
- Modify: `CLAUDE.md` (Plugin Layout block)
- Modify: `skills/map-codebase/SKILL.md` (Notes section)

- [ ] **Step 1: Add the scanner + manifest to the CLAUDE.md Plugin Layout**

In `CLAUDE.md`, in the ```` ``` ````-fenced Plugin Layout tree, replace the line:

```
bin/init-project.{sh,ps1}     Idempotent bootstrap helpers (POSIX + Windows)
```

with:

```
bin/init-project.{sh,ps1}     Idempotent bootstrap helpers (POSIX + Windows)
bin/scan-codebase.{sh,ps1}    Git-driven repo scanner -> TSV manifest (token est + content hash); powers map-codebase recon + incremental
```

- [ ] **Step 2: Note the manifest artifact under the map-codebase skill Notes**

In `skills/map-codebase/SKILL.md`, in the `## Notes` list, append:

```markdown
- The scanner (`${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.{sh,ps1}`) is git-only and dependency-free (no Python). It writes `docs/codebase/.manifest.tsv` (git-tracked) — the record of what state the map was built from, used for incremental re-maps. Non-git repos skip it and get the full 4-focus map without incremental.
```

- [ ] **Step 3: Verify both edits and run the CLAUDE.md sanity greps**

Run:

```bash
grep -n "scan-codebase" CLAUDE.md skills/map-codebase/SKILL.md
grep -rn "/speckit-" skills/ ; echo "speckit-refs exit=$?"
grep -H "^name:" skills/*/SKILL.md | grep -v "name: $(echo)" | head
```

Expected: `scan-codebase` appears in both files; `grep -rn "/speckit-"` prints nothing (exit=1, i.e. 0 hits); every `name:` matches its folder.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md skills/map-codebase/SKILL.md
git commit -m "docs(map-codebase): register scan-codebase scripts + .manifest.tsv artifact"
```

---

## Verification (whole feature)

Run after all tasks (mirrors spec §7):

- [ ] **Scanner correctness** — `bash bin/scan-codebase.sh | head` shows a valid header; a sampled `hash` equals `git hash-object <that file>` (Task 1 Steps 4–5).
- [ ] **Cross-platform parity** — `diff` of `.sh` vs `.ps1` output is empty (Task 2 Step 4).
- [ ] **Incremental** — identical rescans yield an empty changed set (no-op); a one-file edit yields exactly that file in the changed set (Task 4 Step 3).
- [ ] **Non-git degrade** — scanner exits 3 outside a git repo (Task 1 Step 6); the skill documents the Phase 1 fallback (Task 3 Step 1).
- [ ] **Sanity greps** — `grep -rn "/speckit-" skills/` → 0 hits; `grep -H "^name:" skills/*/SKILL.md` → each matches its folder (Task 5 Step 3).
- [ ] **Smoke** — `claude --plugin-dir C:/dev/spec-kit-system`, confirm `/spec-kit:map-codebase` is still visible and its description unchanged.

**Out of scope (do not implement here):** Phase 2B dynamic agent scaling; the Python/tiktoken scanner; a non-git filesystem-walk fallback; any `map-feature` change. See spec §6/§9.
