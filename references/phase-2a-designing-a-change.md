# Phase 2a: Designing a change

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

What happens before any code is written: the design doc, the order tests come in, the
interview that fills the gaps, and the lightweight assignment for work between a
one-liner and a design doc. Recording the decision and shipping it is
[2b](phase-2b-recording-and-shipping.md).


### 4. Design Doc Before Code

Every non-trivial feature gets a design doc before any code is written.
See **Skip threshold** below for what counts as non-trivial.

**Minimum content:**
- Problem statement (what's broken or missing)
- Algorithm or approach (numbered steps)
- Schema/data changes (SQL, types, JSON structure)
- Edge cases table (case | handling)
- Performance estimate (cost per call, expected latency)
- Rollback plan (how to undo if it breaks)

Mark each question the doc raises as **decided** or **open**, and let the gate pass only
when every open one is resolved or waived with a reason — the same three-status discipline a
findings backlog uses, applied one document earlier. Without it a doc can carry all six
sections above with the fork in the road still unresolved inside one of them, which is
exactly what the doc exists to prevent. Waiving is a real option: exploratory work whose
point is to find out by building marks the question open, says so, and proceeds.

**Location:** `designs/<feature-name>.md`. Retained after implementation — don't delete.

**Skip threshold:** One-line fixes (typo, parameter rename, one-function refactor) don't need a design doc. If the change spans 3+ methods or touches the schema, it gets one.

#### Write tests after Design Doc, before engine code

Once the Design Doc defines the interface, write the test skeleton immediately — before the engine implementation. This forces the agent to clarify interface boundaries early and creates a contract the engine code must satisfy.

**Order:** Design Doc → Test skeleton → Engine code → Tests pass

Tests written alongside or after the engine code tend to match the implementation, not the spec. Writing them first catches interface ambiguity before it becomes code.

#### Pre-design: interview first

Requirements arrive underspecified. Before writing the design doc, interview the user: ask
clarifying questions one at a time until edge cases, data requirements, and failure modes are
explored, and don't start the doc until they are. You only know what you've been told, and the
forks in the road won't surface on their own.

The prompt a user can paste to trigger this is in `../operator-guide.md`.

#### Task Assignments (`ta/`)

For tasks between a one-liner fix and a full design doc, use a lightweight task assignment in `ta/`. This bridges "we need something" and "design doc written" — a quick way to capture intent before the agent starts typing code.

**File types and naming:**

| Pattern | When to use |
|---------|-------------|
| `<topic>.md` | Brief assignment, no decomposition (one page) |
| `<topic>-plan.md` | Decomposed plan with steps and agent boundaries |
| `<topic>-errors.md` | Bug report with grouping and code references |
| `update-<what>-<why>.md` | Change request for existing functionality |

Lowercase, hyphenated, no dates in filenames (dates go in headings).

**Every assignment must contain:**
1. **H1 title** — what the task is, in one sentence
2. **Context / Why** — what pain this solves
3. **Goal** — measurable result (what should work/be true)
4. **Steps** — concrete actions with file paths and domain names
5. **What NOT to do** — explicit scope boundaries and forbidden changes

If an assignment references code, it must use specific file paths and names. "Fix auth" is a bad assignment. "In `src/auth/auth.service.ts`, replace bcrypt with argon2" is a good one.

**Lifecycle:**

```
created -> in progress -> completed -> ta/done/   (or deleted if disposable)
              |                                    |
              +-> blocked -> needs-review -> ...   +-> ta/done/
              |
              +-> cancelled -> ta/tldr/   (with note: "cancelled, reason")
```

- `blocked` — waiting on external dependency, missing information, or human approval (escalated finding)
- `needs-review` — work complete but requires human sign-off before proceeding

When an escalated or blocked finding occurs (see Phase 4 escalation tiers), the task assignment enters a paused state until human intervention resolves it.

- `ta/done/` — completed assignments, retained as decision history. Useful for scoping similar future work.
- `ta/tldr/` — cancelled or stale assignments with a short note explaining why.

**Pre-flight checklist** (before starting work on any assignment):
- [ ] File read in full — don't act on the first paragraph; important constraints are often at the end
- [ ] Referenced paths in the repository exist
- [ ] Goal is clear (what should work/be true)
- [ ] Boundaries are clear (what NOT to touch)
- [ ] Mode selected: self / subagent / chain / parallel
- [ ] Result is verifiable (test, build, or manual check)

**Anti-patterns:**
- Writing assignments with code blocks instead of file references — stale within a week
- Copying assignments from old projects without review — half the points are irrelevant
- Ignoring the "What NOT to do" section — leads to scope creep
- Launching a subagent on an assignment goal without a `-plan.md` — subagent doesn't know boundaries and does "everything"
- Leaving "hanging" assignments — move to `done/` or `tldr/` after completion/cancellation

**If an assignment has contradictory points, ask the user — don't choose yourself.**

When the executing model is small or local, every rule above hardens from recommended to
mandatory — see [small-model-operation.md](small-model-operation.md).
