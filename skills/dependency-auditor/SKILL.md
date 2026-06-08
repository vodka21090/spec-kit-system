---
name: dependency-auditor
description: >-
  Audit project dependencies for known security vulnerabilities, decide which
  ones are actually fixable, analyze the breaking changes an upgrade would
  introduce, propose a concrete remediation, apply it as a reviewable patch, and
  lay out the parity tests (automated + manual) to run afterward. Covers
  JavaScript/TypeScript (npm, yarn, pnpm) and the JVM stack (Maven, Gradle,
  Kotlin/Gradle). Uses the GitHub Advisory Database (GHSA) as the source of truth
  for advisories and cross-checks native scanners (npm audit, OWASP
  dependency-check). USE THIS SKILL whenever the user mentions vulnerabilities,
  CVEs, GHSAs, "npm audit", "dependabot", security alerts, "out-of-date /
  vulnerable dependencies", upgrading a package to fix a security issue, supply
  chain risk, or asks "is it safe to bump X?" — even if they don't say the word
  "audit". Prefer this skill over an ad-hoc `npm audit fix` because the value is
  in the triage, breaking-change analysis, and the test plan, not just running a
  command.
---

# Dependency Auditor

## What this skill is for

Running a scanner is the easy part. The hard part — and where this skill earns
its keep — is the judgment around the results:

- **Which findings are real and reachable**, versus noise (dev-only, not in the
  vulnerable code path, no fix available yet).
- **Which are actually fixable today**, and at what cost: a patch bump inside the
  existing range, a major version jump with breaking changes, or a transitive
  pin/override.
- **What breaks if you apply the fix**, so the user upgrades with eyes open
  instead of discovering it in production.
- **How to prove the fix is safe** through parity tests — confirming behavior is
  unchanged where it should be — both automated and manual.

The goal is a remediation the user can trust and merge, not a green audit score.

## Supported ecosystems

This skill targets two stacks. Detect which one(s) apply from the manifest files
present, then read the matching reference:

