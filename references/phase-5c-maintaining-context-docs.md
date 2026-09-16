# Phase 5c: Maintaining context docs

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

A context doc is loaded on every task in its subtree, so its size and its accuracy are
a tax on all of them. Creating the hierarchy is [5a](phase-5a-context-docs.md).

### 22. Keeping a context doc worth loading

A context doc is loaded on every task in its subtree, so its size is a tax on all of them.
Four rules, and the last is the one that actually holds the line:

- **Budget it.** Keep a root context doc near 200 lines and a domain doc near 300. Over
  budget, split or prune rather than compress. Treat the budget as a prompt to decide, not
  a hard cap that evicts hard-won content: a traps list grows legitimately, and deleting a
  trap to satisfy a line count trades a cheap tax for an expensive relearn.
- **Test before you add.** Run the task without the rule first. If the agent already does
  the right thing, the rule is noise. This kills more proposed lines than any budget.
- **An incident buys a check, not a paragraph.** A lint rule, a CI assertion or a test
  outlives a sentence nobody rereads, and this is the same preference
  [phase 2b §6](phase-2b-recording-and-shipping.md) states for recurring drift.
- **Never paste a value a command could print.** Config snapshots and counts go stale in
  place; show the command instead.
- **Every addition names what it removed.** Otherwise reactive accumulation — one rule per
  incident, forever — is the steady state.

**A rule whose scope is a file pattern does not belong in a directory.** The hierarchy is
directory-shaped, so a rule about every test file, or every migration, or every generated
file has nowhere to live but the root doc, where it loads on every unrelated task. Where
your runner supports path-scoped rule files, give that rule a small file with its glob and
let it not load at all when it does not apply — which is the cheapest possible way to stay
under the budget above. Where it does not, keep the rule in the nearest doc that covers
the pattern and accept the over-reach; do not push it to the root. Path-scoped rule files
are a harness feature rather than a portable convention, so a project adopting them is
betting on one runner — worth knowing before you restructure around it.

**Staleness is found by tripping over it unless something dates it.** Deleting stale text
immediately only works for the drift you notice; the common case is a doc that went stale
because the code around it moved. A dated `last-verified` line plus an audit cadence tied
to the project's tier makes the age visible — and carries its own trap, so take it with
the rule attached: an un-refreshed date is worse than no date, because it converts
"unknown" into a confident wrong answer. Either refresh it during the audit or do not
write it. Staleness found in an audit is filed as debt, not fixed silently, or the audit
teaches you nothing about how fast your docs rot.

**Other harnesses read other filenames.** `AGENTS.md` is this strategy's convention, not a
universal one — other agent runners look for their own file. Pick the one your primary
runner reads, keep the content there, and make the others pointers to it rather than
copies. Two files with the same rules in them is the same drift as two maps, one level up.
