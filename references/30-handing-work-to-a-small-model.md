# 30 Handing work to a small model

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Shaping the work a larger model or a human hands a small one: the assignment, a mechanical
oracle, what to escalate, a failing test instead of a plan, and repeating a rung. Why a small
model degrades, and its working-set budget, is [29](29-small-models.md).

**Rules**

- With a small model an assignment names exact paths, one goal and what not to touch, points at an example to imitate, and keeps discovery apart from action (30.1)
- Give the model one fast command that prints the first failure; read the installed version before calling an API, and mark what it could not check unverified rather than writing it from memory (30.2)
- Route design, cross-cutting refactors, repro-less debugging and contradictory requirements to a larger model or a human (30.3)
- The larger model writes the failing test, read-only to the small one; no test first, no split (30.4)
- Repeat a rung before climbing one; climb when the cheap rung starts producing non-findings, not when it goes quiet (30.5)

### 30.1 Task assignments carry more weight

Underspecification is filled by invention, and small models invent more. Every rule in
[9](09-task-assignments.md) becomes mandatory rather than recommended:

- Name exact paths. Never a goal like "add caching" without the files it lands in.
- One goal per assignment. An "and also" is a second assignment.
- State what NOT to touch explicitly - scope creep is how a 3-file task becomes a 12-file one.
- Point at an existing example in the repo to imitate. Imitation is far more reliable than
  specification for a small model.
- Don't ask it to discover the codebase and then act in the same step. Discovery first, with
  its findings written down; then act from the notes.

### 30.2 Give it a mechanical oracle

A small model cannot reliably verify its own work by reasoning, so it needs an external check
it can run in seconds. This upgrades parts of [14](14-writing-tests.md) from good practice to
prerequisite:

- A type checker or LSP diagnostics - a hallucinated method name should die on the spot rather
  than in review.
- One command that lints and tests, finishing fast enough to sit inside the edit loop, and
  printing the first failure with its file and line - a full log is distractor load.
- The installed version, read before calling a library API: the lockfile for the version,
  the installed source for the signature. Anything the model did not check, it marks
  unverified rather than writing from memory.
- Tests that fail loudly on a wrong symbol, not just on wrong values.

Every check that runs mechanically is a check the model doesn't have to hold in its head.

### 30.3 Escalate by kind, not by difficulty

Some work is a poor fit for a small model regardless of how the context is arranged. Route
these to a larger model or a human, and let the small model execute the result:

- Schema and interface design - the decisions everything else is measured against.
- Cross-cutting refactors spanning many call sites at once.
- Debugging without a reproduction, where the search space is the whole repo.
- Reconciling contradictory requirements - it will silently pick one.

Good targets for the small model: a well-scoped assignment with named paths, an existing
pattern to imitate, and a test that says when it's done.

### 30.4 Hand down a failing test, not a plan

Prose gets reinterpreted; a red test does not. The larger model writes, before any code:

- The task assignment, per the rules above.
- Acceptance criteria a command checks.
- Failing tests encoding them, committed red ([8.3](08-designing-a-change.md)),
  written before the fix is designed: tests the implementer writes fit its implementation,
  and a small model fits harder.

The small model loops - edit, run, fix the cause - until green.

- **Handed-down tests are read-only.** A wrong-looking test is a question back up; weakening
  it is the cheapest route to green, and a small model finds it.
- **Done is the command's output, not a sentence.**

The larger model closes by checking the diff against its criteria item by item
([16.8](16-checking-what-you-claim.md)) and for weakened gates
([33.8](33-running-a-review.md)). Expensive tokens buy the ends, cheap ones the middle. Where no
failing test can be written first - exploration, layout, debugging without a repro - skip the
split.

### 30.5 Repeat a rung before climbing one

When a step is worth escalating, the reflex is to climb the effort or model ladder. Measured,
that is the wrong first move: the rungs do not nest - a cheap level can find what a middle one
misses - and the spread within a rung exceeds the gap between most rungs, so **a second run at
the same rung buys more than a first run one rung up**, at a fraction of the cost. Climb when the
cheap rung starts producing non-findings, not when it goes quiet. The benchmark and what every
rung misses are in [36](36-what-a-round-is-worth.md).
