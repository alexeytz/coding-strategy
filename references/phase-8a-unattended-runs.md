# Phase 8a: Unattended runs

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

The contract before the operator leaves, the loop, when to stop, and what to hand
back. Trusting what you measured while doing it is [8b](phase-8b-instrumentation.md);
delegating a bounded task to a subagent is
[phase 5b §15](phase-5b-working-and-delegating.md).

### 19. Unattended runs

The operator leaves; an agent runs for hours and must not need a decision. **Write
the contract down.** One project reconstructed its overnight procedure from memory
twice before writing the file, which is the reason the file exists.

#### The standing protocol

Four things, agreed before the operator leaves, kept in a table the agent re-reads
at the start of every run:

| | |
|---|---|
| **Scope** | what to work on, and what to do when that is done |
| **Autonomy** | which of: verify, fix, run suites, commit, push |
| **Effort** | the level, plus "repeat a rung before climbing" ([phase 7d](phase-7d-what-a-round-is-worth.md)) |
| **On failure** | repair what is documented, record it, continue — or stop |

**Grants are named fields, not a sentence in the conversation.** An agreement that
lives in chat cannot be cited by the agent mid-run, checked afterwards, or reused next
time. Put each permission in the brief as a named field that defaults to refusing —
`ALLOW_DESTRUCTIVE`, `ALLOW_PUSH`, `ALLOW_LONG_RUN` — and have every step that could
spend money or destroy something cite the field that authorises it: "do not delete
outputs or kill remote jobs unless `ALLOW_DESTRUCTIVE` is set and the exact target is
confirmed." A brief that will run more than once is a template plus a config, and the
renderer refuses to emit one with an unfilled slot. For a single run this layer is
overhead — write the fields inline. And note what it is not: an agent honouring a grant
it can read is a compliance assumption, not a mechanism, so the grants that matter are
also enforced where the action happens ([phase 3a §8](phase-3a-writing-resilient-code.md)
on dry-run defaults).

**Two more fields, because the four above are all about correctness.** An agent doing
correct work passes every one of them while the money runs out or while it does
something it cannot take back.

- **A budget it can actually check.** Not spend — an agent usually cannot see its own
  spend, which is why quota sits in the operator's guide. Pick a proxy it *can* read:
  wall clock, cycles, iterations. Check it between iterations, and cross it into the
  hand-back below rather than into a new mechanism — stop cleanly at a cycle boundary
  instead of half-finishing one. The operator calibrates the proxy; a wrong calibration
  stops a healthy run, which is the cost of having one at all.
- **Reversibility, named rather than judged.** "Can this be undone?" is not decidable in
  general — a push usually can, a deploy usually cannot, a delete depends on a backup
  you have not checked. So do not ask the agent to judge it. List the actions that are
  one-way for *this* run, and make that list a stop condition below.

**Ask only if the handover did not say.** One question, those four options, then run.
Do not stop mid-run to ask something the table already answers.

**A scenario that does not fit is split like a review is.** If the work itself is
larger than one session, splitting it is the same problem
[phase 7d](phase-7d-what-a-round-is-worth.md) solves for an oversized review, with a
worse failure mode: a run that hits the cap partway through leaves the last parts
unrun, nothing cleaned up and no verdict, which reads as *stalled* rather than
*failed*. Generate the parts with a script, pass the budget and turn cap explicitly
rather than inheriting a profile default, and add a check that fails when a part stops
being reachable or when state that one part sets up crosses into the next without being
carried.

#### Before the first iteration

Confirm the preconditions that make a result meaningful, and confirm them again
between iterations:

- external services up, tree clean
- **residue from the previous run at zero** — a non-zero count means the last run
  did not clean up, and this run's results are contaminated by it
- **the driver is not the target.** An agent that is itself a live session against
  the system under test is two concurrent writers on one resource. In one project
  that shape corrupted a database file so thoroughly that every later connection in
  the process failed until it was restarted.

#### Each iteration

1. **Run one cycle**, with explicit per-stage budgets rather than a uniform one — a
   stage with twice the steps and the expensive ones runs out of a shared budget and
   stops honestly, which reads like a failure.
2. **Read the report, not the exit code.** `rc=0` means the driver returned, not
   that the work happened.
3. **Every failure is a suspect, not a defect.** In one project, nine cycles found
   zero product defects and every failure was harness-side. Verify at the code site
   before changing product code.
4. **Fix, test, release.** Suites green before the tag, never after.
5. **Re-check the preconditions** before the next iteration.

#### Stop and wait rather than continue if

- the same failure recurs after a documented repair — the repair is wrong, and a
  third attempt is guessing
- a fix requires changing a test to land, and it is not clear whether the test was
  wrong before or is wrong now (say so out loud and decide deliberately)
- anything touches a resource outside the test namespace, or a target that is not
  the one under test
- the tree cannot be returned to green
- **the next action is on the one-way list and no grant authorises it.** With nobody
  watching, "can I undo this?" outranks "is this right?", because being right is the
  thing that cannot be checked.
- **the budget proxy crossed its threshold.** Hand back at the cycle boundary.
- **a behavioural change to shipped code has no mechanical oracle.** Reasoning about
  your own output is not verification. Report it `verifier-only, unconfirmed`, name the
  half you could not check, and stop rather than closing it. Scope this deliberately:
  documentation and exploratory work have no oracle either and are fine — this fires on
  a behavioural change to code that ships.

Continuing past these is how a long run produces damage instead of releases.

#### What to hand back, in this order

Not a narrative:

1. **Verdicts** — cycles run, pass/fail each, step counts, what was scanned.
2. **Releases** — version and one line each; tagged, pushed, `unpushed=0`.
3. **Findings** — fixed / refuted / declined, each with its code evidence. A
   refutation is a result; record it where the next round will find it.
4. **What I got wrong** — corrections to claims made earlier in the run. The section
   most likely to be skipped and most likely to matter.
5. **Decisions waiting on a human** — with the reasoning already done, so each is a
   yes/no.
6. **State** — preconditions, tree, and *everything still running*.

**Write the record as the run goes, not at the end.** Items 3 and 4 above are the ones
that cannot be reconstructed from the tree afterwards, and a run that dies in hour three
— crash, context exhausted, session killed — loses exactly those. Append each cycle's
verdict and each correction to a file as it happens, and have a cold start read that file
and the tree before anything else. Where the run commits per iteration, the commit log
already is that file and a second one is a third thing to keep true; where it does not,
one append-only file is the difference between resuming and restarting.
