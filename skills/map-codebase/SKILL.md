---
name: map-codebase
description: Scan the current codebase and generate a set of onboarding/navigation documents (ARCHITECTURE.md, TECH-STACK.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, INTEGRATIONS.md, CONCERNS.md + a README index) under docs/codebase/. Use when the user wants to map, explore, or understand a codebase, onboard onto an unfamiliar project, document the current architecture/tech stack, or produce codebase onboarding docs.
argument-hint: "(optional) sub-path to scope the scan; defaults to the whole repository"
user-invocable: true
disable-model-invocation: false
tools: Read, Glob, Grep, Bash, Write, Edit, Agent
---

# /spec-kit:map-codebase

You produce a **codebase map** — a set of human-readable, AI-navigable Markdown documents that explain the current project so a new developer (or a future agent) can get oriented fast.

The documents are **dual-purpose**: a human reads them to onboard, and an agent loads them as navigation context. Keep them prescriptive but tight — every claim cites a real path in backticks; no padding.

## Output contract

Write into **`docs/codebase/`** at the repository root (git-tracked, human-discoverable):

| File | Source template |
|------|-----------------|
| `README.md` | `${CLAUDE_PLUGIN_ROOT}/templates/codebase/readme.md` |
| `ARCHITECTURE.md` | `architecture.md` |
| `TECH-STACK.md` | `tech-stack.md` |
| `STRUCTURE.md` | `structure.md` |
| `CONVENTIONS.md` | `conventions.md` |
| `TESTING.md` | `testing.md` |
| `INTEGRATIONS.md` | `integrations.md` |
| `CONCERNS.md` | `concerns.md` |

Templates live at `${CLAUDE_PLUGIN_ROOT}/templates/codebase/` (plugin-owned, not part of the spec-kit upstream payload). Each template contains a fenced **File Template** block — that block is the structure to fill in and write to the output file.

## Hard rules (apply to every agent and to you)

- **Never read secrets.** Do not open `.env*`, credential files, private keys, or anything that looks like a secret. Note only the *existence* and the *env var names*, never values.
- **Cite real paths.** Every finding references an actual file/dir in backticks, e.g. `` `src/services/user.ts` ``. If you can't point to it, don't claim it.
- **Evidence over guesswork.** Report what the code shows. Mark anything inferred as "suspected". Do not invent bugs, metrics, or patterns.
- **Length cap.** Target 80–250 lines per document. Prescriptive, not padded. `README.md` stays short (a table of contents, not a duplicate).
- **Date.** Use today's date for every `analysis_date` frontmatter field.

## Execution

### Step 0 — Scope and existing-map check

1. Determine scope: default to the whole repository. If the user passed an argument, treat it as a sub-path to focus on (reject paths containing `..`, leading `/`, or shell metacharacters).
2. Check whether `docs/codebase/` already exists. **If it does, do NOT overwrite silently.** Report when it was generated (read the `analysis_date`/`source_sha` frontmatter in `README.md`).

   **Incremental detection (git repos with a saved manifest).** If `docs/codebase/.manifest.tsv` exists and this is a git repo, run the scanner again to a temporary manifest (via the out-file arg) and diff by `hash`:
   - POSIX: `bash "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.sh" . docs/codebase/.manifest.new.tsv`
   - PowerShell: `pwsh -File "${CLAUDE_PLUGIN_ROOT}/bin/scan-codebase.ps1" -OutFile docs/codebase/.manifest.new.tsv`

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

   Wait for the answer before proceeding. Delete the temporary `docs/codebase/.manifest.new.tsv` after comparing. Whenever you regenerate any document, also overwrite `docs/codebase/.manifest.tsv` with the fresh scan so the next run diffs against current state.

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

### Step 2 — Dispatch four focus agents in parallel

Spawn **four `Agent` calls in a single message** so they run concurrently. Give each the prompt below, substituting its focus row:

| Focus | Reads template(s) | Writes |
|-------|-------------------|--------|
| `tech` | `tech-stack.md`, `integrations.md` | `TECH-STACK.md`, `INTEGRATIONS.md` |
| `arch` | `architecture.md`, `structure.md` | `ARCHITECTURE.md`, `STRUCTURE.md` |
| `quality` | `conventions.md`, `testing.md` | `CONVENTIONS.md`, `TESTING.md` |
| `concerns` | `concerns.md` | `CONCERNS.md` |

**Agent prompt template** (fill in `<FOCUS>`, `<TEMPLATES>`, `<OUTPUTS>`, `<SCOPE>`, `<DATE>`, `<SHA>`):

> Read `${CLAUDE_PLUGIN_ROOT}/templates/codebase/agent-prompt.md` and follow its spawn-prompt
> skeleton. Fill the slots for the **<FOCUS>** focus: `<DOC_ID>` per the table below,
> `<SKILL>` = `/spec-kit:map-codebase`, `<OUTPUTS>` = `docs/codebase/<OUTPUTS>`,
> `<TEMPLATES>` = the focus templates under `${CLAUDE_PLUGIN_ROOT}/templates/codebase/`,
> `<SCOPE>` = <SCOPE>, `<DATE>` = <DATE>, `<SHA>` = <SHA>.
>
> Every output file MUST carry the frontmatter v2 block (schema_version, doc, analysis_date,
> generated_by, source_sha, sections) using the frozen canonical headings. README additionally
> carries Tier-3 fields (modules, entry_points, docs); STRUCTURE carries key_files. Obey the hard rules and the
> "frontmatter is an index of the body" discipline from the shared prompt. Return a brief
> confirmation listing the files written and their line counts.

If an agent returns `null` (user skipped it), note the gap and continue.

### Step 3 — Synthesise the README index (you)

After the agents finish, read the seven generated documents and write `docs/codebase/README.md` from `readme.md`: a one-paragraph "what this is", the documents table, and a short "Start here" orientation. Keep it tight — it's the front door, not a summary of everything.

### Step 4 — Point AGENTS.md at the map (you)

So agents discover the map, upsert a single section in `AGENTS.md` at the repo root. Use these exact markers so re-runs replace cleanly and `agent-md-improver` owns everything else:

```markdown
<!-- BEGIN spec-kit:codebase-map -->
## Codebase Map

Generated by `/spec-kit:map-codebase`. Detailed docs in `docs/codebase/`:

- [Architecture](docs/codebase/ARCHITECTURE.md) · [Tech Stack](docs/codebase/TECH-STACK.md) · [Structure](docs/codebase/STRUCTURE.md)
- [Conventions](docs/codebase/CONVENTIONS.md) · [Testing](docs/codebase/TESTING.md) · [Integrations](docs/codebase/INTEGRATIONS.md) · [Concerns](docs/codebase/CONCERNS.md)

Per-feature blast-radius context may also exist at `specs/<feature>/codebase-context.md` (generated by `/spec-kit:map-feature`).
<!-- END spec-kit:codebase-map -->
```

- If `AGENTS.md` exists and already contains the markers, replace only the block between them.
- If it exists without the markers, append the block (do not touch other content).
- If it does not exist, create a minimal `AGENTS.md` containing just this block.

### Step 5 — Report (no commit)

Do **not** run git. List the files written with line counts, note any skipped/empty sections, and tell the user they can run `/spec-kit:git-commit` to save the map. Suggest `/spec-kit:agent-md-improver` if they want to enrich the rest of `AGENTS.md`.

## Notes

- This skill is plugin-only (not part of the spec-kit upstream) and does **not** require `.specify/` — it runs in any repository.
- Templates are intentionally outside `assets/specify/` so an upstream sync never clobbers them.
