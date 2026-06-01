# Codebase Map — Index Template

Template for `docs/codebase/README.md` — the human entry point into the codebase map.

**Purpose:** Give a new developer (or an AI agent) a single landing page that summarises the project in one paragraph and links to the seven detailed documents. Keep it short: this is a table of contents, not a duplicate of the other docs.

---

## File Template

```markdown
---
schema_version: 1
doc: README
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
modules: [list, the, top-level, modules]
entry_points: [path/to/main, path/to/other-entry]
docs: [ARCHITECTURE, TECH-STACK, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS]
sections:
  - { id: what-this-is, summary: "[one-paragraph project description]" }
  - { id: documents, summary: "[table of the 7 detail docs]" }
  - { id: start-here, summary: "[first-day orientation bullets]" }
---

# Codebase Map

## What this is

[One or two paragraphs: what this project does, who it's for, and the single
most important thing a newcomer must understand before touching the code.
Plain language. No jargon dump.]

## Documents

| Document | Read it to understand |
|----------|-----------------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | How the code is organised conceptually — layers, data flow, key abstractions |
| [TECH-STACK.md](TECH-STACK.md) | Languages, runtime, frameworks, and critical dependencies |
| [STRUCTURE.md](STRUCTURE.md) | Where things physically live and where to add new code |
| [CONVENTIONS.md](CONVENTIONS.md) | How code is written here — naming, style, patterns to match |
| [TESTING.md](TESTING.md) | How tests are written and run |
| [INTEGRATIONS.md](INTEGRATIONS.md) | External services, APIs, and storage this code depends on |
| [CONCERNS.md](CONCERNS.md) | Tech debt, known bugs, fragile areas — what to watch out for |

## Start here

[3-5 bullet "first day" orientation:
- Entry point: `path/to/main` — what runs first
- Run it locally: `command`
- Run the tests: `command`
- The one directory that matters most: `path/`
- The one gotcha that bites everyone: see CONCERNS.md]

---

*Codebase map: [date]. Regenerate with `/spec-kit:map-codebase` after major changes.*
```
