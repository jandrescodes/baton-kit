---
name: refactor-audit
description: Use before refactoring or applying design patterns, or when asked to audit a codebase for improvements, find code smells, or prioritize technical debt. Turns a grep-based list of candidates into verified findings, orders the work, and records what was rejected and why.
---

# Refactor audit: verify before you change

A list of candidates built from `grep` or line counts is a lead, not a finding.
In practice about half of such numbers are wrong: vendored libraries counted as
project code, guards of a different kind lumped together, an "N+1" that is dead code.

## 1. Verify each candidate

- Read the actual code. Recount excluding vendored/generated paths.
- Check whether the problem is already handled (a helper, a transition table,
  a constant that plays the role of the pattern you were about to add).
- Confirm it is reachable: dead code is deleted, not refactored.
- Write the corrected figure next to the original so the correction is visible.

## 2. Measure what you can

- For query changes, compare the query plan before and after on realistic data.
  The biggest wins are often not patterns: a function wrapped around an indexed
  column (`DATE(col) = ...`) can turn an index lookup into a scan.
- For performance claims, keep the before/after numbers.

## 3. Order the work

1. Characterization tests around the code you will touch, especially money,
   locks, and state transitions. Prove they bite: break the rule on purpose and
   check a test fails.
2. Static analysis, with a baseline on legacy code so only new errors fail CI.
3. Enums/types and strict typing, in new files first; not a global switch.
4. Design patterns, last and only where a diff shows real duplication.

## 4. Protect the invariants

- A guard that relies on every caller remembering to invoke it is a latent bug.
  Declare it once (middleware, route group, base class) and add a test that
  fails if a protected route or entry point lacks it.

## 5. Record rejections

Output a short list of what was **not** applied and the reason (already covered,
single implementation, freshness required, cost exceeds benefit). A rejected
candidate without a reason gets proposed again next quarter.

## Output

Verified findings (with corrected figures), the ordered plan, and the rejection
list. Stop there; applying the plan is a separate, approved step.
