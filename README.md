# spec-kit (Claude Code Plugin)

A portable repackaging of [github/spec-kit](https://github.com/github/spec-kit) (v0.8.13) as an installable Claude Code plugin. Brings the full Spec-Driven Development (SDD) workflow — `specify → clarify → plan → tasks → analyze → implement` — into Claude Code with **zero Python/uv dependency at install time**.

## Why this plugin

`github/spec-kit` is excellent but ships as a Python CLI (`specify`) that requires `uv` + Python 3.11+ on every machine where it is initialized. This plugin vendors the artifacts that `specify init` produces (`.specify/` templates, scripts, memory, extensions, workflows) and exposes the workflow as namespaced Claude Code skills (`/spec-kit:specify`, `/spec-kit:plan`, …). End users only need Claude Code.

The plugin follows upstream's convention exactly — after `/spec-kit:init`, your project layout is indistinguishable from one created by `specify init`. Your project remains 100% interoperable with the upstream CLI if you ever want to switch back.

## Install

### From a local clone (development / personal use)

```bash
git clone https://github.com/vodka21090/spec-kit-system.git
claude --plugin-dir ./spec-kit-system
```

### From a marketplace (planned)

```text
/plugin marketplace add vodka21090/spec-kit-system
/plugin install spec-kit@spec-kit-system
```

## Usage

### 1. Bootstrap a project (one-time)

```text
/spec-kit:init
```

Copies `.specify/` (templates, scripts, memory, extensions, workflows) into the current project. Idempotent — won't overwrite an existing `.specify/`.

### 2. Run the SDD cycle

```text
/spec-kit:constitution           # (optional) seed project principles
/spec-kit:specify add user authentication with OAuth2 and session management
/spec-kit:clarify                # (optional) resolve [NEEDS CLARIFICATION] markers
/spec-kit:plan
/spec-kit:tasks
/spec-kit:analyze                # (optional) cross-artifact consistency check
/spec-kit:implement
```

Outputs land in `specs/<NNN>-<short-name>/{spec,plan,tasks}.md` exactly like upstream.

### 3. Optional extensions

- `/spec-kit:checklist` — custom quality checklist per feature
- `/spec-kit:taskstoissues` — convert `tasks.md` into GitHub issues
- `/spec-kit:git-feature` — create feature branch with sequential/timestamp numbering
- `/spec-kit:git-commit` — auto-commit between SDD phases
- `/spec-kit:git-initialize`, `/spec-kit:git-remote`, `/spec-kit:git-validate`

Hook wiring lives in `.specify/extensions.yml` (the upstream registry) — edit there to enable/disable per phase.

## Layout

```
spec-kit-system/
├── .claude-plugin/plugin.json    Plugin manifest
├── SPECKIT_VERSION               Pinned upstream version (0.8.13)
├── skills/                       15 skills (14 vendored from upstream + init)
│   ├── init/                     Bootstrap .specify/ into a project (new)
│   ├── constitution/  specify/  clarify/  plan/  tasks/
│   ├── analyze/  implement/  checklist/  taskstoissues/
│   └── git-{commit,feature,initialize,remote,validate}/
├── assets/specify/               Bootstrap payload — mirrors `.specify/` exactly
│   ├── templates/  scripts/{bash,powershell}/  memory/
│   ├── extensions/git/  extensions.yml
│   ├── workflows/  integrations/
│   └── init-options.json  integration.json
└── bin/
    ├── init-project.sh           Bootstrap helper (POSIX)
    └── init-project.ps1          Bootstrap helper (Windows)
```

## Differences from upstream

| Aspect | Upstream `github/spec-kit` | This plugin |
|---|---|---|
| Install | `uv tool install specify-cli` (Python 3.11+) | `/plugin install` (no runtime deps) |
| Bootstrap | `specify init <dir>` (CLI) | `/spec-kit:init` (in-session) |
| Skill names | `/speckit-specify` (per-agent flat) | `/spec-kit:specify` (Claude Code namespace) |
| Hook command rule | `speckit.git.commit` → `/speckit-git-commit` | `speckit.git.commit` → `/spec-kit:git-commit` |
| Project layout after init | `.specify/`, `specs/` | `.specify/`, `specs/` — **identical** |
| Templates, scripts, hooks logic | Source of truth | Vendored verbatim — semantics unchanged |

## Sync upstream

When `github/spec-kit` releases a new version:

```bash
# 1. Re-init into a temp dir to harvest fresh artifacts
uv tool run --from git+https://github.com/github/spec-kit.git specify init /tmp/probe --here

# 2. Replace assets/specify/ wholesale
rm -rf assets/specify && cp -r /tmp/probe/.specify assets/specify

# 3. Replace skills/ from /tmp/probe/.claude/skills (re-run the rename + sed pipeline)
# 4. Bump SPECKIT_VERSION and .claude-plugin/plugin.json's metadata.speckit_upstream
```

A `bin/sync-upstream.sh` automating this is a TODO for v0.2.

## License

MIT. Upstream spec-kit content (vendored in `assets/specify/` and `skills/`) belongs to GitHub Inc. and is redistributed under spec-kit's MIT license. See `assets/specify/integrations/speckit.manifest.json` for the SHA hashes of the upstream payload pinned to version 0.8.13.

## Credits

- [github/spec-kit](https://github.com/github/spec-kit) — the underlying SDD methodology and all workflow content.
- Claude Code plugin format — Anthropic.
