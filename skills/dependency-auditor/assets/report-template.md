# Dependency Audit Report — {{project}}

_Generated {{date}} · Ecosystems audited: {{ecosystems}}_

## Summary

{{One paragraph: total findings by severity, how many this patch fixes, what
remains, and the single most important takeaway.}}

| Severity | Found | Fixed by this patch | Remaining |
| --- | --- | --- | --- |
| Critical | 0 | 0 | 0 |
| High | 0 | 0 | 0 |
| Moderate | 0 | 0 | 0 |
| Low | 0 | 0 | 0 |

## Findings & remediation

For each finding:

### {{package}} {{current_version}} — {{GHSA-id}} ({{CVE}}) · {{severity}}

- **What:** {{one-line description of the vulnerability + CWE}}
- **Path:** {{direct, or "transitive via <parent>"}}  ·  **Scope:** {{prod / dev}}
- **Vulnerable range:** {{range}}  ·  **First patched:** {{version}}
- **Fixability:** {{trivially fixable / minor bump / major bump / transitive
  override / no fix available}}
- **Breaking-change analysis:** {{semver jump; specific removed/changed APIs;
  whether this codebase uses them, with file:line evidence; runtime/engine bumps;
  transitive ripple. State "none expected" only after checking.}}
- **Recommendation:** {{the specific action and why; risk level}}

_(Repeat per finding, ordered by severity × ease of fix.)_

## Applied changes

{{What was edited and how the lockfile/tree was regenerated. The full diff is in
`dependency-fixes.patch`.}}

## Parity test plan

| Check | Type | Command / steps | Expected | Status |
| --- | --- | --- | --- | --- |
| Build | auto | {{cmd}} | exit 0 | ☐ |
| Test suite | auto | {{cmd}} | same pass count as baseline | ☐ |
| Dependency diff | auto | {{cmd}} | only intended versions changed | ☐ |
| Re-scan | auto | {{cmd}} | target findings gone, no new ones | ☐ |
| Smoke test | auto | {{steps}} | {{expected}} | ☐ |
| {{manual item}} | manual | {{steps}} | {{unchanged result}} | ☐ |

## Residual risk / follow-ups

{{Findings with no fix yet and their mitigations; optional larger upgrades
deferred; anything the user should track.}}
