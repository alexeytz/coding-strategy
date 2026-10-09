# Phase 2b: Decision records

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2c](phase-2c-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [3g](phase-3g-verifying-against-real-targets.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) · [11](phase-11-debugging.md) — full names in [SKILL.md](../SKILL.md)

---

What you decided and why, including what you decided *against* — the record a later session
reads instead of re-litigating it. Designing the change is
[2a](phase-2a-designing-a-change.md); getting it out of the tree is [2c](phase-2c-shipping.md).

### 5. Decision Records

One file — `consider-features.md`, `proposed_features.md`, any name — holding every feature
idea with a dated decision. Copy `config/feature-tracker.template.md`; it carries the status
legend and the maintenance rules.

**Statuses:** DONE, BACKLOG, CONSIDER LATER, COVERED BY #N, WON'T IMPLEMENT, SKIP.

```
### #N. Feature name ❌ WON'T IMPLEMENT
Two or three sentences on what the idea is.
**Decision (YYYY-MM-DD):** The verdict, then why — what was considered and rejected.
**Design doc:** designs/<name>.md, or `git show <sha>^:designs/<name>.md` if deleted.
```

**Why:** it stops decisions being re-litigated. A future agent shouldn't wonder "why didn't we
do X?" — and worse, a review will eventually propose X as a finding, so the answer needs to be
somewhere a reviewer's intent gate ([phase 7a](phase-7a-running-a-review.md)) will find it.

Two rules are worth stating here because getting them wrong is expensive later; the rest
are in the template. **The number is a permanent identifier** — commits, findings and other
docs cite `#37`, so never renumber and never reuse after a delete. And **every entry ends in a
dated decision, including the open ones**: "no decision yet, as of YYYY-MM-DD" is a record, a
bare description is what rots.

**Not every change earns a number.** Number it when it chooses between alternatives, declines
something, or reverses behaviour — the cases where someone will later ask why. Exposing an
existing default as a setting, a rename, a field that follows a precedent: a changelog line is
enough, and numbering them buries the decisions among the bookkeeping.

#### Patches over someone else's tree are a record too

If the project carries local changes on a vendored or forked dependency, they need the same
treatment as a decision, and the ledger is what stops a patch outliving its reason. Each local
change is a patch file plus a row naming the upstream issue or PR, the base commit it applies to,
why it exists, and — the field that does the work — **its removal condition and the command that
verifies it**: "remove when the vendored source contains upstream PR #12907 and the resize tests
pass without this patch." A patch with no removal condition is not a patch, it is a permanent
fork, and should be named one.

Close it mechanically in both directions, because this is the record that decays exactly when it
matters most — when nobody is watching upstream any more. Two ordinary tests do it: every patch
file appears in the ledger, and each one reverse-applies against the tree, which proves it is
*currently applied* rather than merely filed. The prose half of the ledger — who last looked
upstream and why they did not rebase — is worth writing and will rot; the two tests will not.
