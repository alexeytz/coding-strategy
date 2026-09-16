# Phase 9: Releasing

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

The strategy runs a loop — design, build, verify, review — and this is where it ends.
Everything up to here makes a change trustworthy; this makes it shipped, and reversible
if it should not have been. Recording what changed and why is
[2b](phase-2b-recording-and-shipping.md).

### 24. Cutting a release

**Suites green before the tag, never after.** A tag is a promise about a commit. If the
suite runs after tagging, the tag is a promise you had not checked.

#### The three-step contract

1. **Bump the version, and assert the files agree.** Any project carries the version in
   more than one place — a manifest, a module constant, a lockfile, a docs header. Write
   the script that reads all of them and fails when they diverge, and run it in the same
   gate that runs the tests. Two files claiming different versions is a release that
   cannot be reasoned about afterwards.
2. **Write the changelog entry, including what was tried and rejected.** The version
   being tagged has an entry — assert that mechanically, as
   [phase 3d §21](phase-3d-checking-what-you-claim.md) describes, so it holds whether or
   not anyone remembers this procedure. The entry's value is the part most often left
   out: the approach that did not work, so the next release does not retry it.
3. **Push an annotated tag, and push it with the commits.** An annotated tag carries who
   and when; a lightweight one is a bookmark. Push tags together with the commits they
   name, so a tag never points at something nobody else can fetch.

#### What a release changes that nothing else does

A release is the moment several documented numbers move at once — counts of tests,
supported versions, feature lists across README, docs and context files. Adding one test
changed a documented count in six files in one project, and a doc-truth check named which
six. Without that check the release is where documentation quietly goes wrong, because
it is the one commit nobody re-reads.

Two more things a release breaks that ordinary commits do not:

- **Your checks read the tree; your users get the artifact.** Build it and assert the
  invariant there ([phase 3d §21](phase-3d-checking-what-you-claim.md)). A release is
  exactly when the gap between the two becomes someone else's problem.
- **A generated file that ships is a claim about its source.** Regenerate and diff as
  part of the release, rather than trusting that whoever touched the source also ran the
  generator.

#### Before it is reversible, decide that it is

Ask what undoes this *before* pushing, not after: yanking a package, reverting a
migration, rolling back a deployment. Where the answer is "nothing", that is not a reason
to skip the question — it is the one release that needs a staged rollout or a flag, and
it is a [phase 8a §19](phase-8a-unattended-runs.md) one-way action when an agent is doing
the pushing. Where the answer is "revert the commit", say so in the changelog entry; the
person who needs it will be reading under pressure.

**Scale this to the project.** A personal tool with no consumers needs the version
assertion and the changelog entry and nothing else. The rest earns its place the first
time someone other than you installs a release.
