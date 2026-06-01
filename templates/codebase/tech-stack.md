# Technology Stack Template

Template for `docs/codebase/TECH-STACK.md` — captures the technology foundation.

**Purpose:** Document what technologies run this codebase. Focused on "what executes when you run the code." Cite the file each fact comes from (`package.json`, lockfile, config) in backticks.

---

## File Template

```markdown
---
schema_version: 1
doc: TECH-STACK
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
sections:
  - { id: languages, summary: "[primary/secondary languages]" }
  - { id: runtime, summary: "[runtime + package manager]" }
  - { id: frameworks, summary: "[core/testing/build frameworks]" }
  - { id: key-dependencies, summary: "[5-10 critical deps]" }
  - { id: configuration, summary: "[env + build config]" }
  - { id: platform-requirements, summary: "[dev/prod platform needs]" }
---

# Technology Stack

## Languages

**Primary:**
- [Language] [Version] — [Where used: e.g., "all application code"]

**Secondary:**
- [Language] [Version] — [Where used: e.g., "build scripts, tooling"]

## Runtime

**Environment:**
- [Runtime] [Version] — [e.g., "Node.js 20.x"] — [source: `path`]

**Package Manager:**
- [Manager] [Version] — [e.g., "npm 10.x"]
- Lockfile: [e.g., `package-lock.json` present]

## Frameworks

**Core:**
- [Framework] [Version] — [Purpose: e.g., "web server", "UI framework"]

**Testing:**
- [Framework] [Version] — [e.g., "Jest for unit tests"]

**Build/Dev:**
- [Tool] [Version] — [e.g., "Vite for bundling"]

## Key Dependencies

[Only the 5-10 dependencies critical to understanding the stack — not the full list.]

**Critical:**
- [Package] [Version] — [Why it matters: e.g., "authentication", "database access"]

**Infrastructure:**
- [Package] [Version] — [e.g., "Express for HTTP routing"]

## Configuration

**Environment:**
- [How configured: e.g., ".env files", "environment variables"]
- [Key configs: e.g., "DATABASE_URL, API_KEY required"] — note names only, never values

**Build:**
- [Build config files: e.g., `vite.config.ts`, `tsconfig.json`]

## Platform Requirements

**Development:**
- [OS requirements or "any platform"]
- [Additional tooling: e.g., "Docker for local DB"]

**Production:**
- [Deployment target: e.g., "Vercel", "AWS Lambda", "Docker container"]

---

*Stack analysis: [date]. Update after major dependency changes.*
```
