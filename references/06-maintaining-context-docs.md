# 6 Maintaining context docs

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

A context doc is loaded on every task in its subtree, so its size and its accuracy are
a tax on all of them. Creating the hierarchy is [5](05-context-docs.md).

**Rules**

- Root context doc near 200 lines, domain doc near 300; over budget, decide: split or prune, never compress, and never evict a trap to fit (6.1)
- Run the task without the rule before adding it; re-test the rules when the model changes, and cut a safety rule only on a test with and without it (6.2, 6.3)
- An incident buys a check, not a doc paragraph; never paste a value a command could print (6.4, 6.5)
- Every addition names what it removed (6.6)
- A rewording keeps every number, condition and "unless"; diff old against new (6.7)
- A rule scoped to a file pattern gets a glob-scoped file where the runner supports one, else the nearest doc covering the pattern - never the root (6.8)
- Write a `last-verified` date only with an audit that refreshes it; staleness the audit finds is filed as debt, not fixed silently (6.9)
- Other runners' files point at the one canonical doc, and a check asserts each pointer is still there (6.10)

### 6.1 Budget it

Keep a root context doc near 200 lines and a domain doc near 300. Over
budget, split or prune rather than compress. Treat the budget as a prompt to decide, not
a hard cap that evicts hard-won content: a traps list grows legitimately, and deleting a
trap to satisfy a line count trades a cheap tax for an expensive relearn.

### 6.2 Test before you add

Run the task without the rule first. If the agent already does
the right thing, the rule is noise. This kills more proposed lines than any budget. Where
you cannot re-run the task cheaply, add a line only for a failure you watched happen.

### 6.3 Re-test when the model changes

A rule written for one model's habit can be noise, or
over-applied, on the next. On a model change, run the tasks the rules exist for and cut
what the new model no longer needs. Hold safety rules: change one only when a test shows
the new model behaves correctly both with and without it.

### 6.4 An incident buys a check, not a paragraph

A lint rule, a CI assertion or a test
outlives a sentence nobody rereads, and this is the same preference
[25.5](25-shipping.md) states for recurring drift.

### 6.5 Never paste a value a command could print

Config snapshots and counts go stale in
place; show the command instead.

### 6.6 Every addition names what it removed

Otherwise reactive accumulation - one rule per
incident, forever - is the steady state. Of the budget rules, this is the one that actually
holds the line.

### 6.7 A rewording keeps every number, condition and "unless"

Tightening prose to fit a
budget is where a rule quietly changes: diff old against new for each qualifier, and
restore any that went. A shorter rule that drops one is a different rule. Prior art:
addyosmani/agent-skills' documentation skill.

### 6.8 A rule whose scope is a file pattern does not belong in a directory

The hierarchy is
directory-shaped, so a rule about every test file, or every migration, or every generated
file has nowhere to live but the root doc, where it loads on every unrelated task. Where
your runner supports path-scoped rule files, give that rule a small file with its glob and
let it not load at all when it does not apply - which is the cheapest possible way to stay
under the budget above. Where it does not, keep the rule in the nearest doc that covers
the pattern and accept the over-reach; do not push it to the root. Path-scoped rule files
are a harness feature rather than a portable convention, so a project adopting them is
betting on one runner - worth knowing before you restructure around it.

### 6.9 Staleness is found by tripping over it unless something dates it

Deleting stale text
immediately only works for the drift you notice; the common case is a doc that went stale
because the code around it moved. A dated `last-verified` line plus an audit cadence (Tier 2: at each release or
quarterly; Tier 3: at each audit milestone, 23.1) makes the age visible - and carries its own trap, so take it with
the rule attached: an un-refreshed date is worse than no date, because it converts
"unknown" into a confident wrong answer. Either refresh it during the audit or do not
write it. Staleness found in an audit is filed as debt, not fixed silently, or the audit
teaches you nothing about how fast your docs rot.

### 6.10 Other harnesses read other filenames

`AGENTS.md` is this strategy's convention, not a
universal one - other agent runners look for their own file. Pick the one your primary
runner reads, keep the content there, and make the others pointers to it rather than
copies. Two files with the same rules in them is the same drift as two maps, one level up. Have a
check assert each pointer still names the canonical file: a dropped pointer leaves that
runner with no rules and no error.

### 6.11 A model's quirks go in that model's file

Corrections for one model's habits - reads
instructions literally, stops early, reaches into adjacent work - belong in a small file
loaded only with that model, not in the shared doc where every other model pays for them.
Each line is a failure you observed, and the file is the first place a re-test looks.
