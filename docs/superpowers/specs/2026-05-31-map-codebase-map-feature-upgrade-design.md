# Design: `map-codebase` + `map-feature` upgrade

**Date:** 2026-05-31
**Status:** Approved (Phase 1 ready for planning). Phase 2 deferred.
**Author:** brainstorming session (Phuong Nguyen + Claude)
**Inspiration:** [`kingbootoshi/cartographer`](https://github.com/kingbootoshi/cartographer) (packed at `cartographer-repomix.md`)

---

## 1. Goal

Upgrade the plugin-owned `/spec-kit:map-codebase` skill and its `docs/codebase/` report
templates so the output is **dual-purpose** — a human onboards from it, an AI agent reads,
searches, and navigates by it — and add a **feature-scoped** companion that scouts the
existing code a feature will touch, so speckit can ground `plan`/`implement` in real code.

Drawn from Cartographer's scanning philosophy, but **adapted** to this plugin's constraints:
Claude Code first, cross-platform, **no `uv`/Python runtime dependency** (CLAUDE.md). The
Cartographer Python+tiktoken scanner is therefore *not* ported verbatim.

## 2. Naming decision

Two skills, parallel verb, scope-as-noun → self-documenting in `/help`:

```
/spec-kit:map-codebase   Map the whole repository → docs/codebase/
/spec-kit:map-feature    Map the code a feature touches → specs/<feature>/codebase-context.md
```

The `codebase ↔ feature` contrast explains scope without reading the description. Residual
ambiguity ("feature may not exist yet") is resolved by each skill's `description` /
`argument-hint`, not by the name. Considered and rejected: single-skill-two-modes (hook
wiring reads wrong — see §3) and auto-detect-context (unpredictable, hard to test).

## 3. Architecture: two skills + shared files

**Deciding factor for two skills = hook wiring.** Speckit hooks in `.specify/extensions.yml`
reference commands *by name* (`speckit.x.y` → `/spec-kit:x-y`). A dedicated named skill is
cleanly wireable as a `before_plan`/`before_implement` hook; a `map-codebase <arg>` mode would
force the hook to call the full-map command with a flag — works, but reads wrong.

**Controlling the "two skills = duplicated logic" downside** — split shared pieces by
*consequence-of-absence*, not by length:

| Shared piece | Where it lives | Why |
|---|---|---|
| Safety hard-rules (no secrets / cite paths / evidence-over-guess / length cap / date) | **Inline in BOTH `SKILL.md`** | Safety-critical → must always be in context, not Read-on-demand |
| Spawn-prompt skeleton + frontmatter schema v2 | **Shared file** `templates/codebase/agent-prompt.md` | Bulky execution template → Read-on-demand is fine |

### File / folder layout

```
skills/
  map-codebase/SKILL.md          # upgraded
  map-feature/SKILL.md           # NEW
templates/codebase/
  agent-prompt.md                # NEW — shared spawn-prompt skeleton + frontmatter v2 schema
  readme.md … concerns.md        # upgraded: frontmatter v2, frozen headings, nav index
  feature-context.md             # NEW — map-feature output template
```

`templates/codebase/` is plugin-owned and **must never be clobbered** by an upstream sync
(it is outside `assets/specify/`). This holds for the new files too.

---

## 4. Phase 1 scope

### 4.1 `map-feature` (new skill)

Reads the feature's *intent*, then scouts the existing code's **blast radius** — which files
the feature touches, where to add code, patterns to reuse, risks in that area.

**Input — scope resolution order:**
1. Explicit sub-path arg (e.g. `map-feature src/auth`) → scope to that path.
2. Active feature spec: read `.specify/feature.json` → `feature_directory` → read `spec.md` →
   derive search seeds (keywords, entities, actions).
3. Neither → ask the user for a path or short description.
   (Reject paths with `..`, leading `/`, or shell metacharacters — same rule as map-codebase.)

**Output — one focused doc** at `specs/<feature>/codebase-context.md` (co-located with the
spec so `plan`/`tasks`/`implement` read it). Fallback when not in a speckit project:
`docs/codebase/feature-<slug>-context.md`.

**Output schema (8 sections):**
```markdown
---
schema_version: 1
doc: FEATURE-CONTEXT
feature: <slug>
analysis_date: YYYY-MM-DD
generated_by: /spec-kit:map-feature
source_sha: <short-sha>
scope_paths: [...]
blast_radius_files: [{ path, purpose }]   # inverted index, grep-able
entry_points: [...]
sections: [{ id, summary }]
---
# Feature Context: <name>

## Vùng ảnh hưởng (blast radius)        # existing files the feature touches; cite paths
## Vị trí trong kiến trúc (architectural fit)
    # layers crossed (route→service→repo), local data flow, architectural constraints
    # + one bounded mermaid sequenceDiagram/graph of the LOCAL blast-radius flow
    # LINK-OR-DERIVE: if docs/codebase/ARCHITECTURE.md exists → deep-link its anchors/diagram;
    #                 else → derive a mini local-architecture (+ local diagram) inline
## Chỗ thêm code mới                     # insertion points, by convention
## Pattern nên tái dùng                  # similar existing impls to mirror
## Convention vùng này                   # local naming/structure/testing
## Integration điểm chạm                 # DB/API/services in scope
## Rủi ro & test không được phá          # fragile spots, tests that must stay green
## Câu hỏi mở (suspected)                # needs human confirmation
```

**Flow (Cartographer discipline — orchestrator never reads files directly):**
1. Resolve scope (arg | active spec | ask).
2. If spec available: read `spec.md` → extract intent → search seeds.
3. Lightweight recon on main thread: Glob/Grep from seeds to bound the blast radius
   (no token scanner needed — the slice is narrow by construction).
4. Dispatch **1 Agent** (scale to 2 only if blast radius is wide) to read blast-radius files
   and return the context doc per schema.
5. Write `codebase-context.md`.
6. Report; note `plan`/`implement` can consume it.

**Does NOT touch AGENTS.md** — output is ephemeral, feature-lifecycle-scoped, read directly by
plan/implement. Lifecycle decides residence.

### 4.2 Templates → AI-navigable

Three lightweight mechanisms, no new tooling:

**(a) Frontmatter v2 — tiered, versioned.** Replaces the current bold `Analysis Date` line.

- **Tier 1 Core (every doc):** `schema_version`, `doc`, `analysis_date`, `generated_by`,
  `source_sha`.
- **Tier 2 Navigation (every doc):** `sections: [{ id, summary }]` — anchor contract *with*
  one-line summaries, so an agent reads frontmatter and routes to the right section without
  opening the file.
- **Tier 3 Index (README + STRUCTURE only):** `modules`, `entry_points`,
  `key_files: [{ path, purpose, see }]` — the inverted index folded into the markdown (one
  source of truth, no separate JSON to drift).
- **Extensibility:** `schema_version` guards breaking changes; an `x-*` namespace lets a
  project add custom fields (e.g. `x-team: { owner, jira_epic }`) that consumers ignore safely
  — no template fork needed.

**(b) Stable anchors via frozen headings.** Templates own the headings, so slugified anchors
(`## Data Flow` → `#data-flow`) are stable *by construction*. Freeze the canonical heading set
and publish it via `sections:`. This is what makes map-feature's link-or-derive load-bearing.

**(c) Navigation Index table in STRUCTURE.md** — `path → purpose → see` for key dirs/files
(module-level, capped to respect the 80–250 line limit). Agents grep one table; humans read it
as a per-file TOC.

**(d) Mermaid diagrams — bounded, high-level.** Mermaid is fenced ` ```mermaid ` Markdown, so
it stays portable (non-rendering viewers show the source) — the earlier "out of scope" call was
over-cautious. Placement, no duplication:
- `ARCHITECTURE.md` → `## System Overview` carries a `graph TB` of modules/layers; `## Data Flow`
  carries `sequenceDiagram`(s) for the primary flows (request, auth).
- `feature-context.md` → `## Vị trí trong kiến trúc` carries one small `sequenceDiagram`/`graph`
  of the **local** blast-radius flow only.
- `README.md` stays text + links to the ARCHITECTURE diagram (no duplicate diagram → no drift).

Discipline (same spirit as the frontmatter rule):
- **High-level only** — nodes are modules/layers and primary flows, **never one-node-per-file**.
- **A diagram visualizes prose already in the doc — not a second source of truth.**
- Templates ship a **canonical fenced skeleton** so agents fill a known shape (fewer broken
  diagrams). Diagram sections are part of the frozen-heading anchor contract.
- map-feature obeys link-or-derive: if `ARCHITECTURE.md` exists, link its diagram anchor and draw
  only the local flow; else derive the local diagram inline.

**Load-bearing discipline:** *frontmatter is an INDEX of the body, not a second source of
truth.* Every field must be derivable from what the doc already states — no facts that live
only in frontmatter. This is what keeps rich frontmatter from drifting away from the markdown.

### 4.3 Spawn-prompt v2 (shared `agent-prompt.md`)

Skeleton both skills fill in. Upgrades over the current generic prompt: structured return
value framing; incremental reading discipline; mandatory frontmatter v2 output; frozen-heading
anchors; populate `sections[].summary` + (README/STRUCTURE) `key_files`; restated hard-rules;
index-not-source discipline.

Two fills:
- **map-codebase:** `<FOCUS>` ∈ {tech, arch, quality, concerns} → writes the 8 docs.
- **map-feature:** `<FOCUS>` = blast-radius scout → writes 1 `codebase-context.md`.

### 4.4 `map-codebase` upgrades (consolidated)

| # | Upgrade | Serves |
|---|---|---|
| 1 | Frontmatter v2 on all 8 docs (Core+Nav; README/STRUCTURE add Tier-3) | AI-navigable |
| 2 | Frozen headings → anchor contract via `sections:` | AI-navigable + map-feature links |
| 3 | Navigation Index table in STRUCTURE.md | search |
| 4 | `source_sha` → concrete staleness check (vs HEAD) | incremental-update detection |
| 5 | Shared spawn-prompt v2 | task #2 |
| 6 | AGENTS.md discovery line extended (note per-feature context under `specs/`) | task #3 |
| 7 | Size guardrail at recon: count files (`git ls-files`/Glob); if over threshold, warn + suggest scoping by sub-path or using map-feature | large-repo safe-fail |
| 8 | Bounded mermaid diagrams in ARCHITECTURE.md (System Overview `graph TB`, Data Flow `sequenceDiagram`) | human onboarding (visual) |

The skill keeps the **fixed 4-focus model** in Phase 1 (fine for small/medium repos — the
common case). Large-repo users scope manually via the already-supported sub-path arg; the size
guardrail makes oversize repos fail safe instead of silently overflowing context. Automatic
token-budgeted scaling is **Phase 2**.

### 4.5 AGENTS.md / CLAUDE.md update (task #3)

Only `map-codebase` upserts the existing marker block
(`<!-- BEGIN spec-kit:codebase-map -->` … `<!-- END ... -->`), extended with a line telling
agents that per-feature context may exist under `specs/`. If the project uses a CLAUDE.md with
a SPECKIT marker region, mirror the line there; otherwise skip.

### 4.6 Speckit hook wiring

Document registering an **optional** hook in `.specify/extensions.yml`:
```yaml
hooks:
  before_plan:
    - { extension: map-feature, command: speckit.map.feature, optional: true,
        description: "Scout blast radius before planning" }
```
`speckit.map.feature` → `/spec-kit:map-feature`. Optional = suggested, not forced.

### 4.7 Build sequence (Phase 1)

1. Shared `agent-prompt.md` (skeleton + schema v2 + anchor contract).
2. Upgrade 8 templates (frontmatter v2, frozen headings, nav index in STRUCTURE, mermaid
   skeletons in ARCHITECTURE).
3. New `feature-context.md` template.
4. New `map-feature/SKILL.md`.
5. Upgrade `map-codebase/SKILL.md` (shared prompt, frontmatter v2, `source_sha`, size guardrail).
6. Extend AGENTS.md discovery.
7. Document the hook example.

### 4.8 Verification

- Smoke: `claude --plugin-dir C:/dev/spec-kit-system`, confirm `/spec-kit:map-codebase` and
  `/spec-kit:map-feature` both visible.
- Sanity greps (CLAUDE.md): `grep -rn "/speckit-" skills/` → 0 hits;
  `grep -H "^name:" skills/*/SKILL.md` → each matches its folder.
- Dogfood: run `map-feature` against this repo's own `specs/` and inspect the context doc.

---

## 5. Phase 2 — Deferred (resume future brainstorming here)

Gated on **real, observed need** — do not build "because Cartographer has it." Cartographer
needs a token scanner *because* it assigns agents by token budget; map-codebase's fixed
4-focus split needs no budgeting, and map-feature is narrow by construction. Build only when
"map a huge repo in one shot" is a proven pain for actual speckit users.

1. **Dependency-free scanner** — `chars/4` token estimate (NOT tiktoken/uv — preserves the
   no-Python-runtime stance), respects `.gitignore`, emits file tree + token budget.
2. **Dynamic agent assignment** — group files by module, balance token budgets, spawn N
   reading agents scaled to repo size; synthesize into the 8 docs. Two-phase: token-budgeted
   *reading* agents → focus *synthesis*.
3. **Incremental update via manifest** — use `source_sha` (already in Phase 1) + a per-doc
   file-hash/path manifest to regenerate *only* changed modules. Phase 1 ships the *detection*
   half (`source_sha` vs HEAD); Phase 2 ships the *regenerate-changed-only* half.

**To resume:** new session → "continue Phase 2 brainstorming from this spec" (or "Phase 2
map-feature"). Read this section, then run the brainstorming flow on items 1–3.

---

## 6. Out of scope

- Porting Cartographer's Python/tiktoken scanner verbatim (portability conflict).
- A separate machine-readable `index.json` (grep over frontmatter + nav table suffices; revisit
  only if programmatic tooling consumes it).
- Multi-assistant adapters (Copilot/Cursor) — out of scope, per CLAUDE.md portability stance.
