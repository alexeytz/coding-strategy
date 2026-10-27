# 33 Running a review

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Auditing code that already exists - yours, an agent's or a contributor's: how to read
it and what counts as a finding. Recording findings is [34](34-findings-log.md); deciding what to
do with them is [35](35-verifying-findings.md).

**Rules**

- Before opening code, read whichever the project keeps of the root context doc, the trust-boundary doc and the handover's traps and settled sections; a finding contradicting one names it and says why it is out of date (33.1)
- Old findings files are leads to re-verify, never context (33.2)
- Verify before logging and quote what you read; never report an observation you did not make, and log what you cannot verify as unverified (33.3)
- An impact paragraph reaching "no practical impact" deletes the finding, unless it names a documented standard and the change the violation made harder (33.4)
- Engage with the comment, changelog or decision record explaining the behaviour before proposing a fix (33.5)
- Log a pattern once with every instance in scope; check the fix reached every surface, branch and operation (33.6)
- Scan every diff for weakened gates; one that silences its failure with nothing in the diff to justify it goes to a human - its commit message does not count (33.8)
- Trust-boundary findings go to the top of the log and are reported at once (33.9)

### 33.1 Orient before reading any implementation file

Read whichever of these the
project keeps, in full, whatever your scope: the root context doc, the trust-boundary doc,
and the handover's "traps" and "settled with measurements" sections. Then read your scope's
in/out list. Only then open code.

A codebase that documents its decisions will look wrong in places where it is
deliberate. A finding that contradicts one of those documents is not automatically
wrong, but it must name the document and say why the document is out of date.
Reviews that skip this step reliably recommend the change that caused the bug the
code exists to prevent.

### 33.2 Do not read previous reviews' findings files

They mix findings that were fixed
with findings that were disproved, and treating them as context imports both. The
changelog records dispositions; a findings file is scratch. Use one only for leads to verify
again and declines not to re-file.

### 33.3 Rules of evidence

- **Verify before logging.** Follow the call chain and read the surrounding lines,
  not the line you noticed. Most false findings come from reading one line: a regex
  that "misses capitals" when the input was lowercased four lines above, an
  exception that "escapes" a handler catching its base class.
- **Quote what you read** - file, line, code. A claim about behaviour across two
  functions quotes both.
- **Never report an observation you did not make.** No timings, memory figures,
  process listings or production symptoms unless you ran something and can say
  what. An invented measurement attached to a wrong finding is the most damaging
  artifact a review can produce, because it makes the finding credible enough to
  act on.
- **If you cannot verify a claim, log it as unverified and say what would settle
  it.** That is a useful finding. A guess dressed as a fact is not.

### 33.4 The self-refutation gate

If your own impact paragraph reasons its way to "no
practical impact", "correct in practice" or "no change needed" - delete the finding,
or rewrite it as a documentation gap. One real review filed a Critical whose body
read *"Impact: None. Fix: None needed. Logged for completeness."*

**One carve-out, and it is narrow.** A finding that names a documented standard the
code violates - a layout rule, an interface convention, a boundary the context doc
draws - has no behavioural impact by construction, so the gate above deletes it, and
[34.4](34-findings-log.md) has a Minor tier defined as exactly that finding.
Keep it only when it names the standard **and** the change the violation made harder.
"This file is in the wrong directory" is the ritual the gate exists to stop; "this is
the third call site I had to edit because the helper was never extracted" is a
finding. It disposes through exit 4 in [35.5](35-verifying-findings.md).

### 33.5 The intent gate

Before proposing a fix, look for the comment, docstring,
changelog entry or decision record ([10](10-decision-records.md)) explaining why the code is
as it is; for something deliberately never built, the decision record is the only one. If one exists, your fix must
engage with it. Proposing to revert a deliberate decision is allowed; doing it
without saying so is not.

### 33.6 The class check - the highest-value move

When a finding is an instance of a pattern - a timestamp built the wrong way, a
missing filter, a validation applied in one writer - **search for every other
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
dangerous than an unfixed bug, because the code reads as handled and the next
reviewer skips it.

If the pattern plausibly extends outside your scope, do not read outside your scope
to chase it. Name what you could not check in the final report; the pass that owns
those files, or a synthesis across all logs, is where it gets closed.

### 33.7 Does every consumer handle the new value?

A diff adding an enum
member, a status or a wider input usually breaks outside the diff - read every consumer in
scope and name the rest.

### 33.8 Scan the diff for gates it weakened

A change that turned a red suite green is the likeliest to have weakened it. Tag each hunk
that:

- deletes, skips or expects-to-fail a test
- adds a suppression pragma or swallows an exception
- raises a timeout, retry count or tolerance, or lowers a threshold
- loosens an exact assertion to a bound
- regenerates a snapshot, its test unchanged
- adds `--no-verify` or continue-on-error
- branches product code on running under test
- swaps an implementation for a stub, a `TODO` or a not-implemented raise
- changes an expected value in a commit claiming no behaviour change

Ask of each: does it silence the failure it was added for, with nothing in this diff to
justify it? A yes goes to a human, not an auto-fix; a commit message does not clear it - the
author being checked wrote it. Prior art: gstack's gate-integrity
review.

### 33.9 Trust-boundary priority

Anything touching a [trust boundary](12-trust-boundaries.md), authentication, or
an interface's exposure of stored data goes to the top of the log the moment you
find it, before you continue reviewing, and is reported immediately rather than held
for the summary. This holds whatever scope you are running.

Do not rank these by how alarming they read. A one-word key mismatch that silently
disables fencing on an unauthenticated endpoint outranks anything that merely
crashes.

Where the finding goes once you have it - file name, header, per-finding shape,
severity and the final report - is [34](34-findings-log.md). Write it
there before you read the next file.
