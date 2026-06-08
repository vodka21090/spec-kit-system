# npm / yarn / pnpm reference

Covers JavaScript/TypeScript projects. Detect the package manager from the
lockfile: `package-lock.json` → npm, `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm.
Use the matching commands; mixing them corrupts the lockfile.

## Table of contents

1. Inventory
2. Scan
3. Triage & fix strategies (direct, range, transitive overrides)
4. Applying fixes & regenerating the lockfile
5. Breaking-change sources
6. Gotchas

## 1. Inventory

```bash
# Resolved tree (what's actually installed — vulns attach to these versions)
npm ls --all --json                 # npm
yarn list --json                    # yarn classic
pnpm list --depth Infinity --json   # pnpm

# Production-only view, to separate shipped code from build/test tooling
npm ls --all --omit=dev --json
```

`package.json` declares ranges (`^4.17.0`); the lockfile pins the resolved
version. Always reason about the **resolved** version for vulnerability matching,
and the **declared range** for whether a fix is "in-range."

## 2. Scan

```bash
npm audit --json          # npm — parses cleanly; see structure below
yarn npm audit --json     # yarn berry
pnpm audit --json         # pnpm
```

`npm audit --json` returns a `vulnerabilities` object keyed by package name; each
has `severity`, `via` (the advisory or the parent that introduces it), `range`
(vulnerable range), `nodes` (paths), `fixAvailable` (false, true, or an object
describing a breaking fix). Treat `fixAvailable` as a *hint*, then confirm the
real fixed version against GHSA — npm's notion of "fix available" can mean a
major bump it labels breaking.

Always cross-check against GHSA / OSV (see `references/github-advisory.md`);
`npm audit` uses the GitHub Advisory data but can present ranges differently and
occasionally lags.

## 3. Triage & fix strategies

- **In-range patch** — fixed version satisfies the existing declared range. Just
  refresh the lockfile (`npm update <pkg>`). Lowest risk.
- **Out-of-range bump** — raise the version in `package.json`, then reinstall.
  Crosses semver boundaries → do the breaking-change analysis.
- **Transitive** — the vulnerable package isn't in `package.json`. Two routes:
  - Bump the **direct parent** if its newer release pulls a fixed child
    (cleaner, keeps you on supported combinations).
  - **Force the resolved version** when no parent fix exists yet:
    - npm: `"overrides": { "vulnerable-pkg": "1.2.3" }` in `package.json`.
    - yarn: `"resolutions": { "vulnerable-pkg": "1.2.3" }`.
    - pnpm: `"pnpm": { "overrides": { "vulnerable-pkg": "1.2.3" } }`.
    Overrides can break the parent if it relied on the old version — flag this and
    test.

## 4. Applying fixes & regenerating the lockfile

```bash
# Targeted, in-range refresh (preferred — minimal change)
npm update <pkg> --save

# Explicit version bump
npm install <pkg>@<version> --save

# Last resort, and never blindly: this can apply major bumps
npm audit fix            # safe-ish (semver-compatible only)
npm audit fix --force    # AVOID without breaking-change review — applies majors
```

After edits, ensure the lockfile is regenerated (`npm install`) so resolved
versions are consistent, then produce the diff:

```bash
git diff -- package.json package-lock.json > dependency-fixes.patch
```

## 5. Breaking-change sources

- The package's `CHANGELOG.md` / GitHub Releases between current and target.
- `npm view <pkg> versions` and `npm view <pkg>@<version> engines` for runtime
  (Node) requirement bumps.
- `npm view <pkg>@<version> peerDependencies` for peer constraints that may force
  other upgrades.
- Grep the codebase for imports/usage of the package to see whether changed APIs
  are actually used: `grep -rn "from '<pkg>'" src/` and `require('<pkg>')`.

## 6. Gotchas

- `npm audit` reports against the lockfile; no lockfile → run `npm install` first
  or audit is meaningless.
- Monorepos/workspaces: audit at the root but fixes may belong to a specific
  workspace's `package.json`.
- A single advisory can appear via multiple paths; fixing the shared resolved
  version usually clears all paths at once.
- Dev-only vulnerabilities (`--omit=dev` makes them disappear) are real but lower
  priority — note the distinction rather than dropping them.
