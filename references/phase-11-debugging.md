# Phase 11: Debugging

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-decision-records.md) · [2c](phase-2c-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [3g](phase-3g-verifying-against-real-targets.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Something failed and you do not know why. Proving code works before it fails is
[3b](phase-3b-verifying.md); driving a finding someone else wrote down is
[7c](phase-7c-verifying-findings.md). This is the half in between, and the rules below are
three this project used repeatedly before anyone wrote them down.

### 26. Working a failure

**No fix before the cause is located.** A change that makes the symptom go away without
naming what produced it has not fixed anything; it has moved the evidence. The three moves
below are what locating a cause actually consists of, and each is here because skipping it
cost something.

**Reproduce it yourself before you believe the report.** A failure you have not seen is a
claim, including when it is your own. Two costs on the record: a scanner branch was filed as
a defect from reading the code, and is still marked *not execution-verified* in the bug log
because the tool was not installed to check it. The reverse is worse — a shipped secret-scan
config was believed correct by three readings and turned out to allow the same token in one
directory and block it in another, which only a probe could show. Reproduce in both
directions where the thing has two: the failing case must fail *and* the passing case must
still pass, or you have tested nothing.

**Put a working example beside the broken one and list every difference, however small.**
When two things do the same job and one is wrong, the diff is the diagnosis. Two guards here
were written from the same pattern against the same input; one failed loudly and one reported
success on what it could not parse. Reading the broken one alone had produced nothing across
several passes — the pair is what named the class, and the class turned out to be wider than
the instance. Prefer a *working* comparator to a remembered one: the value is that it runs.

**Trace the bad value backward to where it was produced, not to where it surfaced.** The
place a failure becomes visible is rarely the place it was made. A pre-commit hook here
blocked every commit and named every staged file as a secret; the exit code it read had come
from the scanner's self-updater failing before the scan ran at all. A fix applied where the
symptom appeared would have suppressed the only signal that the scanner was never running.
Follow the value one hop at a time and confirm each hop, rather than reasoning about where it
must have come from.

**When to stop is already written down.** [8a §22](phase-8a-unattended-runs.md) carries the
stop list: a repeat failure after a documented repair ends the run and hands back. Resist
replacing that with a fixed number of attempts — the condition that matters is *a repair you
documented did not hold*, which is evidence about the model of the system, where a raw count
of tries is only evidence about persistence.
