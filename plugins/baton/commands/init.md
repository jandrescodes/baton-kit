---
description: Set up baton-kit in this project - find the verify command, create .baton.conf, and optionally add the team CLAUDE.md rules.
argument-hint: "[verify command]"
---

Set up the `baton` plugin for the project in the current directory.

Argument: `$ARGUMENTS` (an explicit verify command, optional).

## 1. Find the verify command

If an argument was given, that is the verify command: skip detection.

Otherwise detect it from evidence, in this order, and stop at the first hit:

1. A verification gate the project already documents (`AGENTS.md`, `CLAUDE.md`,
   `CONTRIBUTING.md`, `README.md`: sections named Verification, Testing, Checks,
   or "before committing").
2. The project's own manifests:
   - `package.json` → the `test` script, run with the package manager the lockfile implies
   - `composer.json` or `phpunit.xml*` → the project's PHPUnit/Pest invocation
   - `Makefile` → a `test` or `check` target
   - `pyproject.toml`, `pytest.ini`, `tox.ini` → `pytest` as configured
   - `Cargo.toml` → `cargo test`; `go.mod` → `go test ./...`
   - a CI workflow's test step, if none of the above exists

Read the files; never guess a command that no file supports. If nothing is
found, say so and ask the user for the command.

Prefer one command that exercises the whole change. The `Stop` hook supports a
single `verify_command` and only recognizes it when the Bash call contains it
verbatim, so write it exactly as it will be run. If the project documents
several required commands, pick the main one and tell the user about the rest.

## 2. Create `.baton.conf`

- If `.baton.conf` already exists, show it and ask before changing anything.
- Without an explicit argument, show the proposed file and the evidence for it
  (which file and line) and **wait for approval** before writing.
- File content (the file is parsed as `KEY=VALUE` lines, never executed):

```text
verify_command=<command>
commit_guard=ask
```

This file holds no secrets and is meant to be committed so the whole team shares it.

## 3. Offer the team rules (optional)

The plugin ships a short set of universal rules at
`${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md`. Ask whether to add them:

- If the project has an `AGENTS.md`, offer to append them there.
- Otherwise offer to append them to `CLAUDE.md`, or create it.
- Never overwrite existing content; show the exact text to be added and wait for a yes.

## 4. Report

State the verify command and where it came from, whether the rules were added,
and that nothing else was changed. Do not commit.
