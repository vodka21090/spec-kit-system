# Design: Phase 2A — Scanner primitive + Incremental re-map

**Date:** 2026-06-01
**Status:** Approved (ready for planning).
**Author:** brainstorming session (Phuong Nguyen + Claude)
**Supersedes:** the "Phase 2 — Deferred" section of
`docs/superpowers/specs/2026-05-31-map-codebase-map-feature-upgrade-design.md`
(that section is now decomposed; see §6 for the carried-forward, refined Phase 2B deferral).
**Inspiration:** [`kingbootoshi/cartographer`](https://github.com/kingbootoshi/cartographer)
(packed at `cartographer-repomix.md`) — adapted, not ported.

---

## 1. Goal

Deliver the lower-risk half of the deferred Phase 2 work for `/spec-kit:map-codebase`:

1. **A dependency-free, cross-platform scanner primitive** (`bin/scan-codebase.{sh,ps1}`)
   that produces one structured manifest of the repo (file list + token estimate + content
   hash + module), with **no `uv`/Python runtime** — `git` is the engine.
2. **Incremental re-map**: make the existing "update changed only" path exact (manifest diff)
   and add a **no-op short-circuit** so re-running the map when nothing changed costs zero
   agent dispatches.

This was chosen over the higher-risk large-repo *scaling* work (Phase 2B, §6) because both
deliverables are de-risked (git-driven feasibility proven below), independent of 2B, and
directly address the user's "re-map is expensive" pain. The scanner is also the **shared
foundation** 2B will consume later — one scan, multiple consumers.

## 2. Decomposition context

The original Phase 2 (three items: scanner, dynamic agents, incremental) decomposes into a
shared foundation plus two independent branches:

```
        ┌─ Foundation: scanner primitive (this spec) ─┐   proven feasible (git-driven)
        │   bin/scan-codebase.{sh,ps1}                │
        │   one scan → file list + token + hash       │
        └──────────────┬───────────────┬─────────────┘
                       │               │
         2A: Incremental (THIS SPEC)   2B: Large-repo scaling (DEFERRED, §6)
         consumes hashes               consumes token budget + module grouping
         → "re-map is expensive" pain  → "huge repo in one shot" pain
         low risk, independent         high risk, unsolved synthesis-overflow problem
```

**Risk asymmetry (load-bearing).** The feasibility test (§3) de-risks the scanner and the
incremental branch. It does **not** de-risk 2B: 2B's hard problem (two-phase reading →
synthesis without re-overflowing context) lives downstream of the scanner and is untouched
by this work. 2B gets its own brainstorming session — see §6.

## 3. Feasibility evidence (git-driven, no Python)

Validated on this repo (122 tracked files):

| Primitive | Command | Serves |
|---|---|---|
| File list (respects `.gitignore`) | `git ls-files` | foundation |
| Content hash per file (free) | `git hash-object --stdin-paths` | 2A change detection |
| Byte count → token estimate | `wc -c` (POSIX) / `.Length` (PS) | 2B token budget |
| Module grouping | `awk -F/ '{print $1}'` / `Group-Object` | 2B agent assignment |

All rely only on `git` (already a hard dependency) plus standard shell tooling. The
"no Python runtime" constraint (CLAUDE.md) is satisfied. One scan produces all three signals,
which is why the scanner is a shared foundation rather than a feature.

## 4. Component 1 — Scanner primitive `bin/scan-codebase.{sh,ps1}`

A cross-platform script pair, matching the existing `bin/init-project.{sh,ps1}` precedent.
Scans and prints the manifest to **stdout** by default. It also accepts an **optional
output-path argument**; when given, the script writes the manifest itself as **UTF-8, no BOM,
LF line endings**. This output arg exists specifically to dodge a real persistence hazard: on
Windows PowerShell 5.1 a `>` redirect emits UTF-16 and `Set-Content -Encoding utf8` adds a BOM
— either would corrupt the manifest and break cross-platform diffs. Letting the script own the
write keeps the persisted bytes identical to the POSIX output; the caller still decides the path.

### 4.1 Input & precondition

- Optional sub-path argument to scope the scan; default = repository root.
- **Reject** arguments containing `..`, a leading `/`, or shell metacharacters — the same
  validation rule `/spec-kit:map-codebase` already applies.
- **Precondition: a git repository.** The scanner needs `git ls-files` for the
  gitignore-correct file list. If the target is not a git repo (`git ls-files` fails), the
  scanner exits non-zero with a clear message; it does **not** reimplement `.gitignore`.
  `/spec-kit:map-codebase` then degrades to its existing Phase 1 behaviour (Glob-based recon,
  full 4-focus map, no manifest, no incremental) so the skill's "runs in any repository"
  promise holds. Non-git repos simply do not get the scanner/incremental features.
  (A non-git filesystem-walk fallback was considered and rejected: it would mean a second
  cross-platform walk + binary-detection surface in both `sh` and `ps1` for a rare case the
  Phase 1 path already covers.)

