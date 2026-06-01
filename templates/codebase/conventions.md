# Coding Conventions Template

Template for `docs/codebase/CONVENTIONS.md` — captures coding style and patterns.

**Purpose:** Document how code is written in this codebase. Prescriptive guide so a contributor (human or AI) can match existing style. Derive each convention from real examples, not from a generic style guide — cite a file where the pattern is visible.

---

## File Template

```markdown
---
schema_version: 1
doc: CONVENTIONS
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
sections:
  - { id: naming-patterns, summary: "[file/function/variable/type naming]" }
  - { id: code-style, summary: "[formatting + linting]" }
  - { id: import-organisation, summary: "[import order + path aliases]" }
  - { id: error-handling, summary: "[throw/catch strategy]" }
  - { id: logging, summary: "[framework + patterns]" }
  - { id: comments, summary: "[when/how to comment]" }
  - { id: function-design, summary: "[size/params/returns]" }
  - { id: module-design, summary: "[exports + barrel files]" }
---

# Coding Conventions

## Naming Patterns

**Files:** [e.g., "kebab-case for all files"; test files `*.test.ts` alongside source]

**Functions:** [e.g., "camelCase"; event handlers `handleEventName`]

**Variables:** [e.g., "camelCase"; constants `UPPER_SNAKE_CASE`]

**Types:** [e.g., "PascalCase interfaces, no `I` prefix"]

## Code Style

**Formatting:**
- [Tool: e.g., "Prettier, config in `.prettierrc`"]
- [Line length / quotes / semicolons]

**Linting:**
- [Tool + config file]
- [Run: e.g., `npm run lint`]

## Import Organisation

**Order:**
1. [e.g., "External packages"]
2. [e.g., "Internal modules (@/lib)"]
3. [e.g., "Relative imports"]

**Path Aliases:** [Aliases used: e.g., "@/ for src/"]

## Error Handling

**Patterns:** [Strategy: e.g., "throw errors, catch at boundaries"]

**Error Types:** [When to throw vs return; custom error classes]

## Logging

**Framework:** [Tool + levels]

**Patterns:** [Format, when, where]

## Comments

**When to Comment:** [e.g., "explain why, not what"]

**Doc Comments:** [JSDoc/TSDoc usage and required tags]

**TODO Comments:** [Pattern: e.g., `// TODO(username): description`]

## Function Design

**Size:** [e.g., "keep under 50 lines, extract helpers"]

**Parameters:** [e.g., "max 3 params, object for more"]

**Return Values:** [e.g., "explicit returns, guard clauses first"]

## Module Design

**Exports:** [e.g., "named exports preferred"]

**Barrel Files:** [e.g., "index.ts re-exports public API; avoid circular deps"]

---

*Convention analysis: [date]. Update when patterns change.*
```
