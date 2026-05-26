# init-agents-md Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a plugin-only Claude Code skill `init-agents-md` that initializes (or audit-improves) a vendor-neutral `AGENTS.md` at the repo root by self-discovering the codebase.

**Architecture:** Single skill with dual-mode dispatch (INIT/IMPROVE) selected by phase-0 detection of an existing `AGENTS.md`. Template + 3 reference files load on demand. Adapts Anthropic's `claude-md-improver` (rubric, diff workflow) and `agent-development` (frontmatter, "When to invoke" body).

**Tech Stack:** Markdown (skill files), YAML frontmatter, Bash sanity greps. No code, no tests beyond manual smoke checks against this repo as the fixture. Aligns with CLAUDE.md rule "Do not add package manager / CI / test framework without explicit spec."

**Spec source-of-truth:** `docs/superpowers/specs/2026-05-25-init-agents-md-design.md` (commit `c18bcf0`).

---

## File Structure

Files this plan creates or modifies:

| Path | Responsibility |
|---|---|
| `skills/init-agents-md/SKILL.md` | Frontmatter + dual-mode workflow body (the prompt itself) |
| `skills/init-agents-md/template.md` | Markdown skeleton with `<!-- FILL/REQUIRED/... -->` directives |
| `skills/init-agents-md/references/rubric.md` | 6-criterion 100-pt scoring rubric |
| `skills/init-agents-md/references/adaptation-matrix.md` | Project-type → sections to include/omit |
| `skills/init-agents-md/references/examples.md` | 3 worked examples (Go CLI, Node monorepo, Python lib) |
| `.claude-plugin/plugin.json` | Add skill entry if manifest lists skills explicitly (check first; may be a no-op) |
| `tmp/fixtures/empty-repo/.gitkeep` | Empty-repo fixture for Task 9 |
| `tmp/fixtures/monorepo/...` | 2-package fixture for Task 10 |

No source code files. No test framework files. Validation is via sanity greps and manual smoke runs against this repo.

---

## Task 1: Scaffold the skill directory

**Files:**
- Create: `skills/init-agents-md/SKILL.md` (stub)
- Create: `skills/init-agents-md/template.md` (stub)
- Create: `skills/init-agents-md/references/rubric.md` (stub)
- Create: `skills/init-agents-md/references/adaptation-matrix.md` (stub)
- Create: `skills/init-agents-md/references/examples.md` (stub)

- [ ] **Step 1: Define the sanity check that proves scaffold is correct**

Sanity grep (will be re-used in Task 7):

```bash
test -f skills/init-agents-md/SKILL.md \
  && test -f skills/init-agents-md/template.md \
  && test -f skills/init-agents-md/references/rubric.md \
  && test -f skills/init-agents-md/references/adaptation-matrix.md \
  && test -f skills/init-agents-md/references/examples.md \
  && echo OK || echo FAIL
```

- [ ] **Step 2: Run the check to verify it fails (no files yet)**

Expected: `FAIL`

- [ ] **Step 3: Create the five empty stub files**

```bash
mkdir -p skills/init-agents-md/references
printf '# init-agents-md (stub)\n' > skills/init-agents-md/SKILL.md
printf '# template (stub)\n' > skills/init-agents-md/template.md
printf '# rubric (stub)\n' > skills/init-agents-md/references/rubric.md
printf '# adaptation-matrix (stub)\n' > skills/init-agents-md/references/adaptation-matrix.md
printf '# examples (stub)\n' > skills/init-agents-md/references/examples.md
```

- [ ] **Step 4: Re-run the sanity check**

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/
git commit -m "feat(init-agents-md): scaffold skill directory"
```

---

## Task 2: Write `template.md`

**Files:**
- Modify: `skills/init-agents-md/template.md`

- [ ] **Step 1: Define the directive-presence sanity check**

```bash
grep -q "<!-- FILL:" skills/init-agents-md/template.md \
  && grep -q "<!-- REQUIRED" skills/init-agents-md/template.md \
  && grep -q "<!-- OPTIONAL" skills/init-agents-md/template.md \
  && grep -q "{{PROJECT_NAME}}" skills/init-agents-md/template.md \
  && echo OK || echo FAIL
```

- [ ] **Step 2: Run check, expect FAIL (template still a stub)**

- [ ] **Step 3: Write the full template content**

Replace the entire contents of `skills/init-agents-md/template.md` with:

````markdown
<!--
This template is consumed by the init-agents-md skill at fill time.
Three placeholder kinds appear here:
  {{NAME}}         — inline scalar; replace with derived value
  <value>          — example token inside a table/list; replace or delete the row
  <!-- DIRECTIVE -->  — instruction to the agent; STRIP from final output

Emit rules (enforced by SKILL.md):
1. Strip every HTML comment from the produced AGENTS.md.
2. SKIP-SECTION-IF predicate true → remove heading + body.
3. Optional section with no concrete content → remove heading + body.
4. Commands table with zero verified rows → keep heading, body becomes `_No verified commands._`.
5. Hard ceiling 10 KB; compression pass if exceeded.
-->

# {{PROJECT_NAME}}

<!-- FILL: One-sentence what this codebase IS, not what it aspires to be. ≤120 chars. -->

## Commands
<!-- REQUIRED. Weight 20. Verify every row against a manifest or CI file before listing. -->
<!-- OMIT-ROWS-IF: command not found in any manifest/script/CI. Tag `# unverified` if listed anyway. -->

