# 32 Running unattended

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

The loop an agent runs once the operator has left, when it stops, and what it hands back. The
contract it runs under is [31](31-briefing-an-unattended-run.md); trusting what you measured while doing
it is [19](19-instrumentation.md).

**Rules**

- Before the first iteration and between iterations: services up, tree clean, the last run's residue at zero, the driver not the target (32.1)
- Read the report, not the exit code; every failure is a suspect, not a defect (32.2)
- Stop on a repeat failure after a documented repair, a fix needing a test changed when it is unclear which was wrong, anything outside the test namespace, a red tree, underspecified work, an ungranted one-way action, or a crossed budget (32.3)
- A behavioural change to shipped code with no mechanical oracle is `verifier-only, unconfirmed` and does not close (32.3)
- Hand back in the final message, in 32.4's order; a file only if the brief asks or the project keeps one (32.4)
- Record verdicts and corrections as the run goes: in the commit messages if it commits per iteration, else one append-only log (32.5)
- Stop when every item in the brief is done or handed back; unasked work goes in the hand-back, not the tree (32.6)

### 32.1 Before the first iteration

Confirm the preconditions that make a result meaningful, and confirm them again
between iterations:

- external services up, tree clean
- **residue from the previous run at zero** - a non-zero count means the last run
  did not clean up, and this run's results are contaminated by it
- **the driver is not the target.** An agent that is itself a live session against
  the system under test is two concurrent writers on one resource. In one project
  that shape corrupted a database file so thoroughly that every later connection in
  the process failed until it was restarted.

### 32.2 Each iteration

1. **Run one cycle**, with explicit per-stage budgets rather than a uniform one - a
   stage with twice the steps and the expensive ones runs out of a shared budget and
   stops honestly, which reads like a failure.
2. **Read the report, not the exit code.** `rc=0` means the driver returned, not
   that the work happened.
3. **Every failure is a suspect, not a defect.** In one project, nine cycles found
   zero product defects and every failure was harness-side. Verify at the code site
   before changing product code.
4. **Fix, test, release.** Suites green before the tag, never after.
5. **Re-check the preconditions** before the next iteration.

### 32.3 Stop and wait rather than continue

- the same failure recurs after a documented repair - the repair is wrong, and a
  third attempt is guessing
- a fix requires changing a test to land, and it is not clear whether the test was
  wrong before or is wrong now (say so out loud and decide deliberately)
- anything touches a resource outside the test namespace, or a target that is not
  the one under test
- the tree cannot be returned to green
- the work turns out underspecified in a way the brief does not settle - an unattended run
  cannot interview anyone, so a guess here is a decision nobody made
- **the next action is on the one-way list ([31.3](31-briefing-an-unattended-run.md)) and no
  grant ([31.2](31-briefing-an-unattended-run.md)) authorises it.** With nobody
  watching, "can I undo this?" outranks "is this right?", because being right is the
  thing that cannot be checked.
- **the budget proxy crossed its threshold.** Hand back at the cycle boundary.
- **a behavioural change to shipped code has no mechanical oracle.** Reasoning about
  your own output is not verification. Report it `verifier-only, unconfirmed`, name the
  half you could not check, and stop rather than closing it. Scope this deliberately:
  documentation and exploratory work have no oracle either and are fine - this fires on
  a behavioural change to code that ships.

Continuing past these is how a long run produces damage instead of releases.

### 32.4 What to hand back, in this order

The hand-back is your last message to the operator, not a new file. Write it to a file only
when the brief asks for one or the project already keeps one - an existing `handover.md` is
updated, never created for a single run ([27.5](27-handover.md)). Not a narrative:

1. **Verdicts** - cycles run, pass/fail each, step counts, what was scanned.
2. **Releases** - version and one line each; tagged, pushed, `unpushed=0`.
3. **Findings** - fixed / refuted / declined, each with its code evidence. A
   refutation is a result; record it where the next round will find it.
4. **What I got wrong** - corrections to claims made earlier in the run. The section
   most likely to be skipped and most likely to matter.
5. **Decisions waiting on a human** - with the reasoning already done, so each is a
   yes/no.
6. **State** - preconditions, tree, and *everything still running*.

### 32.5 Write the record as the run goes, not at the end

Items 3 and 4 above are the ones that cannot be reconstructed from the tree afterwards, and a
run that dies in hour three - crash, context exhausted, session killed - loses exactly those.
So record them as they happen, in one place:

- **The run commits per iteration:** the commit messages are the record. Put each cycle's
  verdict and any correction in its message; a cold start reads `git log` and the tree. No
  file - a second record is a third thing to keep true.
- **It does not:** one append-only run log, read first on a cold start. It is the run's
  scratch record, not a `handover.md` ([27.5](27-handover.md)); its content ends up in the
  hand-back.

### 32.6 Stop when the brief is done

32.3 is the list for stopping on trouble; this is the stop on success. When every item the
brief names is done, or handed back as a decision, verify, write the hand-back (32.4) and stop.
Time left on the clock is not a budget to spend:

- no suites, probes, refactors or documents the brief did not ask for. Each is a change nobody
  requested, made while nobody watched, that someone must now review before trusting the rest.
- what you noticed and did not do goes in the hand-back - a finding (item 3) or a decision
  waiting on a human (item 5), one line each. A hardening you think is needed is a decision,
  not a next cycle.

In tests of this skill, overnight runs with it loaded took up to three and a half times as long
as runs without it and reached the same result. One agent finished a four-item list early, then added
characterisation suites, mutation probes, a run record and a handover until its time limit cut
it off mid-edit, with four files uncommitted.
