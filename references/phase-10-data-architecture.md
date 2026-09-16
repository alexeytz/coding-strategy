# Phase 10: Data architecture

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) — full names in [SKILL.md](../SKILL.md)

---

One job: **you have more than one copy of the data.** A cache, a search index, a vector
store, a denormalised table, a read replica. The rules below all answer one question —
which copy is authoritative, how is every other copy rebuilt from it, and what must a
process prove before it deletes from one on the strength of another. Where code goes is
[1a](phase-1a-layout.md); config layout is [1b](phase-1b-config-and-setup.md).

### 25. More than one copy of the data

**Name the source of truth in one sentence, and put it where a recovery reads it.**
"The relational database is the source of truth; the vector store holds vectors derived
from it and can always be rebuilt." That sentence drives every recovery path there is —
what to rebuild, which side to believe when they disagree, and what a sync check is
checking. **A derived store that cannot be rebuilt from the source is a second source of
truth that nobody declared**, and you will find out which it is during an incident.

**A destructive reconciliation proves it has authority before it deletes.** An orphan
sweep that deletes index entries whose key is missing from the database is correct right
up until the database it is reading is the wrong one — empty, partially loaded, or
pointed at a different environment. Two incidents in one project wiped 44 and then ~90
vectors exactly that way. Before deleting on the strength of another store, refuse when:

- the authority has no active rows at all,
- it has fewer rows than the number of items about to be deleted,
- it shares none of the specific keys under consideration, or
- the count could not be taken.

Dry-run defaults ([phase 3a §8](phase-3a-writing-resilient-code.md)) do not cover this.
This is maintenance that runs on its own schedule, not a user-invoked destructive action,
so nobody is watching for the confirmation prompt.

**Namespace a derived store by whatever determines its semantics, not by a proxy.** Name
a vector collection for the embedding model, not the dimension: two different 4096-dim
models share a size and not an embedding space, so a dimension check passes while
silently mixing two incompatible spaces. The general form — key the namespace on the
thing that would make two datasets incomparable, and never on a property that merely
correlates with it.

**Give tests their own namespace on a shared real service.**
[Phase 3b §9](phase-3b-verifying.md) says temp dirs and mocked externals, which is not
available when the external *is* a real shared service you cannot mock. Then isolation
is a configurable prefix or collection name the suite sets, verified before the first
test writes anything. One project's suite wrote into live production data until it got
one. Where that prefix is missing, the correct behaviour is to refuse to run.

**A sync check is a first-class operation, not a debugging convenience.** Ship the
command that answers "do these two stores still agree", give it an exit code derived from
the same predicate its report prints ([phase 3d §23](phase-3d-checking-what-you-claim.md)),
and run it before and after anything that touches both. It is also what makes
[phase 8b §20](phase-8b-instrumentation.md)'s "believe the system's own health check"
actionable rather than aspirational — without it, there is no health check to believe.

**When this phase does not apply.** One store, no cache, no index: skip it entirely. The
moment you add the second copy, come back — the cost of these rules is small and the cost
of learning them from an incident is not.
