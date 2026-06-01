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
2. Check whether `docs/codebase/` already exists. **If it does, do NOT overwrite silently.** Report when it was generated (read the `analysis_date` frontmatter in `README.md`) and ask the user to choose:
   - **(a) Refresh all** — regenerate all 8 files.
   - **(b) Update changed only** — regenerate only the documents whose underlying areas changed since the last map (use `git log`/`git diff` to judge; fall back to (a) if you can't tell).
   - **(c) Skip** — leave the existing map untouched.

   Wait for the answer before proceeding.

### Step 1 — Quick recon (you, on the main thread)

Do a lightweight pass so the agents share a baseline. Keep it cheap:
- Top-level layout: `Glob` the root and one level down.
- Stack signals: locate manifest/lockfiles (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.) and the primary language.
- Entry points and test directories.
- **Capture the commit** for frontmatter `source_sha`: run `git rev-parse --short HEAD`.
- **Size guardrail.** Count tracked files: `git ls-files | wc -l` (fallback: `Glob` count). If the
  repo is large (roughly > 1500 files or you expect the full map to overflow a focus agent),
  **warn the user** and recommend either scoping with a sub-path argument
  (`/spec-kit:map-codebase <path>`) or mapping feature-by-feature with `/spec-kit:map-feature`.
  Proceed only after the user confirms. (Automatic token-budgeted scaling is a future Phase 2.)

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
