# Parity testing after a dependency fix

A security upgrade is "done" only when you've demonstrated that behavior the user
relies on is **unchanged** — that's parity. The risk in a dependency bump isn't
the vulnerability anymore; it's a silent behavior change in the upgraded library.
Parity testing is how you catch that before it ships.

Build the plan in two halves. The automated half proves the obvious things
quickly and repeatably; the manual half targets exactly the surfaces the
breaking-change analysis (SKILL.md stage 4) flagged as risky.

## Automated parity checks

Run these in order; stop and report on the first hard failure.

1. **Clean build** — the project compiles/installs with the new versions.
   - npm: `npm ci && npm run build`
   - Maven: `mvn -q clean verify -DskipTests` (compile first, isolate from tests)
   - Gradle: `./gradlew clean assemble`

2. **Full test suite** — the existing tests are your parity oracle. Same tests,
   new dependencies; a diff in results localizes the impact.
   - npm: `npm test`
   - Maven: `mvn test` (or `verify` for integration tests)
   - Gradle: `./gradlew test`
   Compare pass/fail counts against a pre-upgrade baseline run, not just
   "green/red" — a newly skipped or newly failing test is a parity signal.

3. **Dependency-graph diff** — confirm *only* the intended versions moved and no
   unexpected transitive drift came along.
   - npm: diff `package-lock.json` (or `npm ls --all` before/after)
   - Maven/Gradle: diff `mvn dependency:tree` / `./gradlew dependencies` output
   Unexpected version changes are the most common source of surprise breakage.

4. **Re-scan** — re-run the scanner and GHSA check to confirm the targeted
   finding is gone **and no new finding was introduced** by the upgrade. A fix
   that pulls in a newer-but-also-vulnerable transitive is a real failure mode.

5. **Smoke test the critical path** — start the app / run the main entrypoint and
   exercise the one or two flows that must always work (health endpoint, a core
   API call, the main CLI command). Catches runtime/classpath issues that compile
   and unit tests miss (e.g. a removed class only hit at runtime).

If the project has thin test coverage, say so — automated parity is only as
strong as the suite, and that raises the weight of the manual checklist.

## Manual parity checklist

Derive this directly from stage-4 breaking-change findings. For each changed API
or behavior the project actually uses, write a concrete, checkable item — what to
do and what the expected (unchanged) result is. Generic "test the app" items get
skipped; specific ones get done.

Good manual items look like:

- "Upload a >10 MB file on the Documents page — should still succeed (multer was
  bumped 1.x→2.x; default limits changed in 2.0)."
- "Hit `POST /api/orders` with a nested JSON body — response shape unchanged
  (jackson-databind 2.13→2.16; check no field is now omitted/renamed)."
- "Run the nightly export job against a date range — CSV output byte-identical to
  baseline (date library upgrade; default formatting can shift)."

Structure each item as: **action → expected unchanged result → why it's at risk
(which upgrade)**. Tie every item back to a specific package bump so the user
knows it's not busywork.

## Recording the result

In the report, present parity testing as a table the user can check off:

| Check | Type | Command / steps | Expected | Status |
| --- | --- | --- | --- | --- |
| Build | auto | `npm ci && npm run build` | exit 0 | ☐ |
| Test suite | auto | `npm test` | same pass count as baseline | ☐ |
| Dep diff | auto | lockfile diff | only intended versions changed | ☐ |
| Re-scan | auto | `npm audit` + GHSA | target finding gone, no new ones | ☐ |
| Smoke | auto | start app, hit `/health` | 200 OK | ☐ |
| File upload >10MB | manual | Documents page | succeeds | ☐ |

Leave the status column unchecked — these are for the user (or CI) to run. Where
you were able to run a check yourself, fill in the actual result.
