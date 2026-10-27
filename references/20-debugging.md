# 20 Debugging

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Something failed and you do not know why. Proving code works before it fails is
[14](14-writing-tests.md); driving a finding someone else wrote down is
[35](35-verifying-findings.md). This is the half in between. Moves that name prior art came from it; the
rest this project used before anyone wrote them down.

**Rules**

- No fix before the cause is located (20.1)
- Reproduce it yourself, both directions where there are two; where you can delegate, the failing test comes from an agent that has not seen the fix (20.2)
- Shrink the repro until any further cut makes it pass (20.3)
- Put a working example beside the broken one; the diff is the diagnosis (20.4)
- Trace the bad value back to where it was produced (20.5)
- One hypothesis, one edit; revert an edit that did not move the symptom (20.6)
- If it used to work, bisect what changed on a deterministic signal; call a failure pre-existing only after it fails on the base branch, and unverified when the base cannot be run (20.7, 20.8)
- Before believing a behavioural check of an edit, confirm the running process has loaded it (20.10)
- In a live incident, stop the damage before finding the cause: rollback is the operator's call, and reproduction happens off the live data (20.12)
- Fixing the code that wrote bad data does not fix the data: find what it already wrote, and repair it or record that you looked (20.11)

### 20.1 No fix before the cause is located

A change that makes the symptom go away without
naming what produced it has not fixed anything; it has moved the evidence. The moves
below are what locating a cause actually consists of.

### 20.2 Reproduce it yourself before you believe the report

A failure you have not seen is a
claim, including when it is your own. Two costs on the record: a scanner branch was filed as
a defect from reading the code, and is still marked *not execution-verified* in the bug log
because the tool was not installed to check it. The reverse is worse - a shipped secret-scan
config was believed correct by three readings and turned out to allow the same token in one
directory and block it in another, which only a probe could show. Reproduce in both
directions where the thing has two: the failing case must fail *and* the passing case must
still pass, or you have tested nothing. Where you can delegate, the failing test comes
from an agent that has not seen the intended fix: one that has writes a test of the patch,
not of the symptom. Prior art: addyosmani/agent-skills' test-driven skill.

### 20.3 Shrink the reproduction before reading code

Cut the failing input and setup - rows,
steps, config, files - until removing anything more makes it pass. What remains is the case
you debug, and it is usually small enough that the cause is in view. It is also a smaller
working set, which is what a small model needs to reason at all. Prior art:
addyosmani/agent-skills' debugging skill.

### 20.4 Put a working example beside the broken one and list every difference, however small

When two things do the same job and one is wrong, the diff is the diagnosis. Two guards here
were written from the same pattern against the same input; one failed loudly and one reported
success on what it could not parse. Reading the broken one alone had produced nothing across
several passes - the pair is what named the class, and the class turned out to be wider than
the instance. Prefer a *working* comparator to a remembered one: the value is that it runs.

### 20.5 Trace the bad value backward to where it was produced, not to where it surfaced

The
place a failure becomes visible is rarely the place it was made. A pre-commit hook here
blocked every commit and named every staged file as a secret; the exit code it read had come
from the scanner's self-updater failing before the scan ran at all. A fix applied where the
symptom appeared would have suppressed the only signal that the scanner was never running.
Follow the value one hop at a time and confirm each hop, rather than reasoning about where it
must have come from.

### 20.6 One hypothesis, one edit

Change one thing per test of a hypothesis, and revert an edit
that did not move the symptom before trying the next. Edits that pile up while debugging
leave a fix nobody can name - some of them load-bearing, the rest noise that ships with it.
Prior art: addyosmani/agent-skills' debugging skill.

### 20.7 If it used to work, the cause is in what changed

Read history before code: `git log` on
the affected paths since the last known-good state. With a good commit, a bad one and a
command that tells them apart, `git bisect run` finds the change mechanically - a bounded
loop instead of a search of the whole repo, which is what makes a regression workable for a
small model ([30-handing-work-to-a-small-model.md](30-handing-work-to-a-small-model.md) otherwise routes
repro-less debugging away from one). The same halving finds a test that pollutes another:
split the tests that run before the victim until one remains. Bisection needs a
deterministic signal - a flaky one names the wrong commit, so characterise the flake first
([15.5](15-running-tests.md)). Prior art: gstack's debugging skill.

### 20.8 "Pre-existing" is a claim; prove it on the base

Before calling a failure unrelated to
your change, run the same check on the base branch - a detached worktree at the base commit
leaves your tree alone. Fails there too: pre-existing, and cite the run. Passes there: it is
your change, however unrelated it looks. Cannot run it: write *unverified*, never
*pre-existing*. gstack makes this mandatory, citing couplings no one sees from the diff - a
changed preamble shifting agent behaviour, a new helper shifting timing.

### 20.9 When to stop is already written down

[32.3](32-running-unattended.md) carries the
stop list: a repeat failure after a documented repair ends the run and hands back. Resist
replacing that with a fixed number of attempts - the condition that matters is *a repair you
documented did not hold*, which is evidence about the model of the system, where a raw count
of tries is only evidence about persistence.

### 20.10 Confirm the code running is the code you edited

A long-lived process - a server, a gateway, a daemon, a REPL - keeps the module it imported
before your edit. In one project a debug probe never fired because the gateway had loaded the
module earlier, and a fix looked like it did nothing. Before reading a behavioural check as a
verdict on an edit, prove the process has it: restart it, or have the edit print a marker you
then see.

### 20.11 The fix stops new damage; the old damage is still there

A test suite that wrote into a real store was fixed, and two months later the store was
mostly test fixtures; a suite that rewrote the operator's config was fixed, and nothing
repaired the file it had already written, so real data went to the test namespace for weeks.
When a defect wrote data, the fix has a second half: search for its output, then repair it or
record that you looked and found none.

### 20.12 A live incident: stop the damage, then debug

The rules above are for a failure you can reproduce at leisure. When production is failing
now, the order changes. Say what is broken and since when, and propose the quickest way back -
a rollback ([26.4](26-releasing.md)), a flag off, a stopped job - which is the operator's call,
not yours ([23.2](23-audit-milestones.md)'s block tier). Reproduce off the live data, in a test
namespace ([13.4](13-data-architecture.md)) or a copy, never by retrying against production.
Change nothing live you cannot undo. Then debug as above, and file what you found.
