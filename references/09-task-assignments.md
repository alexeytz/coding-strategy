# 9 Task assignments

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

For work between a one-line fix and a full design doc ([8](08-designing-a-change.md)): a
lightweight assignment in `ta/` that captures intent before the agent starts typing code.
`ta/` is Tier 3 apparatus, or Tier 2 with a small model ([1](01-sizing-to-the-project.md)); below
that, the same headings go in the issue or the request itself, and no `ta/` is created.
When the executing model is small or local, every rule here hardens from recommended to
mandatory - see [30](30-handing-work-to-a-small-model.md).

**Rules**

- An assignment names its files, goal, steps and what not to touch (9.2)
- Never overwrite an assignment with open steps for different work; ask (9.4)
- Read an assignment in full and check its paths exist before starting (9.5)
- A contradictory assignment is a question for the user, not a choice for you (9.7)

### 9.1 File types and naming

| Pattern | When to use |
|---------|-------------|
| `<topic>.md` | Brief assignment, no decomposition (one page) |
| `<topic>-plan.md` | Decomposed plan with steps and agent boundaries |
| `<topic>-errors.md` | Bug report with grouping and code references |
| `update-<what>-<why>.md` | Change request for existing functionality |

Lowercase, hyphenated, no dates in filenames (dates go in headings).

### 9.2 What every assignment contains

1. **H1 title** - what the task is, in one sentence
2. **Context / Why** - what pain this solves
3. **Goal** - measurable result (what should work/be true)
4. **Steps** - concrete actions with file paths and domain names
5. **What NOT to do** - explicit scope boundaries and forbidden changes

Name the files: "Fix auth" is a bad assignment. "In `src/auth/auth.service.ts`, replace bcrypt with argon2" is a good one.

### 9.3 Lifecycle

```
created -> in progress -> completed -> ta/done/   (or deleted if disposable)
              |                                    |
              +-> blocked -> needs-review -> ...   +-> ta/done/
              |
              +-> cancelled -> ta/tldr/   (with note: "cancelled, reason")
```

- `blocked` - waiting on external dependency, missing information, or human approval (escalated finding)
- `needs-review` - work complete but requires human sign-off before proceeding

- `ta/done/` - completed assignments, retained as decision history. Useful for scoping similar future work.
- `ta/tldr/` - cancelled or stale assignments with a short note explaining why.

Where there is no `ta/` (the intro above), the issue's own states replace both directories:
closed when done, closed with the reason when cancelled.

### 9.4 Never overwrite an assignment with open steps

Never overwrite or rename an assignment that still has open steps for different work: it
may be mid-build in another session. Ask. Prior art: addyosmani/agent-skills' planning skill.

### 9.5 Pre-flight checklist

Before starting work on any assignment:
- [ ] File read in full - don't act on the first paragraph; important constraints are often at the end
- [ ] Referenced paths in the repository exist
- [ ] Goal is clear (what should work/be true)
- [ ] Boundaries are clear (what NOT to touch)
- [ ] Mode selected: self, or a subagent ([28](28-delegating.md)); several subagents run one after another or side by side, each with its own assignment
- [ ] Result is verifiable (test, build, or manual check)

### 9.6 Anti-patterns

- Writing assignments with code blocks instead of file references - stale within a week
- Copying assignments from old projects without review - half the points are irrelevant
- Launching a subagent on an assignment goal without a `-plan.md` - subagent doesn't know boundaries and does "everything"

### 9.7 A contradictory assignment is a question for the user

If an assignment's points contradict each other, ask the user - don't choose yourself.
