# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Semantic versioning. The canonical version lives in
`plugins/baton/.claude-plugin/plugin.json`; every release carries a git tag
**without the `v` prefix** (`0.1.0`, `0.2.0`, …).

## [Unreleased]

## [0.2.0] - 2026-11-18

### Fixed

- Hook `Stop`: writing `.baton.conf` (what `/baton:init` does) no longer counts
  as an edit that needs verification, so the hook stops nagging right after
  setup. Edits to any other file, including files with a similar name, still do.

### Changed

- README: "Pairs well with" became "Works with other skills" (commit skills,
  spec-driven flows, skills from other plugins, combined hooks), and a quick
  index sits under the title.

### Added

- `assets/icon.png`, shown at the top of the README.

### Tests

- `tests/hooks.sh` covers the `.baton.conf` case with an input shape captured
  from a real transcript (`file_path` in the tool call), 39 cases in total.

## [0.1.0] - 2026-11-17

First release: a stack-agnostic working method for Claude Code, packaged as one
plugin (`baton`) in its own marketplace (`baton-kit`).

### Added

- Subagents routed by model alias: `reader` (`haiku`, read-only lookups with
  `path:line` evidence), `planner` (`opus`, plans and task breakdowns, never
  edits) and `implementer` (`sonnet`, one approved task plus a real
  verification).
- Skill `workflow`: when to delegate to which agent, the read → plan →
  approve → implement → verify → report sequence, and the rules that keep work
  scoped.
- Skill `design-patterns`: maps a code smell found by reading to the smallest
  fitting pattern, with a "when NOT to apply" column and a short list of
  practices that usually pay off more; preloaded into `planner`.
- Skill `refactor-audit`: turns a grep-based list of refactoring candidates into
  verified findings, orders the work (characterization tests, static analysis,
  types, patterns) and records what was rejected and why.
- Hook `PreToolUse` (Bash): `git commit` and `git push` ask for explicit
  confirmation instead of running silently; disable with `commit_guard=off`.
- Hook `Stop`: when files were edited, by the main session or by a subagent, and
  `verify_command` has not run since, it blocks once and asks for the check.
- Hook `SessionStart`: injects a short reminder of the method and of the
  project's verify command.
- Command `/baton:init [verify command]`: detects the project's verify command
  from its documented gate or manifests, shows the evidence, writes
  `.baton.conf` after approval, and optionally appends the team rules.
- `templates/CLAUDE.md`: a short, editable set of universal team working
  agreements (verification, scope, delegation, git, data, comments).
- Per-project configuration in `.baton.conf` (`verify_command`,
  `commit_guard`), parsed as plain `KEY=VALUE` lines and never executed.
- `tests/validate.sh` (structure) and `tests/hooks.sh` (hook behavior against
  transcript fixtures in the real format), both run by CI.

### Known limits

- Plugin agents ignore `hooks`, `mcpServers` and `permissionMode`; hooks ship
  at plugin level.
- The `Stop` hook recognizes the verify command only when it appears verbatim
  in a Bash call, and supports a single `verify_command`.
- The commit guard matches the raw Bash input (plus configured git aliases and
  `-c alias.*` overrides) without parsing shell: a script that runs `git commit`
  internally is not detected. It is a safety net, not a security boundary.
- The `workflow` skill is not guaranteed to activate on its own for small tasks;
  name the agents or invoke the skill to force the method.

[Unreleased]: https://github.com/jandrescodes/baton-kit/compare/0.2.0...HEAD
[0.2.0]: https://github.com/jandrescodes/baton-kit/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jandrescodes/baton-kit/releases/tag/0.1.0