| Command | Purpose |
|---|---|
| `<install>` | Install deps |
| `<dev>` | Run locally |
| `<build>` | Production build |
| `<test>` | Run test suite |
| `<lint>` | Lint / format |

## Architecture
<!-- REQUIRED. Weight 20. Top 2 levels of source root only. One-line purpose per dir. -->

```
<root>/
  <dir>/    # <purpose>
```

## Key Files
<!-- OPTIONAL. List only files an agent needs to know exists (entry points, generated-code sources, registration order). Skip if none. -->

- `<path>` — <why this file matters to an agent>

## Code Style
<!-- OPTIONAL. List ONLY project-specific conventions an agent would otherwise violate. No generic advice. Skip if none. -->

- <convention>

## Environment
<!-- OPTIONAL. Include when .env.example or docker-compose.yml exists. -->

- `<VAR>` — <purpose; required vs. optional>

## Testing
<!-- OPTIONAL. Include when test/ or *_test.* files exist. -->

- `<command>` — <scope>
- <Where fixtures/factories live; mocking convention.>

## Gotchas
<!-- OPTIONAL. Weight 15. Capture non-obvious patterns surfaced during Probe phase. SKIP-SECTION-IF: no concrete project-specific gotcha. -->

- <gotcha>

## Workflow
<!-- OPTIONAL. Include only if --workflow flag passed OR repo has Makefile/Justfile with named recipes. -->

- <when to do X vs. Y>
````

- [ ] **Step 4: Re-run the sanity check**

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/template.md
git commit -m "feat(init-agents-md): add AGENTS.md skeleton template"
```

---

## Task 3: Write `references/rubric.md`

**Files:**
- Modify: `skills/init-agents-md/references/rubric.md`

- [ ] **Step 1: Define the sanity check (six criteria, total 100)**

```bash
grep -c "^### " skills/init-agents-md/references/rubric.md  # expect 6
grep -q "Pass threshold: 80" skills/init-agents-md/references/rubric.md && echo OK || echo FAIL
```

- [ ] **Step 2: Run check, expect FAIL**

- [ ] **Step 3: Write the rubric**

Replace `skills/init-agents-md/references/rubric.md` with:

```markdown
# AGENTS.md Quality Rubric

Adapted from Anthropic `claude-md-improver` `references/quality-criteria.md`. Used by both INIT phase 4 (self-evaluate before emit) and IMPROVE phase 3 (score current file).

**Total: 100 points. Pass threshold: 80.**

### 1. Commands / workflows (20 pts)

- **20**: All essential build/test/lint/dev commands present, each verified against a manifest or CI config in this session.
- **15**: Most commands present; some lack verification.
- **10**: Basic commands only; no workflow context.
- **5**: Few commands, many missing.
- **0**: No commands documented.

### 2. Architecture clarity (20 pts)

- **20**: New agent can find where things live in <30s. Top-level dirs explained, entry points identified.
- **15**: Good overview, minor gaps.
- **10**: Bare directory listing.
- **5**: Vague or incomplete.
- **0**: No architecture info.

### 3. Non-obvious patterns / gotchas (15 pts)

- **15**: Captures things that would otherwise burn debug cycles (import-order, codegen, env quirks).
- **10**: Some patterns documented.
- **5**: Minimal.
- **0**: None.

### 4. Conciseness (15 pts)

- **15**: Dense, no filler, no restating-the-obvious.
- **10**: Mostly concise, some padding.
- **5**: Verbose in places.
- **0**: Mostly filler.

### 5. Currency (15 pts)

- **15**: Every command/path verified against actual repo state this session.
- **10**: Mostly current, minor staleness.
- **5**: Several outdated references.
- **0**: Severely outdated.

### 6. Actionability (15 pts)

- **15**: Every command copy-paste-runnable; every path real.
- **10**: Mostly actionable.
- **5**: Some vague instructions.
- **0**: Vague or theoretical.

## Scoring procedure

1. Score each criterion independently.
2. Sum to a total out of 100.
3. If total < 80, identify lowest-scoring criterion and improve it. Re-score. Max 2 iterations.
4. If still < 80 after 2 iterations, emit anyway with a rationale that names the failing criterion and its concrete cause.

## Red flags (auto-deduct)

- Commands that fail trivial sanity (wrong path, missing dep).
- References to deleted files/folders.
- Outdated tech versions.
- Generic advice not specific to the project.
- Copy-paste from `README.md` without paraphrase.
- Duplicate info across multiple sections.
```

- [ ] **Step 4: Re-run sanity check, expect OK**

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/references/rubric.md
git commit -m "feat(init-agents-md): add scoring rubric"
```

---

## Task 4: Write `references/adaptation-matrix.md`

**Files:**
- Modify: `skills/init-agents-md/references/adaptation-matrix.md`

- [ ] **Step 1: Define the sanity check (one row per project type)**

```bash
grep -q "^| Library" skills/init-agents-md/references/adaptation-matrix.md \
  && grep -q "^| Monorepo" skills/init-agents-md/references/adaptation-matrix.md \
  && grep -q "^| Plugin" skills/init-agents-md/references/adaptation-matrix.md \
  && echo OK || echo FAIL
```