| Stack | Manifests | Reference to read |
| --- | --- | --- |
| JavaScript / TypeScript | `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | `references/npm.md` |
| JVM — Maven / Gradle / Kotlin | `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle(.kts)`, `*.versions.toml` | `references/jvm.md` |

A repo may contain both (e.g. a Spring backend with a JS frontend). Audit each
independently and combine the findings in one report.

Always read `references/github-advisory.md` for how to query the GitHub Advisory
Database, and `references/parity-testing.md` for the post-fix test methodology.
Read them when you reach those stages — don't preload everything.

## The workflow

Work through these stages in order. Announce the stage you're on so the user can
follow along, but keep narration tight.

### 1. Inventory

Establish the ground truth before scanning:

- Identify every manifest and lockfile (see table above). The lockfile matters —
  it pins the *actual resolved* versions, including transitive dependencies,
  which is what vulnerabilities attach to.
- Note whether a lockfile exists. Without one, resolved versions are ambiguous
  and you can only reason about declared ranges; flag this.
- Distinguish **direct** dependencies (declared in the manifest) from
  **transitive** ones (pulled in by a direct dependency). The fix strategy
  differs sharply between the two, so this distinction drives everything later.
- Separate production from dev/test dependencies. A vulnerability in a build-only
  tool is real but lower urgency than one shipped to users.

### 2. Scan and enrich

Two complementary sources, used together:

- **Native scanners** are fast and ecosystem-aware. Run them first to get a
  candidate list (`npm audit --json`, OWASP dependency-check, etc. — see the
  ecosystem reference for exact commands and how to parse output).
- **GitHub Advisory Database (GHSA)** is the source of truth. Native scanners can
  lag, report differently, or miss advisories; GHSA gives you the authoritative
  affected-version ranges, the first patched version, severity (CVSS), and the
  CWE. For every candidate finding, look it up in GHSA to confirm the affected
  range and the exact fixed version. See `references/github-advisory.md`.

Resolve each finding to a normalized record: package, current version, advisory
ID (GHSA + CVE), severity, vulnerable range, first patched version, direct or
transitive, and the dependency path (which direct dep pulls it in).

### 3. Triage fixability

For each finding, classify it. This is the analytical core — be explicit about
which bucket each finding lands in and why:

- **Trivially fixable** — a patched version exists *within the currently declared
  semver range*. The lockfile just needs to advance. Lowest risk.
- **Fixable with a minor/major bump** — a patched version exists but requires
  raising the declared version, crossing a minor or major boundary. Risk rises
  with the size of the jump; this is where breaking-change analysis matters.
- **Transitive-only** — the vulnerable package isn't declared directly. Options:
  bump the parent that pulls it in (preferred, if the parent's newer release
  pulls a fixed child), or force the resolved version with an override
  (`overrides` / `resolutions` for npm, a constraint or `dependencyManagement`
  for JVM). Overrides are powerful but can create incompatibilities — note that.
- **No fix available** — no patched version published yet. Don't pretend
  otherwise. Document the mitigation path: is the vulnerable code reachable in
  this project? Is there a config workaround, a feature that can be disabled, or
  a network-level control? Recommend tracking the advisory for a patch.
- **Won't fix / not applicable** — dev-only and not in the threat model, or the
  vulnerable function is provably unused. Justify the call; don't hand-wave.

### 4. Analyze breaking changes

For every fix that crosses a minor or major version boundary, do the homework so
the user isn't surprised:

- **Read the semver delta.** A major bump (`2.x → 3.x`) signals intentional
  breaking changes by convention; a minor bump *shouldn't* break but sometimes
  does. State the jump explicitly.
- **Find the evidence.** Consult the package's CHANGELOG, release notes, or
  migration guide between the current and target version. Call out removed/renamed
  APIs, changed defaults, raised runtime/engine requirements (e.g. a new minimum
  Node or JDK), and peer-dependency changes.
- **Map it to this codebase.** A breaking change only matters if the project uses
  the affected API. Grep the codebase for usage of the changed surface and report
  concrete hit locations, not just "this version has breaking changes." This
  turns an abstract risk into a specific, checkable list.
- **Watch the ripple.** Upgrading one package can force peer dependencies or
  shared transitive versions to move. Note any second-order upgrades the fix
  drags in.

If a safe fix and a breaking fix both exist, prefer the smallest change that
closes the vulnerability, and surface the larger upgrade as an optional follow-up.

### 5. Propose remediation

For each finding, recommend a specific action with its rationale and risk level.
Order by severity × ease (knock out high-severity easy wins first). Be honest
when the right move is "don't upgrade yet, mitigate instead."

### 6. Apply and produce a reviewable patch

Apply the agreed fixes to manifests and lockfiles, **and** generate a reviewable
diff so the change can go through normal PR review:

- Make the edits (bump versions, add overrides/resolutions/constraints,
  regenerate the lockfile via the ecosystem's command — see the reference).
- Produce a unified diff of every changed file (`git diff`, or a hand-built diff
  if the repo isn't a git checkout) and save it as a `.patch` artifact alongside
  the report so a reviewer can read exactly what changed before merging.
- Keep unrelated changes out of the diff. A focused security patch is far easier
  to review and to roll back.

If the user asked you not to modify files, skip the edit and deliver only the
patch + report for them to apply.

### 7. Parity testing

A security bump is only done when you've shown it didn't change behavior it
shouldn't have. Read `references/parity-testing.md` and produce a concrete test
plan with two halves:

- **Automated** — build, full test suite, lockfile/dependency-tree diff,
  re-running the scanner to confirm the finding is gone and no new one appeared,
  and a smoke test of the critical path. Give the exact commands for the stack.
- **Manual** — a short, targeted checklist derived from the breaking-change
  analysis in stage 4: exactly which features/flows a human should click through,
  because they touch the upgraded package's changed surface.

The manual checklist should be specific to what changed, not a generic "test the
app." That specificity is what makes it actually get done.

## Output

Produce all three:

1. **A chat summary** — the headline: how many findings by severity, how many are
   fixed by this patch, what (if anything) still needs attention, and the single
   most important thing to know. Lead with this.
2. **A remediation report** (`dependency-audit-report.md`) — the full findings
   table, per-finding triage and breaking-change analysis, the remediation
   decisions, and the parity test plan. Use the template in
   `assets/report-template.md`.
3. **A patch** (`dependency-fixes.patch`) — the reviewable diff of applied fixes.

## Principles

- **Never silently auto-fix.** `npm audit fix --force` and friends can quietly
  introduce major-version breaks. Surface the breaking-change analysis and let the
  decision be informed.
- **Severity is necessary but not sufficient.** A critical CVE in an unreachable
  dev dependency may be lower priority than a high-severity one in the request
  path. Reason about reachability, not just the CVSS number.
- **Be honest about residual risk.** If a finding has no fix, say so plainly and
  give the mitigation, rather than burying it.
