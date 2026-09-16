# Driving a small or local model

Cross-cutting constraints for running this strategy with a small model — a ~7B–30B local
model, or any model whose quality visibly drops as a project grows. Read alongside the phase
files; this doesn't replace them, it tightens them.

## The failure this addresses

Quality falls off and hallucination rises as the project grows. The usual assumption is that
the context window has been exhausted. Usually it hasn't: advertised context is the point where
the model *errors*, not the point where it stops reasoning well. For dense interdependent
content like code, useful capacity is typically a fraction of the advertised window, and the
gap widens for reasoning over many interacting facts as opposed to retrieving one.

Three distinct mechanisms produce the same symptom, and only one is fixed by file layout:

| Mechanism | What it looks like | What fixes it |
|---|---|---|
| **Distractor load** | Invents a signature that belongs to a different module; blends two conventions | Shrink and curate the working set |
| **Constraint capacity** | Correct locally, breaks an invariant three files away | Decompose the task; narrow interfaces |
| **Positional dilution** | Follows the rule stated at the start, ignores the one in the middle | Shorter context; rules near the instruction |

## Diagnose before restructuring

Take a task the model fails at in the large project. Re-run it in the same project with only
the genuinely relevant files in context and nothing else.

- **Quality returns** → distractor load. Structure and curation will fix it; keep reading.
- **Still poor at a small curated context** → capacity. No layout change helps. Decompose the
  task, or route that step to a larger model (see *Escalate by kind*).

If degradation shows up at a fraction of the advertised window, the window is not the binding
constraint and a longer-context model will not help.

## Working-set budget

Set a number and hold to it. A workable default for a ~27B model: **no more than 8 files or
~10k tokens of code in context for one task.** Budget it explicitly — skill text, AGENTS.md
chain and task assignment all consume the same allowance the code needs.

Consequences for the rest of this strategy:

- Load [rules-card.md](rules-card.md) rather than a phase file for routine work. It is the
  whole strategy at roughly a fifth of the token cost; open a phase file only for a rule that
  needs its table or template.
- The phase-1 invariant — *a feature touches at most 2 source files* — is the working-set bound
  in disguise. Treat a feature needing 5 files as a blocked task and fix the interface first,
  rather than loading all 5.
- `docs/context-index.md` moves from optional to mandatory. The map is what lets the model open
  3 files instead of grepping through 30.
- Prefer one cohesive file with a narrow interface over several small coupled ones. Splitting
  by line count while leaving coupling intact makes things worse: the working set is unchanged
  and discovery now costs more.

## Task assignments carry more weight

Underspecification is filled by invention, and small models invent more. Every `ta/` rule in
phase 2 becomes mandatory rather than recommended:

- Name exact paths. Never a goal like "add caching" without the files it lands in.
- One goal per assignment. An "and also" is a second assignment.
- State what NOT to touch explicitly — scope creep is how a 3-file task becomes a 12-file one.
- Point at an existing example in the repo to imitate. Imitation is far more reliable than
  specification for a small model.
- Don't ask it to discover the codebase and then act in the same step. Discovery first, with
  its findings written down; then act from the notes.

## Give it a mechanical oracle

A small model cannot reliably verify its own work by reasoning, so it needs an external check
it can run in seconds. This upgrades parts of [phase 3b](phase-3b-verifying.md) from good practice to
prerequisite:

- A type checker or LSP diagnostics — a hallucinated method name should die on the spot rather
  than in review.
- One command that lints and tests, finishing fast enough to sit inside the edit loop.
- Tests that fail loudly on a wrong symbol, not just on wrong values.

Every check that runs mechanically is a check the model doesn't have to hold in its head.

## Escalate by kind, not by difficulty

Some work is a poor fit for a small model regardless of how the context is arranged. Route
these to a larger model or a human, and let the small model execute the result:

- Schema and interface design — the decisions everything else is measured against.
- Cross-cutting refactors spanning many call sites at once.
- Debugging without a reproduction, where the search space is the whole repo.
- Reconciling contradictory requirements — it will silently pick one.

Good targets for the small model: a well-scoped assignment with named paths, an existing
pattern to imitate, and a test that says when it's done.

## Repeat a rung before climbing one

When a step is worth escalating, the reflex is to climb the effort or model ladder. Two
measured results say that is the wrong first move.

**The ladder does not nest.** On a seeded-defect benchmark (six planted defects, four effort
levels, three repeats), the cheapest level found all six on one run while a middle level never
exceeded five in three. Coverage does not accumulate as you climb — the rungs are different
draws.

**The spread within a rung exceeds the gap between most rungs** — 3, 5 and 6 out of 6 on
identical input. So one clean run at any level is weak evidence, and **a second run at the same
rung buys more than a first run one rung up**, at a fraction of the cost. Only the top rung
separated; the middle ones cost multiples of the cheapest for recall inside its noise.

**The signal to climb is not silence** — it is the cheap rung starting to produce
non-findings: claims about symmetric code, or a result whose own body argues against it. A
rung reaching for material is done, whatever its output count says.

Full evidence, and what every rung misses regardless of effort:
[phase 7d](phase-7d-what-a-round-is-worth.md).

## Anti-patterns

| Anti-pattern | Why it backfires |
|---|---|
| Splitting into many small coupled files to "reduce context" | Same working set, higher discovery cost |
| Letting the harness auto-load whatever it finds | Every irrelevant file is an active distractor |
| Asking for a feature rather than an edit | The gap between goal and code gets filled with invention |
| Loading a full phase file for a rule you already know | Spends the code budget on prose |
| Treating a capacity failure as a prompting failure | Re-prompting a task that doesn't fit produces confident nonsense |
| Climbing the effort ladder on one bad run | The within-rung spread is wider than the gap between rungs; repeat the rung first |
