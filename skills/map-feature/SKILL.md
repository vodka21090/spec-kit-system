---
name: map-feature
description: Scout the existing code a feature will touch — its blast radius — before planning or implementing. Reads the active feature spec (or a sub-path) and writes specs/<feature>/codebase-context.md with the relevant files, architectural fit, where to add code, patterns to reuse, and risks. Use before /spec-kit:plan or /spec-kit:implement, when starting or enhancing a feature, or when the user asks to scout/recon the code for a feature.
argument-hint: "(optional) sub-path or feature description to scope the scout; defaults to the active spec"
user-invocable: true
disable-model-invocation: false
tools: Read, Glob, Grep, Bash, Write, Edit, Agent
---

# /spec-kit:map-feature

You scout the **blast radius** of a feature — the existing code it will touch — and write one
focused `codebase-context.md` so `/spec-kit:plan` and `/spec-kit:implement` are grounded in real
code. This is reconnaissance of what *exists*, read through the lens of what the feature *wants*.

## Hard rules (apply to you and every agent)

- **Never read secrets.** Do not open `.env*`, credential files, or private keys. Note env var
  *names* only, never values.
- **Cite real paths.** Every finding references an actual file/dir in backticks. If you can't
  point to it, don't claim it.
- **Evidence over guesswork.** Report what the code shows. Mark inferences "suspected".
- **One focused doc.** Target 80–200 lines — the blast radius, not the whole repo.
- **Date.** Use today's date for `analysis_date`.

## Execution

### Step 0 — Resolve scope

Resolve what to scout, in this order:
1. **Explicit arg sub-path** (e.g. `map-feature src/auth`) → scope to that path. Reject paths
   containing `..`, a leading `/`, or shell metacharacters.
2. **Active feature spec**: read `.specify/feature.json` → `feature_directory`. Read its
   `spec.md` to understand what the feature does, and derive **search seeds** (keywords, entity
   names, actions) from it.
3. **Neither**: ask the user for a sub-path or a one-line feature description, then derive seeds.

Determine the output path:
- In a speckit project with a resolved feature directory → `specs/<feature>/codebase-context.md`.
- Otherwise → `docs/codebase/feature-<slug>-context.md`.

If a `codebase-context.md` already exists at the target, report its `analysis_date` and ask
whether to refresh or skip before overwriting.

### Step 1 — Bound the blast radius (you, on the main thread)

From the search seeds, use `Glob`/`Grep` to find the files the feature will touch — definitions,
call sites, similar existing features, tests in the area. Keep it cheap; do not read deeply here.
Produce a candidate file list. **Do not read codebase files for analysis yourself** — that is the
agent's job (orchestrator plans, agent reads).

Get the current commit for `source_sha`:
```bash
git rev-parse --short HEAD
```

### Step 2 — Check for an existing codebase map

Check whether `docs/codebase/ARCHITECTURE.md` exists. Pass the answer to the agent so it follows
the **link-or-derive** rule: if it exists, the agent deep-links the relevant `ARCHITECTURE.md`
anchors and draws only the local flow; if not, it derives a mini local-architecture inline.

### Step 3 — Dispatch the scout agent

Read `${CLAUDE_PLUGIN_ROOT}/templates/codebase/agent-prompt.md` and fill the skeleton with the
**blast-radius scout** focus. Dispatch **one `Agent`** (use `subagent_type: "Explore"`). Scale to
two agents only if the blast radius spans clearly separable areas.

Fill the slots: `<FOCUS>` = blast-radius scout; `<DOC_ID>` = FEATURE-CONTEXT;
`<SKILL>` = `/spec-kit:map-feature`; `<OUTPUTS>` = the resolved output path;
`<TEMPLATES>` = `${CLAUDE_PLUGIN_ROOT}/templates/codebase/feature-context.md`;
`<SCOPE>` = the candidate file list + scope paths; `<SHA>` = the short sha from Step 1.

Add to the agent prompt: the feature intent (summarised from `spec.md` or the user's
description), the candidate file list, and whether `ARCHITECTURE.md` exists (for link-or-derive).

### Step 4 — Write and report

After the agent returns, confirm `codebase-context.md` was written. Report:
- The output path and its line count.
- A 3-5 line summary of the blast radius.
- That `/spec-kit:plan` and `/spec-kit:implement` can now read this file for grounding.

Do **not** run git and do **not** touch `AGENTS.md` — this artifact is feature-scoped and
ephemeral; it is read directly by plan/implement, not registered for global discovery.

## Speckit integration (optional hook)

`map-feature` can run automatically before planning. Register an **optional** hook in
`.specify/extensions.yml`:

```yaml
hooks:
  before_plan:
    - extension: map-feature
      command: speckit.map.feature
      optional: true
      description: "Scout the feature's blast radius before planning"
```

`speckit.map.feature` resolves to `/spec-kit:map-feature` (strip `speckit.`, dots → hyphens,
prepend `/spec-kit:`). `optional: true` means it is *suggested*, never forced. The same can be
registered under `before_implement`.

## Notes

- Plugin-only (not part of the spec-kit upstream payload). Works best inside a speckit project
  but also runs on a bare sub-path.
- Shares the spawn-prompt and frontmatter schema with `/spec-kit:map-codebase` via
  `templates/codebase/agent-prompt.md`.