- [ ] **Step 2: Run check, expect FAIL**

- [ ] **Step 3: Write the matrix**

Replace `skills/init-agents-md/references/adaptation-matrix.md` with:

```markdown
# Project-Type Adaptation Matrix

Use this table during INIT phase 3 (Draft) to decide which sections to keep or omit from the template.

| Project type | Detection signal | Sections likely to matter | Sections likely to omit |
|---|---|---|---|
| Library | Manifest declares no entry point binary; has public API exports (Cargo lib, Python `__init__.py` exports, npm `main`/`exports`) | Commands, Key Files (public API surface), Testing | Environment, Workflow |
| CLI tool | Manifest declares single binary; `bin/`, `cmd/`, or `main.go` present | Commands, Architecture, Gotchas | Environment (often), Code Style |
| Web app | `next.config.*`, `vite.config.*`, framework manifest, `.env.example` | Commands, Architecture, Environment, Testing | — |
| Monorepo | `pnpm-workspace.yaml`, `lerna.json`, `turbo.json`, ≥2 manifests under `packages/` or `apps/` | Architecture (package table), Commands (with `--filter`/workspace flags), Gotchas (cross-pkg deps) | Code Style (push to per-package files) |
| Plugin / extension | `.claude-plugin/`, `manifest.json` with extension fields, `package.json` `engines` referencing host | Commands, Key Files (manifest, entry points), Gotchas (host-app quirks) | Environment |
| Design / binary asset repo | Predominantly `.pen`, `.psd`, `.blend`, `.fig` files; no manifest | Architecture (file layout) only | Commands, Testing, Environment |
| Bare/unknown | None of the above signals | Header + one-line description + a single Gotcha noting auto-detection failed | Everything else |

## Application rules

1. Pick the **first** matching row (top to bottom).
2. "Likely to omit" is a soft rule — include if a concrete project-specific fact warrants it.
3. "Likely to matter" sections still require content; never include an empty section.
```

- [ ] **Step 4: Re-run sanity check, expect OK**

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/references/adaptation-matrix.md
git commit -m "feat(init-agents-md): add project-type adaptation matrix"
```

---

## Task 5: Write `references/examples.md`

**Files:**
- Modify: `skills/init-agents-md/references/examples.md`

- [ ] **Step 1: Define the sanity check (three example blocks)**

```bash
grep -c "^## Example" skills/init-agents-md/references/examples.md  # expect 3
```

- [ ] **Step 2: Run check, expect 0**

- [ ] **Step 3: Write the examples**

Replace `skills/init-agents-md/references/examples.md` with:

````markdown
# Worked Examples

Three reference outputs the agent should imitate in tone, density, and section selection. **Imitate the shape, not the literal content.**

## Example 1 — Minimal (Go CLI, ~300 LOC)

```markdown
# tinyfmt

Opinionated Markdown table formatter. Single-binary Go CLI.

## Commands

| Command | Purpose |
|---|---|
| `go build ./...` | Build `tinyfmt` binary |
| `go test ./...` | Run all tests |
| `golangci-lint run` | Lint (CI uses this) |

## Architecture

```
cmd/tinyfmt/   # main package, flag parsing only
internal/
  parse/       # markdown table tokenizer
  align/       # column-width + alignment logic
testdata/      # golden files; tests use `-update` to regenerate
```

## Gotchas

- Golden tests: run `go test ./internal/align -update` after intentional output changes.
- Unicode width uses `go-runewidth`; ASCII-only assumptions break on CJK input.
```

## Example 2 — Comprehensive (Node monorepo)

```markdown
# acme-platform

Customer-facing SaaS. Turborepo with Next.js web, Fastify API, shared TS packages.

## Commands

| Command | Purpose |
|---|---|
| `pnpm install` | Install (pnpm required — npm/yarn break workspaces) |
| `pnpm dev` | All apps in parallel (web :3000, api :4000) |
| `pnpm --filter web dev` | Just the web app |
| `pnpm build` | Turbo-cached production build |
| `pnpm test` | Vitest, parallel across packages |
| `pnpm lint` | ESLint + Prettier |
| `pnpm db:migrate` | Apply Prisma migrations to `$DATABASE_URL` |

## Architecture

```
apps/
  web/         # Next.js 14 app router
  api/         # Fastify + Prisma
packages/
  ui/          # Shared React components (Radix + Tailwind)
  db/          # Prisma schema + generated client
  config/      # Shared eslint/tsconfig/tailwind presets
```

## Key Files

- `apps/api/src/server.ts` — Fastify bootstrap; plugin registration order matters.
- `packages/db/schema.prisma` — Source of truth for DB; regen with `pnpm db:generate`.
- `turbo.json` — Task graph; new scripts need entries here to be cached.

## Environment

- `DATABASE_URL` — Postgres connection (required for `api`, `db:migrate`).
- `NEXTAUTH_SECRET` — Required at build time, not just runtime, for `web`.

## Testing

- Unit: Vitest, colocated `*.test.ts`.
- API integration: `apps/api/test/` — uses real Postgres via `testcontainers`, not mocks.
- E2E: Playwright in `apps/web/e2e/`; run `pnpm --filter web e2e`.

## Gotchas

