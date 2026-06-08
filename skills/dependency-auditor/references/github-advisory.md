# Querying the GitHub Advisory Database (GHSA)

The GitHub Advisory Database is the authoritative source for this skill. Native
scanners are a fast first pass, but GHSA gives the canonical affected-version
ranges, the first patched version, severity (CVSS v3/v4), and the CWE. Always
confirm a finding's vulnerable range and fix version against GHSA before
proposing a remediation.

## Table of contents

1. Three ways to query
2. GraphQL (richest — preferred for batch lookups)
3. REST (simple per-advisory or list)
4. `osv.dev` fallback (no auth)
5. Reading a result: the fields that matter
6. Authentication notes

## 1. Three ways to query

- **GraphQL `securityVulnerabilities`** — best when you have a package name and
  want every advisory plus the first patched version, in one call. Requires a
  token.
- **REST `/advisories`** — simple, good for fetching a single GHSA by ID or
  listing by ecosystem/severity. A token raises the rate limit but isn't strictly
  required for the global endpoint.
- **OSV (`api.osv.dev`)** — no authentication, aggregates GHSA + others. Useful
  fallback when no GitHub token is available. Query by package + version and it
  tells you directly whether that version is affected.

Check for a token first: `echo "$GITHUB_TOKEN"` or `gh auth token`. If `gh` (the
GitHub CLI) is installed and authenticated, prefer `gh api` — it handles auth for
you.

## 2. GraphQL (preferred)

The `ecosystem` enum values are `NPM` and `MAVEN` (Maven covers Gradle and
Kotlin/Gradle too — they all resolve Maven coordinates). Use the package name as
the `package` argument (for Maven, the `groupId:artifactId` coordinate).

```bash
gh api graphql -f query='
query($ecosystem: SecurityAdvisoryEcosystem!, $package: String!) {
  securityVulnerabilities(ecosystem: $ecosystem, package: $package, first: 100) {
    nodes {
      severity
      vulnerableVersionRange
      firstPatchedVersion { identifier }
      package { name ecosystem }
      advisory {
        ghsaId
        summary
        cvss { score }
        identifiers { type value }   # includes the CVE
        references { url }
      }
    }
  }
}' -F ecosystem=NPM -F package=lodash
```

For Maven, pass the full coordinate:

```bash
gh api graphql -f query='...same query...' \
  -F ecosystem=MAVEN -F package='com.fasterxml.jackson.core:jackson-databind'
```

Without `gh`, POST to `https://api.github.com/graphql` with
`Authorization: bearer $GITHUB_TOKEN`.

## 3. REST

Fetch one advisory by ID:

```bash
gh api /advisories/GHSA-xxxx-xxxx-xxxx
# or:  curl -s https://api.github.com/advisories/GHSA-xxxx-xxxx-xxxx
```

List advisories affecting a package:

```bash
gh api '/advisories?ecosystem=npm&affects=lodash&per_page=100'
```

The REST advisory object includes `vulnerabilities[]` with
`package.name`, `vulnerable_version_range`, and
`first_patched_version.identifier` — the same fields you need from GraphQL.

## 4. OSV fallback (no auth)

When there's no token, OSV is the most reliable unauthenticated route and it
answers the precise question "is *this* version affected?":

```bash
curl -s https://api.osv.dev/v1/query -d '{
  "version": "4.17.20",
  "package": { "name": "lodash", "ecosystem": "npm" }
}'
```

For Maven set `"ecosystem": "Maven"` and `"name": "groupId:artifactId"`. A
non-empty `vulns[]` means that version is affected; each entry's
`affected[].ranges` and `affected[].database_specific` point at the fixed
version. OSV records carry their GHSA IDs in the `aliases` field, so you can map
back to the GitHub advisory.

A helper that batches version-aware OSV lookups is bundled at
`scripts/query_advisories.py` — hand it a list of `name@version` (npm) or
`group:artifact:version` (Maven) and it returns normalized findings as JSON.

## 5. Reading a result: fields that matter

For each advisory, extract and carry forward:

- **GHSA ID + CVE** — for the report and for the user to look up.
- **Severity + CVSS score** — drives prioritization, but combine with
  reachability (see SKILL.md principles).
- **`vulnerableVersionRange`** — e.g. `>= 4.0.0, < 4.17.21`. Check the project's
  resolved version against this; if it's inside the range, it's affected.
- **`firstPatchedVersion`** — the minimum version that closes it. This is the
  upgrade target. If null/absent, **no fix is published yet** — route to the "no
  fix available" bucket and document a mitigation.
- **CWE** — the weakness class (e.g. prototype pollution, deserialization). Helps
  judge reachability and what to test after the fix.

## 6. Authentication notes

- The global advisory endpoints are public; a token mainly raises rate limits and
  is required for GraphQL.
- If the user wants their *own repo's* Dependabot alerts (which factor in
  reachability and their manifest), that needs a token with `security_events` /
  repo scope:
  `gh api /repos/{owner}/{repo}/dependabot/alerts`. This is the best signal when
  available because it's already scoped to their dependency graph.
