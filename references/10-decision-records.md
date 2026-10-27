# 10 Decision records

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What you decided and why, including what you decided *against* - the record a later session
reads instead of re-litigating it. Designing the change is
[8](08-designing-a-change.md); getting it out of the tree is [25](25-shipping.md).

**Rules**

- A choice, a decline or a reversal gets a numbered entry with a dated decision, open ones included; numbers are never reused or renumbered (10.1–10.3)
- Routine changes get a changelog line, not a number (10.3)
- A local patch on someone else's tree carries its removal condition and the command that verifies it (10.4)

### 10.1 One file, every idea, a dated decision

One file - `consider-features.md`, `proposed_features.md`, any name - holding every feature
idea with a dated decision. Copy `config/feature-tracker.template.md`; it carries the status
legend and the maintenance rules.

**Statuses:** DONE, BACKLOG, CONSIDER LATER, COVERED BY #N, WON'T IMPLEMENT, SKIP.

```
### #N. Feature name ❌ WON'T IMPLEMENT
Two or three sentences on what the idea is.
**Decision (YYYY-MM-DD):** The verdict, then why - what was considered and rejected.
**Design doc:** designs/<name>.md, or `git show <sha>^:designs/<name>.md` if deleted.
```

**Why:** it stops decisions being re-litigated. A future agent shouldn't wonder "why didn't we
do X?" - and worse, a review will eventually propose X as a finding, so the answer needs to be
somewhere a reviewer's intent gate ([33.5](33-running-a-review.md)) will find it.

### 10.2 Permanent numbers, dated decisions

Two rules are worth stating here because getting them wrong is expensive later; the rest
are in the template. **The number is a permanent identifier** - commits, findings and other
docs cite `#37`, so never renumber and never reuse after a delete. And **every entry ends in a
dated decision, including the open ones**: "no decision yet, as of YYYY-MM-DD" is a record, a
bare description is what rots.

### 10.3 Not every change earns a number

Number it when it chooses between alternatives, declines
something, or reverses behaviour - the cases where someone will later ask why. Exposing an
existing default as a setting, a rename, a field that follows a precedent: a changelog line is
enough, and numbering them buries the decisions among the bookkeeping.

### 10.4 Patches over someone else's tree are a record too

If the project carries local changes on a vendored or forked dependency, they need the same
treatment as a decision, and the ledger is what stops a patch outliving its reason. Each local
change is a patch file plus a row naming the upstream issue or PR, the base commit it applies to,
why it exists, and - the field that does the work - **its removal condition and the command that
verifies it**: "remove when the vendored source contains upstream PR #12907 and the resize tests
pass without this patch." A patch with no removal condition is not a patch, it is a permanent
fork, and should be named one.

Close it mechanically in both directions, because this is the record that decays exactly when it
matters most - when nobody is watching upstream any more. Two ordinary tests do it: every patch
file appears in the ledger, and each one reverse-applies against the tree, which proves it is
*currently applied* rather than merely filed. The prose half of the ledger - who last looked
upstream and why they did not rebase - is worth writing and will rot; the two tests will not.
