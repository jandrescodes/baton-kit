## Working agreements

<!-- Added by baton-kit. Edit freely; keep what your team agrees with. -->

### Verification

- Before reporting a change as done, run a real check that exercises it: tests,
  type-check, build, or the changed command. A syntax-only check does not count.
- If you could not run one, say which and why. Never report "done" without it.

### Scope

- Do what was asked, then stop and report. Do not add features, tests, files,
  docs, or refactors that were not requested; mention them at the end instead.
- If asked for ideas, options, or a plan, deliver them and wait for a go-ahead.
- Follow the conventions already in the repo over your own preferences.

### Delegation

- Use the `baton` plugin: `reader` for lookups, `planner` for plans,
  `implementer` for approved tasks. Do trivial edits directly.

### Git and releases

- Never commit, push, delete data, or deploy without explicit approval.
- Group commits by area, with the tests that belong to each change.
- Before pinning a dependency, action, or runtime version, check the latest
  stable on the official source; never rely on memory.

### Data and tests

- Create test data with a unique, reserved marker. Before any `DELETE`, run the
  same `SELECT`, review it row by row, and note the count.
- Run CI-relevant checks without local-only config (`.env`, local services) to
  catch "works on my machine".

### Code and docs

- Comments explain _why_ (business rule, invariant, workaround), never _what_.
- When you correct a mistake of convention or architecture, record it in the
  project's `AGENTS.md` before closing the task.
