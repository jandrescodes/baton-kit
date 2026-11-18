# AGENTS.md — baton-kit

Source of truth for conventions in this repo. `CLAUDE.md` only imports it.

## What this is

A Claude Code marketplace with one plugin, `baton`: subagents routed by
model (`planner` → opus, `implementer` → sonnet, `reader` → haiku), three skills
(`workflow`, `refactor-audit`, `design-patterns`), one command (`/baton:init`), three hooks
(commit confirmation, verification on Stop, session reminder) and a team
`CLAUDE.md` template. Companion to, not part of, `sdd-toolkit`.

## Principles

1. **Stack-agnostic.** No language, framework, or tool is assumed. Anything
   tied to a stack is an optional example, never core.
2. **No personal data.** No names of private repos, clients, vault paths, or
   personal conventions. Personal rules live in each user's own `CLAUDE.md`.
3. **English toolkit.** Prompts, docs, and identifiers are in English; the
   agents must work in whatever language the user writes in.
4. **Model aliases, never IDs.** Use `opus`/`sonnet`/`haiku`/`inherit` so
   nothing ages and each team can swap them (not everyone has Opus).
5. **Enforce, don't just ask.** Rules that must always hold go in hooks;
   prose is for judgment calls. Hooks read the project's commands from
   `.baton.conf` (written by `/baton:init`), never hardcode a stack.
6. **Plugin limits.** Plugin agents ignore `hooks`, `mcpServers`, and
   `permissionMode`; hooks ship at plugin level (`hooks/hooks.json`).
7. **No runtime dependencies.** Hooks are pure bash plus coreutils (no `jq`,
   no `python`); the project config `.baton.conf` is parsed, never sourced.
   Only `tests/validate.sh` may use `python3` (JSON validity check).
8. **Single source.** All editable content lives in `plugins/baton/`.

## Verification

All three must pass before any change is considered done:

```
claude plugin validate ./plugins/baton --strict
bash tests/validate.sh   # structure: JSON, agent/skill frontmatter, hook scripts
bash tests/hooks.sh      # hook behavior against transcript fixtures
```

CI runs the two scripts (the Claude CLI is not available there). A hook test
must be mutation-checked: break the rule on purpose and confirm it fails.

## Releases

Version lives in `plugins/baton/.claude-plugin/plugin.json`; keep it equal to
the README badge and the top `CHANGELOG.md` entry. Tags have no `v` prefix
(`0.1.0`) and are created on `main` only after CI is green.

## Layout

```
assets/icon.png
.claude-plugin/marketplace.json
plugins/baton/{.claude-plugin,agents,skills,commands,hooks,templates}
tests/{validate,hooks}.sh
.github/{workflows/validate.yml,dependabot.yml}
```