### 4.2 Output — manifest (TSV)

Lines sorted by `path` (stable, clean to diff). Leading `#` comment lines carry scan metadata:

```
# scan_version: 1
# source_sha: <git rev-parse --short HEAD>
# scan_scope: .
# total_files: 122
# total_tokens: 48213
path	tokens	hash	module
.agents/skills/caveman/SKILL.md	479	85770a3...	.agents
bin/init-project.sh	312	ed55bda...	bin
...
```

Field definitions:
- `tokens` = `floor(bytes / 4)`. **Deviation from the original spec's `chars/4`:** we use
  **bytes/4**, which over-estimates for multi-byte UTF-8. This is intentionally safe for
  budgeting — under-filling an agent's context beats overflowing it. Documented so 2B does
  not mistake it for an exact count.
- `hash` = `git hash-object` of file contents (history-independent, identical cross-platform).
- `module` = first path segment under the scan scope.

### 4.3 Cross-platform parity (named risk)

`scan-codebase.sh` and `scan-codebase.ps1` MUST emit byte-identical manifests for the same
repo state. Parity hazards to control in the plan:
- **Sort collation** — `LC_ALL=C sort` (bash) vs `Sort-Object` with ordinal comparison (PS).
- **Token formula** — identical integer `floor(bytes/4)` on both.
- **Hash** — `git hash-object` is identical on both by construction.
- **Line endings** — emit `\n`; do not let PowerShell inject `\r\n`.

Verification (§7) diffs the two outputs on this repo.

## 5. Component 2 — Incremental re-map (2A)

Upgrades the existing `/spec-kit:map-codebase` Step 0(b) ("update changed only"), which today
judges heuristically with `git log`/`git diff` and falls back to full refresh. 2A makes
detection **exact** and adds a **no-op short-circuit**.

### 5.1 Manifest persistence

The skill persists the scanner output at **`docs/codebase/.manifest.tsv`**, **git-tracked**
(travels with the repo so collaborators who pull the map can also run incremental). It records
the exact repo state the current map was built from.

**The scanner excludes `docs/codebase/` from its own scan** (`git ls-files … ':(exclude)docs/codebase/'`).
This is load-bearing for the no-op short-circuit: that directory holds the map's *generated
outputs* (the 8 docs **and** the tracked manifest). If the scan included them, every regenerated
map would show its own outputs as "changed" — the manifest can never contain its own correct
hash — so the changed set would never be empty and the no-op could never fire. The comparison
scan on re-run is written to a temp path **outside** the repo so it cannot be committed by
accident; only the post-regeneration manifest lands in `docs/codebase/`.

### 5.2 Re-run flow

1. Run `bin/scan-codebase` → new manifest in memory.
2. Diff new manifest against persisted `.manifest.tsv` by `hash` → **changed file set**
   (added / removed / content-changed).
   - If no persisted manifest exists (map predates this feature), fall back to
     `git diff --name-only <source_sha> HEAD` for detection, and write a fresh manifest.
3. **Changed set empty → report "map is current at `<sha>`, nothing to do" and stop.**
   Zero agent dispatches. This is the primary win for the "ran it again, nothing changed" case.
4. **Changed set non-empty → present the changed files grouped by module, plus a suggested
   regen set** derived from the conservative coverage table (§5.3). The user confirms the
   scope before any dispatch.
5. Regenerate only the confirmed docs; rewrite their `source_sha` frontmatter to the new HEAD
   and overwrite `.manifest.tsv`.

### 5.3 Conservative coverage table (signal → docs)

The 8 docs are organised **by focus, not by module**, so a change anywhere can touch several
focuses. Doc-level coverage is therefore inherently approximate; **the default on any
uncertainty is full refresh.**

| Change signal | Docs to regenerate |
|---|---|
| Lockfile/manifest (`package.json`, `*.lock`, `go.mod`, `pyproject.toml`, `Cargo.toml`...) | TECH-STACK, INTEGRATIONS |
| Test-only files (`*_test.*`, `*.spec.*`, `*.test.*`, `tests/`, `spec/`) | TESTING |
| Top-level module added/removed | STRUCTURE, ARCHITECTURE, README |
| CI/config/env (`.github/`, `Dockerfile`, `*.yml` CI, `.env.example`) | CONCERNS, INTEGRATIONS |
| Broad change (> K modules touched), ambiguous, or general source churn | **Full refresh** (CONVENTIONS always resolves here) |

`K` threshold default: **3 modules** (tune during implementation; over the threshold → offer
full refresh). The mapping only ever *narrows* the regen set as a suggestion the user
confirms; it must never make regeneration *less* conservative than today's behaviour.

### 5.4 Design honesty

Because docs are focus-organised, 2A's real value is **(1) no-op skip** + **(2) a scoped,
confirmable diff with conservative full-refresh fallback** — not magic per-doc incremental.
The manifest makes *detection* exact; the doc mapping stays heuristic and conservative.

