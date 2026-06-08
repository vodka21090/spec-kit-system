# JVM reference — Maven, Gradle, Kotlin/Gradle

Covers Java and Kotlin projects. All three resolve **Maven coordinates**
(`groupId:artifactId:version`), so GHSA/OSV lookups use ecosystem `MAVEN` with
the `group:artifact` name regardless of build tool. Detect the build tool from
files present:

- `pom.xml` → Maven
- `build.gradle` → Gradle (Groovy DSL)
- `build.gradle.kts` → Gradle (Kotlin DSL, typical for Kotlin projects)
- `gradle/libs.versions.toml` → Gradle version catalog (versions centralized here)

## Table of contents

1. Inventory (dependency tree)
2. Scan (OWASP dependency-check + GHSA)
3. Triage & fix strategies (direct, managed, transitive constraints)
4. Applying fixes
5. Breaking-change sources
6. Gotchas

## 1. Inventory — the dependency tree

The resolved tree shows transitive deps and the actual versions after conflict
resolution, which is what vulnerabilities attach to.

```bash
# Maven
mvn dependency:tree -Dverbose            # full tree, shows omitted conflicts
mvn dependency:tree -DoutputType=dot     # machine-readable

# Gradle (use the wrapper ./gradlew if present)
./gradlew dependencies --configuration runtimeClasspath
./gradlew :app:dependencyInsight --dependency <group:artifact>  # why a dep/version is present
```

`dependencyInsight` is the key tool for transitive findings — it tells you which
direct dependency drags in the vulnerable version and via which path.

## 2. Scan

Native scanner — **OWASP dependency-check** maps installed coordinates to
CVEs/advisories:

```bash
# Maven plugin
mvn org.owasp:dependency-check-maven:check
#   → target/dependency-check-report.json (and .html)

# Gradle plugin (apply org.owasp.dependencycheck), then:
./gradlew dependencyCheckAnalyze
#   → build/reports/dependency-check-report.json
```

Alternatives if dependency-check isn't set up: `mvn versions:display-dependency-updates`
shows available newer versions (not security-specific), and Gradle's built-in
nothing — so dependency-check or a GHSA pass is needed.

Then confirm every finding against GHSA/OSV with ecosystem `MAVEN` and the
`group:artifact` name (see `references/github-advisory.md`). GHSA gives the
authoritative `firstPatchedVersion`, which dependency-check doesn't always
provide cleanly.

## 3. Triage & fix strategies

- **Direct dependency** — bump the version in `pom.xml` / `build.gradle(.kts)` /
  the version catalog. Crossing minor/major → breaking-change analysis.
- **Managed version** — if the project uses a BOM or `dependencyManagement`
  (Maven) / a platform or `libs.versions.toml` (Gradle), change the version
  *there* so it applies consistently; editing the leaf declaration may be
  overridden by the managed version.
- **Transitive** — the vulnerable coordinate isn't declared directly. Options:
  - Bump the **direct parent** to a release that pulls a fixed child (cleanest).
  - **Force the version** when no parent fix exists:
    - Maven: add the fixed version to `<dependencyManagement>` — it overrides
      transitive resolution project-wide.
    - Gradle: a constraint —
      `implementation('group:artifact') { because 'CVE fix'; version { strictly '1.2.3' } }`
      or a `dependencies.constraints { }` block / `resolutionStrategy.force`.
    Forcing can break the parent if it needs the old API — flag and test.

## 4. Applying fixes

Edit the appropriate file (leaf declaration, `dependencyManagement`/BOM, or
`libs.versions.toml`), then verify resolution and re-tree:

```bash
mvn -q dependency:tree | grep -i <artifact>      # confirm new version resolved
./gradlew dependencyInsight --dependency <group:artifact>

git diff -- pom.xml build.gradle build.gradle.kts gradle/libs.versions.toml \
  > dependency-fixes.patch
```

Gradle has no separate lockfile unless dependency locking is enabled
(`gradle.lockfile`); if it is, run `./gradlew dependencies --write-locks` to
refresh it and include it in the patch.

## 5. Breaking-change sources

- Library release notes / GitHub Releases / migration guides between current and
  target. Major Java libraries (Jackson, Spring, Netty, Guava) publish detailed
  ones.
- **Java/JDK baseline**: a new major may require a newer JDK — check the release
  notes and the project's `maven.compiler.release` / Gradle `sourceCompatibility`.
- **For Kotlin specifically**: watch the library's Kotlin stdlib / coroutines
  compatibility and whether the bump forces a Kotlin version change.
- Grep for usage of changed APIs to gauge real impact:
  `grep -rn "import com.example.pkg" src/`.
- Transitive ripple: a bump may pull newer shared libs (e.g. a Spring bump moving
  Jackson) — re-run the tree and check for newly conflicting versions.

## 6. Gotchas

- "Nearest-wins" (Maven) and "highest-wins" (Gradle) conflict resolution mean the
  version you declare isn't always the one resolved. Always re-check the tree
  after a change.
- A BOM/platform can silently pin a vulnerable transitive version; bumping the
  BOM is sometimes the real fix.
- `provided`/`compileOnly`/`testImplementation` scope affects whether a vuln
  ships to production — factor scope into priority.
- Gradle version catalogs centralize versions; edit `libs.versions.toml`, not the
  `build.gradle.kts` alias, when one is in use.
