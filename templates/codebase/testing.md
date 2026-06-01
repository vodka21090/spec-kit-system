# Testing Patterns Template

Template for `docs/codebase/TESTING.md` — captures test framework and patterns.

**Purpose:** Document how tests are written and run, so a contributor can add tests that match existing patterns. Show real snippets copied from the repo, not invented examples. If there are no tests, say so plainly and note it in CONCERNS.md too.

---

## File Template

```markdown
---
schema_version: 1
doc: TESTING
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
sections:
  - { id: test-framework, summary: "[runner + assertions + run commands]" }
  - { id: test-file-organisation, summary: "[location + naming]" }
  - { id: test-structure, summary: "[suite organisation + patterns]" }
  - { id: mocking, summary: "[framework + what to mock]" }
  - { id: fixtures-and-factories, summary: "[test data patterns]" }
  - { id: coverage, summary: "[targets + how to view]" }
  - { id: test-types, summary: "[unit/integration/e2e]" }
  - { id: common-patterns, summary: "[async/error/snapshot]" }
---

# Testing Patterns

## Test Framework

**Runner:** [Framework + version; config file]

**Assertion Library:** [Library + common matchers]

**Run Commands:**
```bash
[command]   # Run all tests
[command]   # Watch mode
[command]   # Single file
[command]   # Coverage report
```

## Test File Organisation

**Location:** [Pattern: e.g., "*.test.ts alongside source" or "tests/ tree"]

**Naming:** [Unit / integration / e2e naming]

**Structure:**
```
[Real directory pattern from the repo]
```

## Test Structure

**Suite Organisation:**
```[lang]
[Real describe/it pattern used in this repo]
```

**Patterns:** [Setup/teardown conventions; arrange/act/assert]

## Mocking

**Framework:** [Tool + how mocks are declared]

**Patterns:**
```[lang]
[Real mocking snippet from the repo]
```

**What to Mock:** [e.g., "external APIs, filesystem, DB, time"]

**What NOT to Mock:** [e.g., "pure functions, internal logic"]

## Fixtures and Factories

**Test Data:**
```[lang]
[Real factory/fixture pattern]
```

**Location:** [Where fixtures/factories live]

## Coverage

**Requirements:** [Target + enforcement, or "none"]

**View Coverage:**
```bash
[command]
```

## Test Types

**Unit:** [Scope, mocking, speed expectations]

**Integration:** [Scope, setup, test DB?]

**E2E:** [Framework, scope, location]

## Common Patterns

**Async Testing / Error Testing / Snapshots:**
```[lang]
[Real snippets, or "not used"]
```

---

*Testing analysis: [date]. Update when test patterns change.*
```