## 6. Phase 2B — Large-repo scaling (DEFERRED — resume here)

**Pain:** "map a huge repo in one shot" overflows a fixed-4-focus agent's context.
**Consumes:** the scanner's `total_tokens` + per-module token sums + `module` grouping.

**Items (from the original Phase 2):**
- **Dynamic agent assignment** — group files by module, balance token budgets, spawn N reading
  agents scaled to repo size instead of the fixed 4.
- Two-phase model: **token-budgeted reading agents → focus synthesis agents**.

**UNSOLVED feasibility problem (must be the focus of 2B brainstorming).** The scanner does
**not** de-risk 2B. If the repo is too large for one agent's context — the entire reason to
scale the *reading* phase — then how do the (≈4) **synthesis** agents consume N reading
agents' fact-dumps **without re-overflowing the same context** the split was meant to avoid?
There is currently:
- no defined intermediate "raw facts" representation (format, size budget, where stored),
- no partitioning of those facts per synthesis focus,
- no answer to synthesis-side overflow.

Until that is designed, "scanner works → scaling is solved" is a halo the evidence does not
support.

**Other constraints carried forward:**
- Mode switch, not replacement: keep the fixed-4-focus path for small/medium repos (the common
  case); 2B activates only above the size guardrail threshold.
- **Cannot be dogfooded on this repo (122 files).** 2B verification needs a real large repo.
- `Tokens` column returns to ARCHITECTURE.md's Module Guide (Phase 1 shipped `Lines`).

**OPEN DECISION carried into 2B — accurate tokens vs the no-Python constraint.** During 2A
brainstorming we considered porting Cartographer's Python/tiktoken scanner for accurate,
Claude-comparable token counts. It was **deliberately deferred to 2B**, because accurate token
counts benefit *only* token-budgeted agent assignment (2B); 2A's needs (gitignore-correct
listing + per-file hash + a coarse size threshold) are fully met by git + bytes/4. Committing
the whole plugin to a Python runtime now — reversing CLAUDE.md's defining "no uv/Python at
runtime" promise — to feed a deferred feature is the same "build it because Cartographer has
it" trap the Phase 2 gating exists to prevent. So when 2B is brainstormed, an early question is:
does token-budgeted assignment genuinely need tiktoken-accurate counts, or is bytes/4 (which
over-estimates → safe under-fill) good enough? Note tiktoken is OpenAI's tokenizer, not
Claude's — "more accurate than bytes/4" but still approximate. If 2B does need it, prefer
scoping the Python dependency to the scanner feature only (core SDD workflow stays no-Python)
over dropping the promise wholesale.

**To resume:** new session → "continue Phase 2B brainstorming from the 2026-06-01 spec."
Read this §6, then run the brainstorming flow focused first on the synthesis-overflow problem
(the intermediate raw-facts representation) before any agent-assignment design; resolve the
accurate-tokens/Python question there.

## 7. Verification

- **Scanner correctness** — run `bin/scan-codebase` on this repo; spot-check that `hash`
  matches `git hash-object` for sampled files and `total_files` matches `git ls-files | wc -l`.
- **Cross-platform parity** — diff `scan-codebase.sh` vs `scan-codebase.ps1` output on this
  repo; expect identical bytes.
- **Scaling behaviour** — out of scope here; the scanner's behaviour on a *large* repo is 2B's
  concern and needs a real large repo (this 122-file repo cannot exercise it).
- **Incremental** — generate a map; re-run with no changes → expect the no-op "map is current"
  report and zero agent dispatches; then edit one file → re-run → expect a correct changed set
  and a scoped (or conservatively full) regen suggestion.
- **Sanity greps (CLAUDE.md)** — `grep -rn "/speckit-" skills/` → 0 hits;
  `grep -H "^name:" skills/*/SKILL.md` → each matches its folder.

## 8. Build sequence

1. `bin/scan-codebase.sh` (POSIX) + `bin/scan-codebase.ps1` (Windows), parity-checked.
2. `/spec-kit:map-codebase` Step 1 (recon): call the scanner, use `total_tokens` for the size
   guardrail decision, persist `docs/codebase/.manifest.tsv`.
3. `/spec-kit:map-codebase` Step 0(b): replace the heuristic with manifest-diff detection +
   no-op short-circuit + the conservative coverage table + user-confirmed regen scope.
4. Update the skill's notes and CLAUDE.md plugin layout to mention `bin/scan-codebase.*` and
   the `.manifest.tsv` artifact.

## 9. Out of scope

- Phase 2B (dynamic agents / scaling) — §6.
- `map-feature` changes — it is narrow by construction and does not need the scanner now.
- A separate machine-readable `index.json` — the TSV manifest + frontmatter suffice.
- Porting Cartographer's Python/tiktoken scanner — considered and **deferred to 2B**, where
  accurate tokens would have their only consumer; see §6. 2A stays git-driven / no-Python.
- A non-git filesystem-walk fallback — rejected; non-git targets degrade to Phase 1 (§4.1).
