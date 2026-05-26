---
name: init
description: Bootstrap a project with spec-kit convention. Use when the user wants to start using /spec-kit:* commands in a project that does not yet contain a .specify/ directory, or when any other spec-kit skill reports that .specify/ is missing.
argument-hint: "(optional) target directory; defaults to current project root"
user-invocable: true
disable-model-invocation: false
---

# /spec-kit:init

You are bootstrapping the **spec-kit convention** (`.specify/` directory tree) into the user's current project. The payload is bundled inside this plugin at `${CLAUDE_PLUGIN_ROOT}/assets/specify/` — you do NOT need `uv`, Python, or network access.

## When to run

- The user explicitly invoked `/spec-kit:init`, OR
- Another `/spec-kit:*` skill (specify, plan, tasks, …) detected that `.specify/` does not exist in the project root and asked you to bootstrap first.

## Execution

1. **Detect target directory.** Default to the current working directory (project root). If the user passed an argument, treat it as the target directory.

2. **Check for existing `.specify/`.** If it already exists:
   - Do NOT overwrite by default. Report what is already there.
   - Ask the user whether to (a) keep existing, (b) merge missing files only, (c) overwrite (destructive).

3. **Run the bootstrap helper.** Pick the script that matches the host shell:
   - POSIX (Linux/macOS/Git-Bash): `bash "${CLAUDE_PLUGIN_ROOT}/bin/init-project.sh" "<target>"`
   - PowerShell (Windows): `pwsh -File "${CLAUDE_PLUGIN_ROOT}/bin/init-project.ps1" -TargetDir "<target>"`
   - To overwrite, pass `FORCE=1` (bash) or `-Force` (pwsh).

4. **Verify.** After the script finishes, confirm `<target>/.specify/templates/spec-template.md` exists.

5. **Report.** Tell the user:
   - Which files were copied (count + top-level dirs).
   - That they can now run `/spec-kit:constitution` (recommended first step) or jump straight to `/spec-kit:specify <feature description>`.
   - Optional: project-local customizations go in `.specify/templates/overrides/`.

## Notes

- This skill is **idempotent** when run without force: it will not overwrite an existing `.specify/`.
- The bundled spec-kit version is recorded in `${CLAUDE_PLUGIN_ROOT}/SPECKIT_VERSION`. Mention it in the completion report so the user knows which upstream they are pinned to.
- The git extension (`speckit-git-*` skills) is included in the payload and active via `.specify/extensions.yml` by default. The user can disable hooks by editing that file or setting `enabled: false` per hook.
