# 28 Delegating

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Handing work to subagents, and sharing a checkout with another writer. Working in a
documented repo yourself is [7](07-working-in-a-documented-repo.md); briefing a reviewer is
[36.4](36-what-a-round-is-worth.md).

**Rules**

- Every subagent is defined by name, invocation, purpose and an explicit negative constraint (28.1)
- Withhold a capability by not declaring it, keep refusal for what the caller could expect to work, and log one startup line naming what was withheld and why (28.2)
- With two agents writing at once, take a branch or worktree for anything beyond reading or a small task when you find work in progress that is not yours (28.3)
- Put every defect you found while investigating into the brief, to fix or named as left with the reason; never fence one out of scope silently (28.5)
- A hand-off whose code you will not read gets a second worker as verifier: the task is the reference, it runs things and reads the diff, the developer's report is claims (28.6)

### 28.1 A subagent registry

When delegating work to subagents, define them explicitly - don't leave their scope to inference.

**Registry location:** a table in `docs/agents.md` or the root `AGENTS.md`.

**Each subagent entry:**
- **Name** - short, lowercase, hyphenated (e.g., `browser-checker`)
- **Invocation** - how to call it (e.g., `@browser-checker <message>`)
- **Purpose** - what it does, one sentence
- **Negative constraints** - what it explicitly does NOT do

**Why a registry:** without it, subagents get vague instructions, duplicate work, or silently do the wrong thing. The registry makes delegation explicit and auditable.

**Default roles every project should consider:**

| Role | Purpose | Negative constraint |
|------|---------|---------------------|
| `docs-maintainer` | Update docs after code changes | Does NOT write new features - only syncs docs to match code |
| `test-runner` | Run tests, return pass/fail report | Does NOT fix code - only reports |
| `test-fixer` | Analyze failures, fix root cause, confirm passing | Does NOT rewrite tests to pass - fixes the actual bug |
| `browser-checker` | Visual verification in browser | Does NOT modify DOM or application state |

### 28.2 Don't advertise a capability you intend to refuse

A tool that registers and then
returns "not enabled" spends the caller's attention on every listing and teaches it to
distrust the list. Withhold by not declaring, and keep refusal for cases the caller could
reasonably have expected to work. Pair it with one startup line saying what was withheld and
why - silent absence is harder to debug than a refusal, and an operator who forgot a flag
should see the switch named rather than a tool that never existed.

### 28.3 A second writer in one checkout

A doc rule does not stop two agents interleaving unrelated edits into one diff; the commit
convention describes that mess rather than preventing it. The useful trigger is not "always
branch" but **branch when you find work already in progress that is not yours** - read-only
investigation and small tasks are fine in the shared checkout. Where your VCS supports it,
give the second task its own worktree and branch and do all edits and validation there. This
earns its place only once two agents actually run at once; for a solo operator who is always
the only writer it is cost with no return.

### 28.4 Delegation is bounded by the operator

Which tool or subscription a task runs on, when a session resets, and how remaining quota is
budgeted are operator decisions - an agent cannot see another tool's usage. Those rules live in
`../operator-guide.md`. Within a session, keep to the registry: use the named subagents for
their stated purpose and respect their negative constraints.

### 28.5 A brief carries what you found

When you look at the code before delegating, the defects you find go into the brief: each one to
be fixed, or named as left alone with the reason, which you then pass on to the user. A brief
that draws its scope line around the task alone loses the defect next to it. The worker obeys
the line, your check looks for what the brief asked, and a flaw you could have fixed ends up in
the report as a note. Measured on one model delegating to itself: an injection next to the task
was fixed in 0 of 10 delegated runs, though the same model working alone fixed it every time;
one sentence in the standing instruction brought it to 10 of 10, and on a task with no defect
next to it nothing outside the task changed. That sentence ships in
`config/AGENTS.root.template.md`, under Work Guidance: the standing instructions are loaded
before any brief is written, and this file may not be.

### 28.6 A hand-off you will not read gets a verifier

Handing a whole task over and checking only by commands keeps your context small, but a green
suite and `git diff --stat` show only what the tests assert. When you will not read the code,
start a second worker as verifier with a short brief: the task file is the reference; run the
tests and read the diff; the developer's report is claims to confirm, not facts; answer item by
item with the command that shows it. Findings go back to the developer. The verifier needs a
shell: a read-only reviewer cannot run anything. Measured on one task: an atomic save that left
the live data file private (mode 0600) shipped in 9 of 24 hand-offs without a verifier, 4 of
them checked by commands, and in 0 of 8 with one; the parent stayed at about a third of the context
of delegating piece by piece, and the workers' tokens doubled. A verifier checks against the
task, so it cannot find a defect nobody asked about: on a second task, hand-offs nobody read
fixed the injection next to the task in 1 of 24 runs, against 10 of 10 where the parent read
the code and briefed what it found. Where the code around the task may share its flaw, read it
before you brief (28.5), or say in your report that the check stopped at the task. The sentence ships in
`config/AGENTS.root.template.md` beside 28.5's.