- `packages/db` must build before `apps/api` (Turbo handles this; manual `tsc -b` in `api/` will not).
- Don't edit generated `packages/db/dist/` — regenerate via `pnpm db:generate`.
- `NEXT_PUBLIC_*` env vars baked at build time; changing them needs a rebuild.
```

## Example 3 — Library (Python)

```markdown
# pyalign

Pure-Python column alignment helper. Importable, no CLI.

## Commands

| Command | Purpose |
|---|---|
| `uv sync` | Install deps and editable install |
| `uv run pytest` | Run tests |
| `uv run ruff check` | Lint |
| `uv run ruff format` | Format |

## Architecture

```
src/pyalign/
  __init__.py    # public API: align(), AlignSpec
  _engine.py     # internal layout engine; not part of public API
tests/           # pytest, one file per public function
```

## Key Files

- `src/pyalign/__init__.py` — Source of truth for the public API; anything not re-exported here is internal.

## Testing

- Use `pytest --hypothesis-seed=0` for reproducible property-based tests.
```
````

- [ ] **Step 4: Re-run sanity check, expect 3**

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/references/examples.md
git commit -m "feat(init-agents-md): add worked examples"
```

---

## Task 6: Write `SKILL.md` (frontmatter + dual-mode body)

**Files:**
- Modify: `skills/init-agents-md/SKILL.md`

- [ ] **Step 1: Define sanity checks**

```bash
# Frontmatter `name:` must match folder name
grep -E "^name: init-agents-md$" skills/init-agents-md/SKILL.md && echo NAME_OK || echo NAME_FAIL

# Must mention both modes
grep -q "INIT MODE" skills/init-agents-md/SKILL.md \
  && grep -q "IMPROVE MODE" skills/init-agents-md/SKILL.md \
  && echo MODES_OK || echo MODES_FAIL

# Must mention When to invoke per Anthropic agent-development convention
grep -q "^## When to invoke" skills/init-agents-md/SKILL.md && echo WTI_OK || echo WTI_FAIL

# Must not leak /speckit- references (CLAUDE.md vendoring rule)
grep -c "/speckit-" skills/init-agents-md/SKILL.md  # expect 0
```

- [ ] **Step 2: Run checks, expect FAIL on NAME / MODES / WTI**

- [ ] **Step 3: Write SKILL.md**

Replace `skills/init-agents-md/SKILL.md` with:

````markdown
---
name: init-agents-md
description: Use this agent when a repository needs an AGENTS.md created or maintained. In INIT mode (no existing AGENTS.md) it discovers the codebase and writes a fresh file; in IMPROVE mode (file exists) it audits, scores, and proposes targeted diffs for user approval. Typical triggers include first-time setup in a fresh clone, post-scaffold cleanup after generators like `create-next-app` or `cargo new`, onboarding an existing repo to vendor-neutral AI tooling, and refreshing a stale AGENTS.md after major refactors. See "When to invoke" in the body for worked scenarios.
model: inherit
color: cyan
tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit"]
version: 0.1.0
---

<!-- plugin-only skill; not vendored from github/spec-kit upstream. Safe to edit directly. -->

# init-agents-md

You are a senior software engineer whose single job is to create or maintain a high-signal `AGENTS.md` at the repository root by exploring the codebase yourself. `AGENTS.md` is the vendor-neutral open analog of `CLAUDE.md` — read on every session by AI coding agents (Codex, Cursor, Aider, Claude Code, Gemini). Every line you write occupies their context window; make each one earn its place.

## When to invoke

