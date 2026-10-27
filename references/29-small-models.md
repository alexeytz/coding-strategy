# 29 Small models

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Running this strategy with a small model - a ~7B–30B local model, or any model whose
quality drops as a project grows: why it falls over, telling distractor load from capacity, and
the working-set budget. It tightens the other files rather than replacing them. Shaping the work
you hand it is [30](30-handing-work-to-a-small-model.md).

**Rules**

- Re-run a failing task with only the relevant files; if quality returns, curate the working set, otherwise decompose or escalate (29.2)
- Hold one task to about 8 files or 10k tokens of code (29.3)

### 29.1 The failure this addresses

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

### 29.2 Diagnose before restructuring

Re-run a task the model fails at in the large project, with only the relevant files in context.

- **Quality returns** → distractor load. Structure and curation will fix it; keep reading.
- **Still poor at a small curated context** → capacity. No layout change helps. Decompose the
  task, or route that step to a larger model ([30.3](30-handing-work-to-a-small-model.md)).

If degradation shows up at a fraction of the advertised window, the window is not the binding
constraint and a longer-context model will not help.

### 29.3 Working-set budget

Set a number and hold to it. A workable default for a ~27B model: **no more than 8 files or
~10k tokens of code in context for one task.** Budget it explicitly - skill text, AGENTS.md
chain and task assignment all consume the same allowance the code needs: SKILL.md and one
job file are about 6k tokens, so with them loaded read the Rules block first and open code
files only as the task needs them.

Consequences for the rest of this strategy:

- Load the Rules block of the one file that matches the task; read a rule in full only when its
  line is not enough. Not both rules cards ([rules-card.md](rules-card.md),
  [rules-card-operating.md](rules-card-operating.md)): more than half this budget, and in a test no
  better than SKILL.md at up to 2.2x the time.
- *A feature touches at most 2 source files* ([2.2](02-layout.md)) is the working-set bound
  in disguise. Treat a feature needing 5 files as a blocked task and fix the interface first,
  rather than loading all 5.
- `docs/context-index.md` moves from optional to mandatory. The map is what lets the model open
  3 files instead of grepping through 30.
- Prefer one cohesive file with a narrow interface over several small coupled ones. Splitting
  by line count while leaving coupling intact makes things worse: the working set is unchanged
  and discovery now costs more.

### 29.4 Anti-patterns

| Anti-pattern | Why it backfires |
|---|---|
| Letting the harness auto-load whatever it finds | Every irrelevant file is an active distractor |
| Loading a whole file for a rule its Rules line already gives | Spends the code budget on prose |
| Treating a capacity failure as a prompting failure | Re-prompting a task that doesn't fit produces confident nonsense |
