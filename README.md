<div align="center">

# baton-kit

**A model-routed working method for [Claude Code](https://claude.com/claude-code):
plan with a strong model, implement with a balanced one, read with a fast one,
and keep every change verified and scoped.**

[![validate](https://github.com/jandrescodes/baton-kit/actions/workflows/validate.yml/badge.svg)](https://github.com/jandrescodes/baton-kit/actions/workflows/validate.yml)
&nbsp;[![plugin](https://img.shields.io/badge/plugin-0.1.0-2f81f7)](./CHANGELOG.md)
&nbsp;![license](https://img.shields.io/badge/license-MIT-blue)

<em>Stack-agnostic. Three subagents, three skills, one command, three hooks. No dependencies beyond bash.</em>

</div>

---

## Why

Out of the box, one model does everything in one context: the most expensive
model reads files it could have skimmed, long searches fill the context you
need for the actual change, and rules written in `CLAUDE.md` are only
suggestions the agent may skip under pressure.

`baton-kit` splits the work by what each model is good at, and moves the
rules that must always hold out of prose and into hooks.

| Problem                                                 | What the plugin does                                                                                                |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| A strong model spends tokens on `grep` and file reading | `reader` runs on a fast model and returns `path:line` evidence only                                                 |
| Implementation starts before anyone agreed on the plan  | `planner` returns one recommendation and verifiable tasks; the method waits for your approval                       |
| "Done" without anything having run                      | The `Stop` hook asks for your verify command when files changed and it hasn't run                                   |
| A commit or push you didn't mean to allow               | `git commit` / `git push` ask for explicit confirmation                                                             |
| Refactors built on unverified `grep` counts             | `refactor-audit` verifies candidates first and records what was rejected                                            |
| Patterns applied by name instead of by need             | `design-patterns` maps a code smell to the smallest fix and says when _not_ to apply it; `planner` has it preloaded |

## Install

```text
/plugin marketplace add jandrescodes/baton-kit
/plugin install baton@baton-kit
```

Update with `/plugin update baton`. To try it from a local clone, use
`/plugin marketplace add /path/to/baton-kit`, or load it for one session
with `claude --plugin-dir ./plugins/baton`.

## How a session looks

Illustrative; exact output varies.

```text
you     › Plan and implement a fix for the crash when divide() gets b = 0.

claude  › [reader · haiku]       maps divide() and its callers          → calc.py:5, app.py:12
          [planner · opus]       proposes one fix + 2 tasks, each with a "done when"
you     › Looks good, go ahead.
claude  › [implementer · sonnet] task 1: guard + test, runs `bash check.sh`  → pass
          [implementer · sonnet] task 2: update caller, runs `bash check.sh` → pass
          Stop hook: verify command ran after the last edit, nothing to add.
          Reports what changed, the verification result, and anything left undone.
```

The `workflow` skill guides this when it applies. To be sure, name an agent
directly (`use the reader agent to find where X is defined`).

## What you get

### Subagents

| Agent         | Model    | Tools                                 | Use it for                                                                                                               |
| ------------- | -------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `reader`      | `haiku`  | Read, Grep, Glob                      | Finding files and answering "where is X / how does Y work", with evidence. Never edits.                                  |
| `planner`     | `opus`   | Read, Grep, Glob, WebFetch, WebSearch | Plans, design decisions and task breakdowns with a verifiable "done when". Has `design-patterns` preloaded. Never edits. |
| `implementer` | `sonnet` | all                                   | Implementing one approved task, then running a real verification. No extras.                                             |

Models are aliases, not IDs, so they don't age. If your plan doesn't include
one, change the `model:` line in the agent file or use `inherit`.

### Skills

- **`workflow`** — when to delegate to which agent, the read → plan → approve →
  implement → verify → report sequence, and the rules that keep it scoped (no
  unrequested extras, no surprise reviewers, no commits without approval).
- **`refactor-audit`** — before refactoring or applying design patterns: verify
  grep-based candidates by reading the code, measure what you can, order the
  work (characterization tests → static analysis → types → patterns) and write
  down what you decided _not_ to do and why.

- **`design-patterns`** — a consultation guide: code smell → smallest fitting pattern →
  when _not_ to apply it (state strings, repeated guards, branching on type, mixed
  layers, scattered queries, third-party APIs…), plus a short list of practices that
  usually pay off more than a pattern. Not a catalog to apply.

### Command

- **`/baton:init [verify command]`** — detects the project's verify command, writes
  `.baton.conf`, and optionally appends the team rules below to `AGENTS.md` or
  `CLAUDE.md`. It never overwrites existing content and never commits.

### Team rules

[`templates/CLAUDE.md`](plugins/baton/templates/CLAUDE.md) is a short, editable set
of universal working agreements (verify before "done", stay in scope, no commits
without approval, check versions at the source, test data with a unique marker).
`/baton:init` offers to add it; copy it by hand if you prefer.

### Hooks

| Event               | What it does                                                                                                                  |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `PreToolUse` (Bash) | `git commit` and `git push` ask for your explicit confirmation. It asks rather than blocks, so commit skills keep working.    |
| `Stop`              | If files were edited (by the session or by a subagent) and your verify command hasn't run since, blocks once and asks for it. |
| `SessionStart`      | Injects a two-line reminder of the method and the project's verify command.                                                   |

## Configure per project

Run **`/baton:init`** in the project. It reads your manifests and documented
gate (`package.json`, `composer.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`,
`go.mod`, `AGENTS.md`…), shows the verify command it found with the evidence,
and writes `.baton.conf` once you approve. Pass a command to skip detection:
`/baton:init npm test`. Commit the file so the whole team shares it.

By hand, create `.baton.conf` at the project root (template:
[`hooks/baton.conf.example`](plugins/baton/hooks/baton.conf.example)):

```text
verify_command=npm test
commit_guard=ask
```

| Key              | Default  | Meaning                                                                                                                                           |
| ---------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `verify_command` | _(none)_ | Command that proves a change works. It must appear verbatim in the Bash call for the `Stop` hook to count it. Without it, that hook does nothing. |
| `commit_guard`   | `ask`    | `ask` requires confirmation for `git commit`/`git push`; `off` disables the guard.                                                                |

The file is parsed as `KEY=VALUE` lines and never executed.

## Planning on a strong model

The plugin routes work through subagents; it does not switch your session's
model. To run the _main_ session on a strong model only while planning, use
`/model opusplan` (strong model in plan mode, balanced one when executing).

## Limits

- Plugin agents ignore `hooks`, `mcpServers` and `permissionMode`. That is why
  hooks live at plugin level. If an agent needs `permissionMode`, copy it to
  `~/.claude/agents/`.
- The `Stop` hook finds edits and the verify command by reading the session and
  subagent transcripts. A different invocation than the configured string won't
  be recognized, and only one `verify_command` is supported.
- The commit guard is a safety net, not a security boundary. It matches the raw
  Bash input, including configured git aliases and `-c alias.*` overrides, without
  parsing shell, so a script that runs `git commit` internally (`make release`)
  is not detected. Your permission rules still apply on top of it.
- The `workflow` skill may not activate on its own for small tasks (it tells the
  model to skip trivial ones). Name the agents or invoke the skill to force it.

## Pairs well with

[`sdd-toolkit`](https://github.com/jandrescodes/sdd-toolkit): a spec-driven flow
(spec → plan → tasks → implement → validate). `planner` writes the plan and
`implementer` takes one task at a time.

## Contributing

Principles and conventions are in [`AGENTS.md`](AGENTS.md). Before sending a
change run:

```bash
claude plugin validate ./plugins/baton --strict
bash tests/validate.sh
bash tests/hooks.sh
```

Release notes live in [`CHANGELOG.md`](CHANGELOG.md).

---

<div align="center">

<sub>[MIT License](LICENSE) · [Changelog](CHANGELOG.md) · Made by [jandrescodes](https://github.com/jandrescodes)</sub>

</div>
