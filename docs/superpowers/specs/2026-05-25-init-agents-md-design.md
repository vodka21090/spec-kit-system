# Design Spec — `init-agents-md` skill

**Status:** Approved (brainstorming complete, awaiting implementation plan)
**Date:** 2026-05-25
**Owner:** Phuong Nguyen (vodka21090@gmail.com)
**Plugin:** spec-kit-system
**Upstream references:**
- Anthropic `claude-md-management/skills/claude-md-improver` (5-phase audit workflow, 6-criterion rubric, diff/approval format)
- Anthropic `plugin-dev/skills/agent-development` (frontmatter conventions, "When to invoke" section)
- Open standard: [agents.md](https://agents.md)

---

## 1. Problem statement

Repositories adopting AI coding agents (Claude Code, Codex, Cursor, Aider, Gemini) benefit from a vendor-neutral project-memory file: `AGENTS.md`. Currently `spec-kit-system` ships `skills/init/` to bootstrap `.specify/` but has **no skill to create or maintain `AGENTS.md`**. Users must either hand-author the file or rely on vendor-specific tools (e.g. Claude's `claude-md-improver`).

Goal: ship a plugin-only skill `init-agents-md` that

1. **Initializes** a high-signal `AGENTS.md` at the repo root by discovering the codebase itself, and
2. **Maintains** an existing `AGENTS.md` via the same audit-and-diff workflow Anthropic uses for `CLAUDE.md`,

without hard-coupling to any specific AI vendor in the produced output.

## 2. Non-goals

- Audit/produce per-package `AGENTS.md` files in a monorepo by default. (Opt-in via `--packages` flag, see §6.3.)
- Touch `CLAUDE.md`, `.cursorrules`, or other vendor-specific files. (Read-only cross-reference allowed.)
- Replace `skills/init/`. The two skills are independent.
- Integrate with upstream `github/spec-kit`. This is plugin-only; not vendored.
- Provide a CLI / non-skill entry point. Invocation is solely `/spec-kit:init-agents-md`.

## 3. Architecture overview

Single skill, dual-mode (INIT / IMPROVE) selected by phase-0 dispatch on whether `AGENTS.md` already exists at the repo root. Template and references are separate files so the IMPROVE mode can read the canonical template when auditing.

```
skills/init-agents-md/
├── SKILL.md                       # Frontmatter + dual-mode workflow + prompt body
├── template.md                    # Markdown skeleton with placeholders (see §4)
└── references/
    ├── rubric.md                  # 6-criterion 100-pt scoring rubric
    ├── adaptation-matrix.md       # Project-type → sections to include/omit
    └── examples.md                # 2-3 worked examples (Go CLI, Node monorepo, Python lib)
```

**Decision rationale:** chose single-skill-dual-mode over (a) separate `init` + `improve` skills or (b) unified "reconcile" workflow. Single entrypoint is easier for users to discover and learn; dual-mode keeps the two distinct flows readable inside one SKILL.md.

## 4. Template design (`template.md`)

### 4.1 Skeleton

Nine sections; some required, some optional. Required sections are always emitted (or replaced with an explicit empty-marker). Optional sections are omitted if no concrete content exists.

```markdown
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
```

### 4.2 Placeholder taxonomy

| Token | Meaning | Agent action at fill time |
|---|---|---|
| `{{NAME}}` | Inline scalar | Replace with derived value |
| `<value>` | Example in table row or list item | Replace if keeping row; delete row if not applicable |
| `<!-- FILL/REQUIRED/OPTIONAL/SKIP-SECTION-IF/OMIT-ROWS-IF: ... -->` | Directive for the agent | **Strip from final output**; meaning only at fill time |

### 4.3 Emit rules

1. Strip every HTML comment before writing the file.
2. Section with directive `SKIP-SECTION-IF` whose predicate holds → remove heading + body.
3. Optional section with no concrete content → remove heading + body.
4. `Commands` table with zero verified rows → keep heading, replace body with `_No verified commands._` (signal, not pretense).
5. Final file size hard ceiling 10 KB; trigger compression pass if exceeded (rewrite the longest section as a table/bullet list).

## 5. Workflow design (`SKILL.md` body)

### 5.1 Phase 0 — Dispatch

```
detect AGENTS.md at repo root
├── absent     → INIT MODE
└── present    → IMPROVE MODE
```

The first line of the agent's output is `Mode: INIT` or `Mode: IMPROVE` so users immediately know which flow ran.

### 5.2 INIT MODE (5 phases)

| # | Phase | Action | Stop condition |
|---|---|---|---|
| 1 | Discover | Read manifests, README, CI configs, top 2 levels of `src/` (or equivalent), `.env.example`, existing AI-context files | Project type identified + ≥3 verified commands |
| 2 | Probe (optional) | Grep `TODO\|FIXME\|HACK`, read 1-2 test files, check codegen | ≥1 gotcha found, or confirmed none |
| 3 | Draft | Load `template.md`, fill placeholders, apply `adaptation-matrix.md` to omit/keep sections | Draft complete; directives stripped |
| 4 | Self-evaluate | Score via `rubric.md`. If <80, fix lowest-scoring criterion, re-score. Max 2 passes | Score ≥80 or 2 passes exhausted |
| 5 | Emit | Write `AGENTS.md` at repo root + print rationale + self-score | File written |

**Output format (INIT):**

```
Mode: INIT (no existing AGENTS.md detected)

<file written: AGENTS.md>

Rationale: <2-4 sentences: sections included/omitted, biggest risk, verification step that would catch it>
Self-score: <total>/100 (commands <n>/20, architecture <n>/20, gotchas <n>/15, conciseness <n>/15, currency <n>/15, actionability <n>/15)
```

### 5.3 IMPROVE MODE (5 phases)

Ported from `claude-md-improver` with template-awareness.

| # | Phase | Action | Output |
|---|---|---|---|
| 1 | Read current | Load existing `AGENTS.md` | Current content in context |
| 2 | Reconnaissance | Same commands as INIT phases 1–2, but for cross-check, not fill | Discovered facts list |
| 3 | Score & gap | Score current file via `rubric.md`. Cross-reference with reconnaissance: stale commands, missing dirs, undocumented gotchas | Quality report + gap list |
| 4 | Propose diff | Show diff (additions/removals) per section, each with a **Why** line. **Do not** write yet | Diff block in message |
| 5 | Apply on approval | Wait for `apply` / `apply 1,2` / `skip <n>` / `cancel`. Apply approved hunks via Edit tool | Updated file |

**Output format (IMPROVE):**

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

### 5.4 Monorepo branch (`--packages`)

After root `AGENTS.md` completes (either mode):

1. Glob `{packages,apps}/*/package.json|pyproject.toml|Cargo.toml|go.mod`.
2. For each detected package, run the corresponding mode against the package root, using a shorter skeleton: only the `Commands`, `Key Files` (used here for public exports / entry points), and `Gotchas` sections from §4.1. All other sections are unconditionally omitted in per-package files.
3. Emit a single rollup output listing every file written/proposed.

## 6. Integration with the spec-kit plugin

### 6.1 Naming & namespacing

| Field | Value |
|---|---|
| Folder | `skills/init-agents-md/` |
| `name:` frontmatter | `init-agents-md` |
| Invocation | `/spec-kit:init-agents-md` |
| `description:` | "Use this agent when… Typical triggers include… See 'When to invoke' in the body." |
| `tools:` | `["Read", "Glob", "Grep", "Bash", "Write", "Edit"]` |
| `model:` | `inherit` |
| `color:` | `cyan` |

### 6.2 Arguments

Parsed from the user message body (free-form, not flag-strict):

- `--packages` — opt-in monorepo per-package generation.
- `--lang <code>` — output language (default: `en`).
- `--depth minimal|standard|comprehensive` — default `standard`.
- `--workflow` — force-include the optional Workflow section.

### 6.3 Relationship to other skills

- **`skills/init/`** (existing, plugin-only): bootstraps `.specify/`. Independent. Users may run either or both.
- **Speckit upstream skills (`specify`, `plan`, `tasks`, …)**: unrelated. No call-graph.
- **Vendoring rule**: this skill is **not** vendored from `github/spec-kit`. Sync passes (`grep -rn "/speckit-" skills/`) are unaffected. A comment at the top of SKILL.md will document this for future syncers:
  ```
  <!-- plugin-only skill; not vendored from github/spec-kit upstream. Safe to edit directly. -->
  ```

### 6.4 Manifest

If `.claude-plugin/plugin.json` lists skills explicitly, add an entry. Otherwise (auto-discover) no change. Confirm during implementation.

## 7. Failure modes & edge cases

| # | Situation | Behavior |
|---|---|---|
| 1 | Repo empty (only `.git/`, no manifest/source) | INIT degrade: emit minimal AGENTS.md with only the name + a Gotcha "Auto-detection found no manifest or source; expand manually." Self-score <80; emit anyway with rationale. |
| 2 | Repo has only binary/design assets (.pen, .psd, .blend) | Same as case 1; Architecture lists file layout instead of source tree. |
| 3 | Manifest references missing entry file | List the command with tag `# unverified — entry file not found`; add a Gotcha. Never silent-omit. |
| 4 | Both `AGENTS.md` and `CLAUDE.md` exist | IMPROVE mode on `AGENTS.md`. Read `CLAUDE.md` during reconnaissance for cross-check; propose syncing accurate facts (Why = "synced from CLAUDE.md"). Never touch CLAUDE.md. |
| 5 | `.cursorrules` / `.github/copilot-instructions.md` exists but no AGENTS.md | INIT mode. Read those files during Discover phase 1.7. Paraphrase agent-relevant content into AGENTS.md (vendor-neutral). Leave originals in place. |
| 6 | Monorepo `--packages` flag with package lacking manifest | Skip; list in rollup as "Skipped: \<path\> (no manifest)". |
| 7 | User cancels IMPROVE phase 5 | No file change. Output: "No changes applied. Re-run skill or edit manually." |
| 8 | Self-eval still <80 after 2 passes | Emit anyway. Rationale must name failing criterion + concrete cause. |
| 9 | Git submodules present | Treat root as standalone. List submodule paths in Architecture with `# submodule — see its own AGENTS.md`. Do not recurse. |
| 10 | Projected file size >8 KB after fill | Trigger compression pass (rewrite longest section as table/bullet). Hard ceiling 10 KB. |

### 7.1 Post-emit sanity checks (INIT mode)

```bash
# 1. Comment directives stripped?
grep -q "<!-- FILL\|<!-- REQUIRED\|<!-- OPTIONAL\|<!-- SKIP\|<!-- OMIT" AGENTS.md && echo "FAIL: directives leaked"

# 2. Placeholder tokens stripped?
grep -q "{{.*}}\|<install>\|<dev>\|<build>" AGENTS.md && echo "FAIL: placeholder leaked"

# 3. File size sane?
[ $(wc -c < AGENTS.md) -lt 10240 ] || echo "WARN: exceeds 10KB"
```

Sanity failures are logged in the rationale; the skill does not auto-correct because a leaked-looking token might be intentional content (e.g. a code example).

## 8. Acceptance criteria

The skill is considered complete when:

1. `skills/init-agents-md/` exists with `SKILL.md`, `template.md`, and three reference files.
2. `/spec-kit:init-agents-md` invocation in a fresh clone of `spec-kit-system` itself produces an `AGENTS.md` with self-score ≥80 and passes the 3 sanity checks.
3. Re-invoking on the same repo enters IMPROVE mode, produces a quality report, and waits for approval before editing.
4. `--packages` flag on a 2-package fixture produces root + 2 per-package files.
5. Failure mode #1 (empty repo) is verified manually: skill emits a minimal file with transparent rationale.
6. Greps pass: `grep -rn "/speckit-" skills/init-agents-md/` returns 0 hits; `grep "^name:" skills/init-agents-md/SKILL.md` returns `name: init-agents-md`.

## 9. Open questions / risks

- **Lang flag scope:** does `--lang vi` translate only the prose body, or also the directive comments? **Decision:** prose only; directives are agent-facing, stripped before emit.
- **Token cost of references/**: three reference files loaded on demand; if the model loads all three eagerly, context could balloon. **Mitigation:** SKILL.md instructs "load reference X only when phase Y triggers".
- **Conflict with future per-package AGENTS.md skill:** if a separate skill is added later, both should share `template.md`. Implementation should keep template fully decoupled from SKILL.md for this reason.

## 10. Out of scope (explicit non-deliverables in this spec)

- Slash-command alias outside the spec-kit plugin namespace.
- Telemetry / usage logging.
- Integration tests beyond the manual acceptance criteria.
- Auto-PR creation against the target repo.
- Translation of the produced AGENTS.md after emit (only `--lang` at generation time).
