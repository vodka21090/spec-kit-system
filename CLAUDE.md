# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`spec-kit-system` = Claude Code Plugin. Repackages [github/spec-kit](https://github.com/github/spec-kit) (pinned `SPECKIT_VERSION`, currently 0.8.13) so SDD workflow installs via `/plugin install` -- no `uv`/Python at runtime.

Plugin name: `spec-kit`. Skills namespaced `/spec-kit:<name>` (e.g. `/spec-kit:specify`, `/spec-kit:plan`, `/spec-kit:init`).

### Plugin Layout

```
.claude-plugin/plugin.json    Manifest (name, version, upstream pin)
SPECKIT_VERSION               Pinned upstream version
skills/                       15 skills
  init/                         Bootstrap .specify/ into project (new, plugin-only)
  init-agents-md/               Create/maintain AGENTS.md from codebase discovery (new, plugin-only)
  constitution/ specify/ clarify/ plan/ tasks/ analyze/ implement/ checklist/ taskstoissues/
  git-{commit,feature,initialize,remote,validate}/
assets/specify/               Bootstrap payload -- vendored .specify/ tree
  templates/ scripts/{bash,powershell}/ memory/ extensions/git/
  extensions.yml workflows/ integrations/ init-options.json integration.json
bin/init-project.{sh,ps1}     Idempotent bootstrap helpers (POSIX + Windows)
tmp/                          Upstream probe (uv-installed). Reference only, do not edit.
```

### Vendoring Rules (load-bearing)

- **Skills vendored verbatim** from `tmp/.claude/skills/speckit-*/SKILL.md`. Only adaptation: `name:` field renamed (drop `speckit-` prefix), cross-refs `/speckit-X` -> `/spec-kit:X`, hook-rule sentence rewritten so `speckit.git.commit` -> `/spec-kit:git-commit` (was `/speckit-git-commit`).
- **Payload (`assets/specify/`) byte-for-byte** copy of `tmp/.specify/`. Do not edit in place -- changes get clobbered on next upstream sync. To customize per project, use `.specify/templates/overrides/` in the project user.
- **Sync upstream** = re-run `specify init` into `tmp/`, replace `assets/specify/`, re-run rename+sed pipeline on `skills/`, bump `SPECKIT_VERSION` + manifest `metadata.speckit_upstream`. Automation TODO: `bin/sync-upstream.sh`.

### Portability Stance

Claude Code first. Templates in `assets/specify/templates/` are plain Markdown -- portable to Copilot/Cursor/Gemini via future adapter (out of scope for v0.1). Do not write Claude-only idioms into templates.

<!--
### Methodological Foundations

- **GitHub spec-kit** — the core spec-driven methodology. All product work flows through written specs before implementation.
- **Kiro-inspired spec taxonomy**:
  - **Feature Specs** — two workflows:
    - *Requirement-First*: spec starts from user/business requirements, design is derived.
    - *Design-First*: spec starts from a desired interface/UX, requirements are reverse-engineered.
  - **Bug Specs** — bugs are first-class spec artifacts (reproduction, root cause, fix contract), not ad-hoc tickets.
  - **Steering Files** — long-lived project context. These will live under `/codebases` and act as **initial context** loaded by any downstream project that consumes this system. Steering files are not Claude Code skills and are not specific to one AI surface.
- **BMAD Method** — specialist agents. Work is decomposed across role-shaped agents (analyst, PM, architect, dev, QA, etc.) rather than one generalist.

### Architectural Intent (load-bearing)

These are conventions future sessions must respect even while the repo is still being scaffolded:

- **Spec → Steering → Code.** Nothing implementation-level should be authored before the spec exists. Steering files are the bridge: they encode decisions a spec made so that subsequent prompts (in any tool) inherit them without re-reading the full spec.
- **Tool-portability is a hard constraint.** Anything written for Claude Code only is a leaky abstraction. Specs and steering content must be plain Markdown that any of the listed AI surfaces can consume; tool-specific wiring is the integration layer, not the system.
- **Specialist agents are spec consumers, not spec authors.** A BMAD-style agent is invoked with a spec + relevant steering files as input. If an agent needs information the spec does not contain, the spec is incomplete — fix the spec, do not let the agent improvise.
- **`/codebases` is the public surface.** When introduced, treat it as the export boundary for steering context. Anything outside `/codebases` is internal authoring/scaffolding. -->

### Build / Test / Lint

No build/test/lint pipeline. Validation = manual smoke:

```powershell
claude --plugin-dir C:/dev/spec-kit-system
# Then in session:
/help                       # 15 skills /spec-kit:* visible
/spec-kit:init              # bootstraps .specify/ in CWD
/spec-kit:specify <feat>    # creates specs/NNN-<slug>/spec.md
```

Sanity greps after upstream sync:
- `grep -rn "/speckit-" skills/` -> 0 hits (else missed a rename).
- `grep -H "^name:" skills/*/SKILL.md` -> all match folder name.

Do not add package manager / CI / test framework without explicit spec.

---

## Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