- **Fresh clone, no AI context.** Repo has source code, manifests, maybe a `README.md`, but no `AGENTS.md` / `CLAUDE.md` / `.cursorrules`. User asks to set up AGENTS.md, or you proactively suggest it on first interaction.
- **Post-scaffold tidy.** User just ran a scaffolder (Next.js, Cargo, Poetry, Go templates) and wants project memory before real work begins.
- **Migration to vendor-neutral.** Repo has `CLAUDE.md` or `.cursorrules` only; user wants a portable `AGENTS.md`. Reuse content via paraphrase; never blind-copy vendor idioms.
- **Stale-file refresh.** Existing `AGENTS.md` whose commands no longer match `package.json`/CI; user asks to audit or update it.
- **NOT for:** patching a single section (use `Edit` directly), generating per-package `AGENTS.md` without the root file (run root first), or auditing CLAUDE.md (that's `claude-md-improver`).

## Arguments

Parse from the user message. All optional.

| Argument | Meaning | Default |
|---|---|---|
| `--packages` | After root file, also generate per-package AGENTS.md for detected monorepo packages | off |
| `--lang <code>` | Output language for prose body (e.g. `en`, `vi`) | `en` |
| `--depth minimal|standard|comprehensive` | Section inclusion aggressiveness | `standard` |
| `--workflow` | Force-include the optional Workflow section | off |

## Phase 0 — Dispatch

```
Read AGENTS.md at repo root
├── absent     → INIT MODE
└── present    → IMPROVE MODE
```

The first line of your output is `Mode: INIT` or `Mode: IMPROVE` so the user immediately knows which flow ran.

## INIT MODE

### Phase 1 — Discover (stop early once you have project type + ≥3 verified commands)

| Step | Action | Looking for |
|---|---|---|
| 1.1 | List top-level entries (`Glob`) | Project type (monorepo? single app? library?) |
| 1.2 | Read `README.md` if present | Stated purpose, install/run commands |
| 1.3 | Read manifests | `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `pom.xml` / `composer.json` — scripts, deps, entry points |
| 1.4 | Read CI config | `.github/workflows/*`, `.gitlab-ci.yml`, `azure-pipelines.yml` |
| 1.5 | Scan source root | Top 2 levels of `src/`/`lib/`/`app/`/`pkg/` |
| 1.6 | Skim env / infra | `.env.example`, `docker-compose.yml`, `Makefile`, `Justfile`, `Taskfile.yml` |
| 1.7 | Check existing AI context | `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.aider.conf.yml` — paraphrase, do not duplicate |

### Phase 2 — Probe (only if Phase 1 left gaps)

- Grep `TODO|FIXME|HACK|XXX` → surfaces gotchas worth documenting.
- Open 1–2 test files → infer framework + fixtures location.
- Check for codegen (`prisma generate`, `protoc`, `openapi-generator`).
- Check for non-obvious cross-module dependencies (import-order, plugin registration order).

### Phase 3 — Draft

1. Load `template.md`.
2. Pick the matching row in `references/adaptation-matrix.md` and decide which sections to keep.
3. Fill placeholders. Strip every `<!--` HTML comment in the output.
4. Apply emit rules from the template header (skip empty optional sections; `_No verified commands._` if applicable).

### Phase 4 — Self-evaluate

Score the draft against `references/rubric.md`. If total < 80, fix the lowest-scoring criterion, re-score. Max 2 passes.

### Phase 5 — Emit

Write `AGENTS.md` at the repo root with `Write`. Output:

```
Mode: INIT (no existing AGENTS.md detected)

<file written: AGENTS.md>

Rationale: <2–4 sentences: sections included/omitted, biggest risk, verification step that would catch it>
Self-score: <total>/100 (commands <n>/20, architecture <n>/20, gotchas <n>/15, conciseness <n>/15, currency <n>/15, actionability <n>/15)
```

After emitting, run the post-emit sanity checks below. Append any failures to the rationale.

#### Post-emit sanity checks

```bash
# 1. Comment directives stripped?
grep -q "<!-- FILL\|<!-- REQUIRED\|<!-- OPTIONAL\|<!-- SKIP\|<!-- OMIT" AGENTS.md && echo "FAIL: directives leaked"

# 2. Placeholder tokens stripped?
grep -q "{{.*}}\|<install>\|<dev>\|<build>" AGENTS.md && echo "FAIL: placeholder leaked"

# 3. File size sane?
[ $(wc -c < AGENTS.md) -lt 10240 ] || echo "WARN: exceeds 10KB"
```

## IMPROVE MODE

### Phase 1 — Read current

Load the existing `AGENTS.md` into context with `Read`.

### Phase 2 — Reconnaissance

Run the same discovery as INIT phases 1–2, but for cross-checking rather than filling.

### Phase 3 — Score & gap

Score current file against `references/rubric.md`. Cross-reference with reconnaissance: which commands are stale, which dirs are missing, which gotchas are undocumented. Produce a quality report.

### Phase 4 — Propose diff

For each gap, write a unified diff block tagged with a **Why** line. **Do not write to the file yet.** Number each proposal.

### Phase 5 — Apply on approval

Output the report + diffs and ask:

```
Apply all? [yes / apply 1,2 / cancel]
```

Wait for response. Apply approved hunks with `Edit`.

**Output template (IMPROVE):**

```
Mode: IMPROVE (existing AGENTS.md found, score <n>/100)

## Quality Report
| Criterion | Current | Issue |
| ... |

## Proposed Changes

### 1. ./AGENTS.md § <section>
Why: <one-line reason>
```diff
- <removed>
+ <added>
```

Apply all? [yes / apply 1,2 / cancel]
```

## Monorepo branch (`--packages`)

After root file completes (either mode), if `--packages` was passed:

1. Glob `{packages,apps}/*/package.json|pyproject.toml|Cargo.toml|go.mod`.
2. For each detected package, run the same mode against the package root.
3. Use a shorter skeleton: only `Commands`, `Key Files` (used here for public exports / entry points), and `Gotchas` from `template.md`. All other sections omitted unconditionally.
4. Emit a single rollup output listing every file written or proposed.

If a candidate path has no manifest, skip and report `Skipped: <path> (no manifest)` in the rollup.

## Failure modes

| # | Situation | Behavior |
|---|---|---|
| 1 | Repo empty (only `.git/`, no manifest/source) | INIT degrade: emit AGENTS.md with header + Gotcha "Auto-detection found no manifest or source; expand manually." Self-score will be <80 — emit anyway with explanatory rationale. |
| 2 | Repo has only binary/design assets | Case 1 path; Architecture lists file layout instead of source tree. |
| 3 | Manifest references missing entry file | List command with `# unverified — entry file not found`; add Gotcha. Never silent-omit. |
| 4 | Both `AGENTS.md` and `CLAUDE.md` exist | IMPROVE mode on AGENTS.md; read CLAUDE.md only as cross-reference; never touch CLAUDE.md. |
| 5 | `.cursorrules` / `.github/copilot-instructions.md` exists but no AGENTS.md | INIT mode. Read those files in Discover 1.7. Paraphrase agent-relevant content. Leave originals in place. |
| 6 | Monorepo `--packages` with package lacking manifest | Skip; record in rollup. |
| 7 | User cancels IMPROVE phase 5 | No file change. Output: "No changes applied. Re-run skill or edit manually." |
| 8 | Self-eval still <80 after 2 passes | Emit anyway. Rationale names failing criterion + concrete cause. |
| 9 | Git submodules present | Treat root as standalone. List submodule paths in Architecture with `# submodule — see its own AGENTS.md`. Do not recurse. |
| 10 | Projected file >8 KB | Compression pass: rewrite longest section as table/bullet. Hard ceiling 10 KB. |

## Constraints

### MUST DO
- Verify every command exists in a manifest or CI config before listing it.
- Use real paths from the repo, not placeholders.
- One line per concept. Tables for command lists.
- Stay vendor-neutral in the produced `AGENTS.md` (this SKILL.md itself may name vendors; the output may not).
- Prefer commands over prose.
- If `CLAUDE.md` already exists, paraphrase agent-relevant facts — never blind-copy.

### MUST NOT DO
- Restate what file/dir names already tell a reader.
- Include generic best practices.
- Document one-off bug fixes.
- Copy verbatim from `README.md`.
- Invent sections to look thorough.
- Verbose explanations of well-known tech.
- Badges, marketing copy, table-of-contents, contributor lists.
- Touch any file other than `AGENTS.md` at repo root (and per-package `AGENTS.md` if `--packages`).

## Reference files

Load only when its phase triggers, not eagerly:

- `template.md` — phase 3 of INIT, phase 3 of IMPROVE.
- `references/rubric.md` — phase 4 of INIT, phase 3 of IMPROVE.
- `references/adaptation-matrix.md` — phase 3 of INIT.
- `references/examples.md` — phase 3 of INIT, only if depth=comprehensive or to disambiguate format.
````

- [ ] **Step 4: Re-run sanity checks**

Expected: `NAME_OK`, `MODES_OK`, `WTI_OK`, and the `/speckit-` count is `0`.

- [ ] **Step 5: Commit**

```bash
git add skills/init-agents-md/SKILL.md
git commit -m "feat(init-agents-md): add dual-mode SKILL.md"
```

---

## Task 7: Sanity grep suite

**Files:**
- No new files; runs sanity assertions against the skill folder.

- [ ] **Step 1: Define the full sanity suite**

Save as a one-off shell snippet (do not commit it as a script — CLAUDE.md forbids new tooling):

```bash
set -e
echo "== Existence =="
test -f skills/init-agents-md/SKILL.md
test -f skills/init-agents-md/template.md
test -f skills/init-agents-md/references/rubric.md
test -f skills/init-agents-md/references/adaptation-matrix.md
test -f skills/init-agents-md/references/examples.md
echo OK

echo "== Vendoring rule (no /speckit- references) =="
test "$(grep -rn '/speckit-' skills/init-agents-md/ | wc -l)" = "0"
echo OK

echo "== Frontmatter name matches folder =="
grep -E "^name: init-agents-md$" skills/init-agents-md/SKILL.md > /dev/null
echo OK

echo "== Required directives present in template =="
grep -q "<!-- FILL:" skills/init-agents-md/template.md
grep -q "<!-- REQUIRED" skills/init-agents-md/template.md
echo OK

echo "== Rubric has six criteria and pass-threshold =="
test "$(grep -c '^### ' skills/init-agents-md/references/rubric.md)" = "6"
grep -q "Pass threshold: 80" skills/init-agents-md/references/rubric.md
echo OK

echo "== Examples has three blocks =="
test "$(grep -c '^## Example' skills/init-agents-md/references/examples.md)" = "3"
echo OK

echo "ALL SANITY CHECKS PASS"
```

- [ ] **Step 2: Run the suite**

Expected: `ALL SANITY CHECKS PASS`.

- [ ] **Step 3: If any check fails, return to the responsible task and fix.**

- [ ] **Step 4: No commit (this task is verification only).**

---

## Task 8: Smoke test — INIT mode against `spec-kit-system` itself

**Files:**
- Will produce: `AGENTS.md` at repo root (intentionally — this repo has no AGENTS.md yet).

- [ ] **Step 1: Verify INIT mode preconditions**

```bash
test ! -f AGENTS.md && echo "INIT precondition met" || echo "FAIL: AGENTS.md exists; this is IMPROVE territory"
```

Expected: `INIT precondition met`.

- [ ] **Step 2: Invoke the skill in a Claude Code session**

In a Claude Code session pointed at this repo:

```
/spec-kit:init-agents-md
```

- [ ] **Step 3: Verify the output**

The agent's response must:
- Start with `Mode: INIT (no existing AGENTS.md detected)`.
- Report a self-score ≥ 80.
- Have written `AGENTS.md` at repo root.

- [ ] **Step 4: Run post-emit sanity checks**

```bash
grep -q "<!-- FILL\|<!-- REQUIRED\|<!-- OPTIONAL\|<!-- SKIP\|<!-- OMIT" AGENTS.md && echo "FAIL: directives leaked" || echo "directives clean"
grep -q "{{.*}}\|<install>\|<dev>\|<build>" AGENTS.md && echo "FAIL: placeholder leaked" || echo "placeholders clean"
[ $(wc -c < AGENTS.md) -lt 10240 ] && echo "size OK" || echo "WARN: exceeds 10KB"
```

Expected: `directives clean`, `placeholders clean`, `size OK`.

- [ ] **Step 5: Manual review of `AGENTS.md`**

Read the produced `AGENTS.md`. Confirm:
- Commands listed match `package.json` is absent → the skill should report no Commands section or `_No verified commands._`. (This repo's Commands come from `bin/init-project.{sh,ps1}` only; the agent should pick those up.)
- Architecture mentions the actual top-level dirs (`skills/`, `assets/`, `bin/`, `.claude-plugin/`).
- At least one Gotcha mentions the vendoring rule from CLAUDE.md.

If any item fails, debug SKILL.md instructions and re-run.

- [ ] **Step 6: Commit the generated AGENTS.md**

```bash
git add AGENTS.md
git commit -m "docs: add AGENTS.md generated by init-agents-md self-test"
```

---

## Task 9: Smoke test — IMPROVE mode (re-invocation)

**Files:**
- Will modify: `AGENTS.md` if user approves any diffs during the test.

- [ ] **Step 1: Verify IMPROVE mode precondition**

```bash
test -f AGENTS.md && echo "IMPROVE precondition met"
```

- [ ] **Step 2: Introduce a deliberate staleness**

Edit `AGENTS.md`: insert a bogus command row, e.g.

```markdown
| `npm run lint` | Lint (this command does not exist in this repo) |
```

Commit the staleness (so the test starts from a known dirty state):

```bash
git add AGENTS.md
git commit -m "test: introduce deliberate staleness for IMPROVE test"
```

- [ ] **Step 3: Re-invoke the skill**

```
/spec-kit:init-agents-md
```

- [ ] **Step 4: Verify IMPROVE output**

Response must:
- Start with `Mode: IMPROVE (existing AGENTS.md found, score <n>/100)`.
- Score below 80 (because of the staleness).
- Propose a diff that removes the bogus `npm run lint` row.
- End with `Apply all? [yes / apply 1,2 / cancel]`.
- **Not** have written to `AGENTS.md` yet.

- [ ] **Step 5: Approve the diff**

Reply `yes` to apply.

- [ ] **Step 6: Verify the file was edited**

```bash
grep -q "npm run lint" AGENTS.md && echo FAIL || echo "staleness removed"
```

- [ ] **Step 7: Commit**

```bash
git add AGENTS.md
git commit -m "test: verify IMPROVE mode removes deliberate staleness"
```

---

## Task 10: Smoke test — `--packages` flag on monorepo fixture

**Files:**
- Create: `tmp/fixtures/monorepo/package.json`
- Create: `tmp/fixtures/monorepo/pnpm-workspace.yaml`
- Create: `tmp/fixtures/monorepo/packages/alpha/package.json`
- Create: `tmp/fixtures/monorepo/packages/beta/package.json`

- [ ] **Step 1: Build the fixture**

```bash
mkdir -p tmp/fixtures/monorepo/packages/alpha
mkdir -p tmp/fixtures/monorepo/packages/beta
cat > tmp/fixtures/monorepo/package.json <<'EOF'
{ "name": "monorepo-fixture", "private": true, "scripts": { "build": "pnpm -r build", "test": "pnpm -r test" } }
EOF
cat > tmp/fixtures/monorepo/pnpm-workspace.yaml <<'EOF'
packages:
  - "packages/*"
EOF
cat > tmp/fixtures/monorepo/packages/alpha/package.json <<'EOF'
{ "name": "@fixture/alpha", "version": "0.0.1", "main": "index.js", "scripts": { "build": "echo build alpha", "test": "echo test alpha" } }
EOF
cat > tmp/fixtures/monorepo/packages/beta/package.json <<'EOF'
{ "name": "@fixture/beta", "version": "0.0.1", "main": "index.js", "scripts": { "build": "echo build beta", "test": "echo test beta" } }
EOF
```

- [ ] **Step 2: Invoke the skill against the fixture root**

From a Claude Code session whose working directory is `tmp/fixtures/monorepo/`:

```
/spec-kit:init-agents-md --packages
```

- [ ] **Step 3: Verify outputs**

```bash
test -f tmp/fixtures/monorepo/AGENTS.md
test -f tmp/fixtures/monorepo/packages/alpha/AGENTS.md
test -f tmp/fixtures/monorepo/packages/beta/AGENTS.md
echo "monorepo OK"
```

Expected: `monorepo OK`.

Also verify the rollup output the agent produced lists all three files written.

- [ ] **Step 4: Verify per-package files use the shorter skeleton**

```bash
# Per-package files have at most Commands, Key Files, Gotchas (no Architecture/Environment/Testing/Workflow)
! grep -q "^## Architecture$" tmp/fixtures/monorepo/packages/alpha/AGENTS.md && echo "alpha skeleton OK"
! grep -q "^## Architecture$" tmp/fixtures/monorepo/packages/beta/AGENTS.md && echo "beta skeleton OK"
```

- [ ] **Step 5: Commit fixture only (skill outputs are throwaway)**

```bash
git add tmp/fixtures/monorepo/package.json tmp/fixtures/monorepo/pnpm-workspace.yaml tmp/fixtures/monorepo/packages/
# do NOT commit the generated AGENTS.md files
git commit -m "test: add monorepo fixture for init-agents-md --packages"
```

- [ ] **Step 6: Clean up generated files**

```bash
rm tmp/fixtures/monorepo/AGENTS.md
rm tmp/fixtures/monorepo/packages/alpha/AGENTS.md
rm tmp/fixtures/monorepo/packages/beta/AGENTS.md
```

---

## Task 11: Smoke test — empty-repo failure mode

**Files:**
- Create: `tmp/fixtures/empty-repo/.gitkeep`

- [ ] **Step 1: Build the fixture**

```bash
mkdir -p tmp/fixtures/empty-repo
touch tmp/fixtures/empty-repo/.gitkeep
```

- [ ] **Step 2: Invoke skill against the empty fixture**

From a Claude Code session at `tmp/fixtures/empty-repo/`:

```
/spec-kit:init-agents-md
```

- [ ] **Step 3: Verify graceful degrade**

Response must:
- Start with `Mode: INIT`.
- Write a minimal `AGENTS.md` containing the directory name as the header and a Gotcha noting auto-detection failed.
- Self-score reported (likely <80) with a rationale that explicitly names the constraint.
- Not crash, not refuse, not loop.

- [ ] **Step 4: Verify the output file**

```bash
test -f tmp/fixtures/empty-repo/AGENTS.md
grep -q "Auto-detection" tmp/fixtures/empty-repo/AGENTS.md && echo "graceful degrade OK"
```

- [ ] **Step 5: Commit fixture only**

```bash
git add tmp/fixtures/empty-repo/.gitkeep
git commit -m "test: add empty-repo fixture for init-agents-md failure mode"
```

- [ ] **Step 6: Clean up**

```bash
rm tmp/fixtures/empty-repo/AGENTS.md
```

---

## Task 12: Verify plugin manifest (no-op or update)

**Files:**
- Read: `.claude-plugin/plugin.json`
- Possibly modify: same

- [ ] **Step 1: Inspect manifest**

```bash
cat .claude-plugin/plugin.json
```

- [ ] **Step 2: Decide**

If the manifest contains an explicit `skills` array, append an entry:

```json
{ "name": "init-agents-md", "path": "skills/init-agents-md" }
```

If skills are auto-discovered (no explicit array), no change is required.

- [ ] **Step 3: If you edited the manifest, validate JSON syntax**

```bash
python -m json.tool < .claude-plugin/plugin.json > /dev/null && echo "JSON OK"
```

- [ ] **Step 4: Commit only if edited**

```bash
git add .claude-plugin/plugin.json
git commit -m "chore(plugin): register init-agents-md skill in manifest"
```

---

## Task 13: Update root CLAUDE.md plugin layout note

**Files:**
- Modify: `CLAUDE.md`

The plugin layout section in `CLAUDE.md` currently lists `skills/init/` as the lone plugin-only skill. Add `init-agents-md/` to the same list so future syncers know it's also plugin-only.

- [ ] **Step 1: Find the line to change**

The line currently reads:

```markdown
  init/                         Bootstrap .specify/ into project (new, plugin-only)
```

- [ ] **Step 2: Add `init-agents-md/` immediately below it**

```markdown
  init/                         Bootstrap .specify/ into project (new, plugin-only)
  init-agents-md/               Create/maintain AGENTS.md from codebase discovery (new, plugin-only)
```

Edit `CLAUDE.md` lines 12–14 of the "Plugin Layout" code block.

- [ ] **Step 3: Verify**

```bash
grep -q "init-agents-md/" CLAUDE.md && echo "CLAUDE.md updated"
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): register init-agents-md in plugin layout"
```

---

## Self-Review Notes

Performed inline against `docs/superpowers/specs/2026-05-25-init-agents-md-design.md`:

| Spec section | Covered by task |
|---|---|
| §3 Architecture (5 files) | Task 1 (scaffold), Tasks 2–6 (content) |
| §4 Template design | Task 2 |
| §5.1 Phase 0 dispatch | Task 6 (SKILL.md body) |
| §5.2 INIT 5-phase | Task 6, smoke-tested in Task 8 |
| §5.3 IMPROVE 5-phase | Task 6, smoke-tested in Task 9 |
| §5.4 Monorepo branch | Task 6, smoke-tested in Task 10 |
| §6.1 Naming | Task 6 (frontmatter), Task 7 (grep) |
| §6.2 Arguments | Task 6 (Arguments table) |
| §6.3 Relationship to other skills | Task 13 (CLAUDE.md note) |
| §6.4 Manifest | Task 12 |
| §7 Failure modes (10 cases) | Task 6 (Failure modes table); Tasks 9 & 11 smoke-test cases 1 & 8 |
| §8 Acceptance criteria 1–6 | Task 7 (1, 6), Task 8 (2), Task 9 (3), Task 10 (4), Task 11 (5) |
| §9 Open questions | Decided in spec; no task needed |
| §10 Out of scope | Honored (no telemetry, no CLI alias, no auto-PR) |

**Placeholder scan:** no "TBD" or "fill in later" remain.
**Type consistency:** all section names referenced consistently (Commands, Architecture, Key Files, Code Style, Environment, Testing, Gotchas, Workflow); the per-package shorter skeleton consistently names Commands, Key Files, Gotchas (no Key Exports ambiguity).
