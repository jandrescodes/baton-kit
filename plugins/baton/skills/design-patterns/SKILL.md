---
name: design-patterns
description: Use when planning, reviewing or refactoring code structure - to map a concrete code smell (repeated guards, state strings, branching on type, mixed layers, scattered queries) to the smallest fitting design pattern or practice, and to check when NOT to apply it. A consultation guide, not a catalog to apply.
---

# Design patterns: from smell to the smallest fix

A pattern is justified by a **smell found by reading the code**, never by the
pattern's name. Start from the smell, take the smallest change that removes it,
and read the "do not" column before proposing anything. If the "do not"
condition holds, the right answer is usually to change nothing and say why.

## Smell → pattern → when NOT to apply

| Smell (found by reading)                                                                | Consider                                                                                              | Do NOT when                                                                                                                                             |
| --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The same state/status strings compared in many places                                   | A single enum/constants set plus one transition table                                                 | Behavior (not just labels) doesn't differ per state: then a State object is overkill. If a transition table already exists, it already plays that role. |
| The same guard (auth, role, validation) pasted at the start of many handlers            | Middleware, route group or policy declared once, plus a test that fails if a protected route lacks it | Only 2-3 call sites and no risk of forgetting one.                                                                                                      |
| `if/else` or `switch` on a type picks an algorithm, repeated in several places          | Strategy / polymorphism                                                                               | One implementation, or the branch lives in a single place.                                                                                              |
| Several flows share a skeleton and differ in a few steps (reports, exports, dashboards) | Template Method, or composition with a hook                                                           | Only two flows and they are likely to diverge.                                                                                                          |
| Object construction hidden behind conditionals scattered around                         | Factory function                                                                                      | The constructor is simple and called from one place.                                                                                                    |
| HTTP handling, business rules and SQL mixed in one handler                              | A service or domain class with pure logic, testable without I/O                                       | The handler is a few lines.                                                                                                                             |
| Several side effects follow one event (mail, audit, cache)                              | Observer / events                                                                                     | There is a single listener; call it directly.                                                                                                           |
| The same queries duplicated across the code                                             | A query object or repository                                                                          | The model/ORM already centralizes them, or there is one store and no plan to change it.                                                                 |
| A third-party API called directly from many places                                      | Adapter behind a small interface                                                                      | One provider, no plan to swap it, and tests don't need to fake it.                                                                                      |
| Cross-cutting wrapping (transaction, lock, logging) copy-pasted around operations       | Execute-around helper, decorator or middleware                                                        | It happens once.                                                                                                                                        |
| Collaborators created inline make a class hard to test                                  | Constructor injection                                                                                 | A DI container only when the dependency graph is genuinely large.                                                                                       |
| Money, ids or dates passed around as raw numbers/strings                                | A value object                                                                                        | The value is never operated on or validated.                                                                                                            |
| The same validation rules rewritten per endpoint                                        | One validation object at the boundary                                                                 | A single endpoint.                                                                                                                                      |

## Practices that usually pay off more than a pattern

- Validate at the boundary; keep multi-step writes in one transaction and
  validate before opening it.
- Prefer atomic updates (`UPDATE ... WHERE stock >= n`) over read-modify-write.
- Make retried or double-submitted actions idempotent.
- Use soft delete for rows other tables reference.
- Never wrap an indexed column in a function in a filter; check the query plan.
- Avoid one query per row in a loop; batch or join.
- Write characterization tests before changing behavior you do not fully own.

## How to use it

1. Read the code and name the smell with evidence (`path:line`).
2. Pick the smallest row-matching change; check its "do NOT" cell.
3. Say what you would _not_ apply and why. That list is part of the answer.
4. For candidate lists coming from `grep` or counts, verify first with the
   `refactor-audit` skill, then come back here to choose the fix.
