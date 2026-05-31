# Codebase Concerns Template

Template for `docs/codebase/CONCERNS.md` — captures known issues and areas requiring care.

**Purpose:** Surface actionable warnings — "what to watch out for when making changes." Every entry needs a real location, concrete impact, and a remediation path. No vague complaints. Only report what the code actually shows; do not speculate about bugs you cannot point to.

---

## File Template

```markdown
---
schema_version: 1
doc: CONCERNS
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
sections:
  - { id: tech-debt, summary: "[shortcuts + fix approaches]" }
  - { id: known-bugs, summary: "[symptoms + triggers]" }
  - { id: security-considerations, summary: "[risks + mitigations]" }
  - { id: performance-bottlenecks, summary: "[slow ops + causes]" }
  - { id: fragile-areas, summary: "[what breaks easily]" }
  - { id: dependencies-at-risk, summary: "[deprecated/unmaintained deps]" }
  - { id: test-coverage-gaps, summary: "[untested areas + risk]" }
---

# Codebase Concerns

## Tech Debt

**[Area/Component]** — [`path`]:
- Issue: [What's the shortcut/workaround]
- Why: [Why it was done this way, if known]
- Impact: [What breaks or degrades because of it]
- Fix approach: [How to properly address it]

## Known Bugs

**[Bug description]** — [`path` if locatable]:
- Symptoms: [What happens]
- Trigger: [How to reproduce]
- Workaround: [Temporary mitigation if any]
- Root cause: [If known]

## Security Considerations

**[Area requiring security care]** — [`path`]:
- Risk: [What could go wrong]
- Current mitigation: [What's in place now]
- Recommendation: [What should be added]

## Performance Bottlenecks

**[Slow operation/endpoint]** — [`path`]:
- Problem: [What's slow]
- Measurement: [Numbers if measured, else "suspected, unmeasured"]
- Cause: [Why it's slow]
- Improvement path: [How to speed it up]

## Fragile Areas

**[Component/Module]** — [`path`]:
- Why fragile: [What makes it break easily]
- Common failures: [What typically goes wrong]
- Safe modification: [How to change it without breaking]
- Test coverage: [Tested? Gaps?]

## Dependencies at Risk

**[Package/Service]:**
- Risk: [e.g., "deprecated", "unmaintained", "breaking changes coming"]
- Impact: [What breaks if it fails]
- Migration plan: [Alternative or upgrade path]

## Test Coverage Gaps

**[Untested area]** — [`path`]:
- What's not tested: [Specific functionality]
- Risk: [What could break unnoticed]
- Priority: [High/Medium/Low]

---

*Concerns audit: [date]. Update as issues are fixed or new ones discovered.*
```
