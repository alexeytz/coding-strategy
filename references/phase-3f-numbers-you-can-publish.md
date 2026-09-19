# Phase 3f: Numbers you can publish

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

A measurement is a claim like any other, and it survives scrutiny only if it was built to.
These are the ways a number goes wrong before anyone disputes it. Claims made by documents
and artifacts are [3d](phase-3d-checking-what-you-claim.md).

### 12. Numbers you can publish

**Establish the noise floor before comparing anything.** Run one arm against itself at
least three times and publish the spread. A difference smaller than that spread is not a
result, however good the story around it is. This is the step that gets skipped because
it produces no headline, and skipping it is why most before-and-after numbers are
unfalsifiable.

**Prefer a metric scheduling cannot move.** A counter — calls made, bytes read, cache
misses — is stable where a wall-clock timing is a measurement of the machine's mood. When
you must time something, time it against the floor above, not against a single prior run.

**Compare against a control arm the harness runs, not against nothing.** Name what the
treatment is being credited against, and make the control an arm that actually executes,
not a caveat in the writeup. Two honest cautions: a control multiplies the cost of every
evaluation, and a badly chosen one is *more* misleading than none because it looks
rigorous. Choosing it is the difficulty; an identical-config second arm is the cheapest
control that still catches cache effects and intrinsic noise.

**An optional expensive stage ships with a measured row saying what it buys**, or it gets
enabled by superstition and never switched off. Re-anchor the table deliberately when the
baseline moves — a table assembled from two runs at two baselines is comparing nothing.

**An empty success is a defect.** Derive the exit code from the same predicate the report
prints, never from a proxy: a run that produced no data and a run that produced good data
must not both exit zero. Distinguish *partial* from *absent*. And omit a field you cannot
compute honestly rather than zeroing it, because zero and blank both read as measurements
— accepting that omission has a real cost, since a consumer expecting a fixed schema now
handles the gap, so say which you chose and where.

**Say what the number does not cover.** A results table names its raw data file, and the
data file wins any disagreement. Beside it, a short section on what was deliberately not
measured — other batch sizes, other hardware, total system power — because a table of
greens with no negative space invites a conclusion it cannot support. The same applies to
a protective gate, which additionally says what defeats it: "catches accidents and casual
attempts, not a determined author; branch protection and human review are the real
backstop." This is a documentation habit, so it holds only where something asserts the
section exists — without that check it becomes the ritual paragraph nobody updates.
