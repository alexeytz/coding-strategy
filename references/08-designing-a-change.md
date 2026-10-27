# 8 Designing a change

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What happens before any code is written: the interview that fills the gaps, the design
doc, and the order tests come in. The lighter assignment for work between a one-liner and
a design doc is [9](09-task-assignments.md); recording what you decided is
[10](10-decision-records.md).

**Rules**

- A new app or feature gets an interview: intent first, one question at a time with your guess attached; then only the design questions without a safe default. Unattended, an underspecified ask is a stop, not a guess (8.1)
- A change spanning 3+ methods or touching the schema gets `designs/<feature>.md` before code (8.2)
- A design doc carries problem, what exists, alternatives, approach, schema changes, edge-case table, performance, rollback; every open question resolved or waived with a reason (8.2)
- Order of work: design doc → test skeleton → engine code → tests pass (8.3)

### 8.1 Interview before the design doc

A short request is not a small one: **a new app or feature always gets this interview**
before the doc. Two stages, in order - design questions
asked before intent is settled get answered for the wrong thing.

**Intent first.** Write your one-line read of the ask, then ask one question at a time with
your guess attached (`Q: … GUESS: …, because …`). A wrong guess is corrected faster than a
blank is filled, and one at a time because the first answer often reframes the rest. Cover
who it is for, why now, what success looks like, the binding constraint. A virtue offered as
an answer - "scalable", "the standard way" - gets *if you didn't have to justify it, what
would you want?* Stop when you can predict the user's reaction to your next three questions;
if rounds pass without getting closer, say something foundational is missing. Restate -
outcome, user, why now, success, constraint, out of scope - and get an explicit yes.
"Whatever you think" is not one: offer two concrete options.

**Then design coverage.** Draft the full question list privately - data, auth and roles,
platforms, integrations, scale, failure and offline behaviour - and sort it. Ask only what
changes the design, guess attached. A question with a sensible default goes into the doc
as *decided (assumed)* for the user to scan; one that can wait is marked *open*.

Unattended there is no one to ask: an underspecified ask is a reason to stop and hand back
([32.3](32-running-unattended.md)), not a gap to fill. Prior art: the `interview-me`
skill in addyosmani/agent-skills.

The prompt a user can paste to trigger this is in `../operator-guide.md`.

### 8.2 A design doc before code

Every non-trivial feature gets a design doc before any code is written.
See **Skip threshold** below for what counts as non-trivial.

**Minimum content:**
- Problem statement (what's broken or missing)
- What already exists - code that partly solves it, and what happens if you do nothing
- Alternatives considered, including the smallest one that would do
- Algorithm or approach (numbered steps)
- Schema/data changes (SQL, types, JSON structure)
- Edge cases table (case | handling | tested? | silent?) - a case that is unhandled,
  untested *and* silent blocks the doc
- Performance estimate (cost per call, expected latency)
- Rollback plan (how to undo if it breaks)

Mark each question the doc raises as **decided** or **open**, and let the gate pass only
when every open one is resolved or waived with a reason - the same three-status discipline a
findings backlog uses, applied one document earlier. Without it a doc can carry every
section above with the fork in the road still unresolved inside one of them, which is
exactly what the doc exists to prevent. Waiving is a real option: exploratory work whose
point is to find out by building marks the question open, says so, and proceeds.

**Location:** `designs/<feature-name>.md`. Retained after implementation - don't delete.

**Skip threshold:** One-line fixes (typo, parameter rename, one-function refactor) don't need a design doc. If the change spans 3+ methods or touches the schema, it gets one.

### 8.3 Tests after the design doc, before engine code

Once the Design Doc defines the interface, write the test skeleton immediately - before the engine implementation. This forces the agent to clarify interface boundaries early and creates a contract the engine code must satisfy.

**Order:** Design Doc → Test skeleton → Engine code → Tests pass

Tests written alongside or after the engine code tend to match the implementation, not the spec.
