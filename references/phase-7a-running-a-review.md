# Phase 7a: Running a review

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Phases 1-4 are about producing code. Phase 7 is about auditing code that already
exists — yours, an agent's, or a contributor's. Here: how to read it and what counts
as a finding. Recording findings is [7b](phase-7b-findings-log.md); deciding what to
do with them is [7c](phase-7c-verifying-findings.md).

### 19. Reviewing code you did not write

**Orient before reading any implementation file.** Read the root context doc, the
trust-boundary doc if there is one, and the handover's "traps" and "settled with
measurements" sections — in full, whatever your scope. Then read your scope's
in/out list. Only then open code.

A codebase that documents its decisions will look wrong in places where it is
deliberate. A finding that contradicts one of those documents is not automatically
wrong, but it must name the document and say why the document is out of date.
Reviews that skip this step reliably recommend the change that caused the bug the
code exists to prevent.

**Do not read previous reviews' findings files.** They mix findings that were fixed
with findings that were disproved, and treating them as context imports both. The
changelog is where a disposition is recorded; a findings file is scratch.

#### Rules of evidence

- **Verify before logging.** Follow the call chain and read the surrounding lines,
  not the line you noticed. Most false findings come from reading one line: a regex
  that "misses capitals" when the input was lowercased four lines above, an
  exception that "escapes" a handler catching its base class.
- **Quote what you read** — file, line, code. A claim about behaviour across two
  functions quotes both.
- **Never report an observation you did not make.** No timings, memory figures,
  process listings or production symptoms unless you ran something and can say
  what. An invented measurement attached to a wrong finding is the most damaging
  artifact a review can produce, because it makes the finding credible enough to
  act on.
- **If you cannot verify a claim, log it as unverified and say what would settle
  it.** That is a useful finding. A guess dressed as a fact is not.

#### Two gates every finding must pass

**Self-refutation gate.** If your own impact paragraph reasons its way to "no
practical impact", "correct in practice" or "no change needed" — delete the finding,
or rewrite it as a documentation gap. One real review filed a Critical whose body
read *"Impact: None. Fix: None needed. Logged for completeness."* Do not log
findings that argue against themselves.

**One carve-out, and it is narrow.** A finding that names a documented standard the
code violates — a layout rule, an interface convention, a boundary the context doc
draws — has no behavioural impact by construction, so the gate above deletes it, and
[7b §20](phase-7b-findings-log.md) has a Minor tier defined as exactly that finding.
Keep it only when it names the standard **and** the change the violation made harder.
"This file is in the wrong directory" is the ritual the gate exists to stop; "this is
the third call site I had to edit because the helper was never extracted" is a
finding. It disposes through exit 4 in [phase 7c §21](phase-7c-verifying-findings.md).

**Intent gate.** Before proposing a fix, look for the comment, docstring or
changelog entry explaining why the code is as it is. If one exists, your fix must
engage with it. Proposing to revert a deliberate decision is allowed; doing it
without saying so is not.

#### The class check — the highest-value move available

When a finding is an instance of a pattern — a timestamp built the wrong way, a
missing filter, a validation applied in one writer — **search for every other
instance within your scope before logging it**, and log them as one finding listing
all sites. The recurring defect is never the individual line; it is fixing one
member of a class and believing the class is handled.

Three shapes pay out more than the rest, all of them "was the fix applied
everywhere":

- **Does the other surface have it?** Two front ends that cannot share code apply
  every fix twice, and the second application is the one forgotten.
- **Does the sibling branch have it?** One arm of an if/elif chain, one of three
  archive paths, one of two SQL statements in the same function.
- **Was it applied to the whole operation?** A SELECT normalised but not its COUNT;
  an export column list extended but not the matching import.

Measured, not a hunch: in one round **3 of 20 findings** were incomplete halves of
fixes from the three preceding releases, and in the rounds before it the
highest-severity finding each time had the same shape. A half-applied fix is more
dangerous than an unfixed bug, because the code reads as though the case is handled
and the next reviewer skips it for that reason.

If the pattern plausibly extends outside your scope, do not read outside your scope
to chase it. Name what you could not check in the final report; the pass that owns
those files, or a synthesis across all logs, is where it gets closed.

#### Trust-boundary priority

Anything touching fencing of untrusted content, authentication, path containment, or
an interface's exposure of stored data goes to the top of the log the moment you
find it, before you continue reviewing, and is reported immediately rather than held
for the summary. This holds whatever scope you are running.

Do not rank these by how alarming they read. A one-word key mismatch that silently
disables fencing on an unauthenticated endpoint outranks anything that merely
crashes.

Where the finding goes once you have it — file name, header, per-finding shape,
severity and the final report — is [phase 7b](phase-7b-findings-log.md). Write it
there before you read the next file.
