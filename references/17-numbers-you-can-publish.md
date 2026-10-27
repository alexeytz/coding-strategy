# 17 Numbers you can publish

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

A measurement is a claim like any other, and it survives scrutiny only if it was built to.
These are the ways a number goes wrong before anyone disputes it. Claims made by documents
and artifacts are [16](16-checking-what-you-claim.md).

**Rules**

- Publish the noise floor before any comparison - one arm against itself, three runs (17.1)
- A change inside the floor is reverted; measure one change at a time (17.2)
- Prefer a counter to a timing; compare against a control arm the harness runs (17.3, 17.4)
- Derive the exit code from the predicate the report prints; an empty success is a defect; omit a field you cannot compute honestly rather than zero it, and say where (17.6)
- Fix the sample size and the stop rule before measuring a number you will publish (17.7)
- Every results table names what it does not cover (17.8)
- Results pooled across groups are compared within each group first, the verdict's direction as well as its p-value (17.9)

### 17.1 Establish the noise floor before comparing anything

Run one arm against itself at
least three times and publish the spread. A difference smaller than that spread is not a
result, however good the story around it is. This is the step that gets skipped because
it produces no headline, and skipping it is why most before-and-after numbers are
unfalsifiable. A baseline is written only from a run that passes a sanity bound: one project
re-anchored on a degraded run (recall 0.18 against a normal 0.90), caught by luck and a backup.

### 17.2 A change inside the floor is reverted, not kept as harmless

It bought complexity and
no measured gain. Measure one change at a time - three landed together give one number and
no attribution - and a gain that needed a test edited to land is a regression until the
edit is justified on its own. Record the reverted attempt with its numbers, so nobody
retries it on a hunch. Prior art: addyosmani/agent-skills' performance skill.

### 17.3 Prefer a metric scheduling cannot move

A counter - calls made, bytes read, cache
misses - is stable where a wall-clock timing is a measurement of the machine's mood. When
you must time something, time it against the floor above, not against a single prior run.

### 17.4 Compare against a control arm the harness runs, not against nothing

Name what the
treatment is being credited against, and make the control an arm that actually executes,
not a caveat in the writeup. Two honest cautions: a control multiplies the cost of every
evaluation, and a badly chosen one is *more* misleading than none because it looks
rigorous. Choosing it is the difficulty; an identical-config second arm is the cheapest
control that still catches cache effects and intrinsic noise.

### 17.5 An optional expensive stage ships with a measured row

Without a row saying what it buys, it gets
enabled by superstition and never switched off. Re-anchor the table deliberately when the
baseline moves - a table assembled from two runs at two baselines is comparing nothing.

### 17.6 An empty success is a defect

Derive the exit code from the same predicate the report
prints, never from a proxy: a run that produced no data and a run that produced good data
must not both exit zero. Distinguish *partial* from *absent*. And omit a field you cannot
compute honestly rather than zeroing it, because zero and blank both read as measurements -
accepting that omission has a real cost, since a consumer expecting a fixed schema now
handles the gap, so say which you chose and where. Keep *unknown* and *known empty* apart too:
a field that is missing means unknown, and a value that is known to be empty gets its own
(`""`, `{}`), never the same `None`. Merge the two and a run that fell back to a default
compares silently against a clean one. A later status never overwrites a more specific earlier
one: a runner that turned FAIL into TIMEOUT hid why the run failed. For a test run the receipt is
selected / ran / passed / failed / skipped / errored against what was expected: a runner can
drop a mistyped file selector and pass the rest, and zero tests run exits zero.

### 17.7 Fix the sample size and the stop rule before looking

Adding trials after seeing a
result, or escalating only when a run fails, is a retry dressed as method - it drifts toward
the result you wanted. Write down how many runs and when you stop, then run. This does not
contradict repeating a rung while operating
([30.5](30-handing-work-to-a-small-model.md)): that decides what to do next, it is
not a number you publish.

### 17.8 Say what the number does not cover

A results table names its raw data file, and the
data file wins any disagreement. Beside it, a short section on what was deliberately not
measured - other batch sizes, other hardware, total system power - because a table of
greens with no negative space invites a conclusion it cannot support. The same applies to
a protective gate, which additionally says what defeats it: "catches accidents and casual
attempts, not a determined author; branch protection and human review are the real
backstop." This is a documentation habit, so it holds only where something asserts the
section exists - without that check it becomes the ritual paragraph nobody updates.

### 17.9 Stratify before you pool, and take the direction from the strata

When results pool across groups - tasks, models, hosts - the mix of groups can decide the
verdict on its own. In one evaluation two arms had identical pass rates within every task and
pooled to 33/40 against 15/40, because one arm ran more of the easy task. Compare within each
group, then combine. That includes the direction: a later review there found the p-value
stratified while BETTER or WORSE still came from the pooled rates, so the verdict could
disagree with its own test. Report the per-group table beside any pooled number.
