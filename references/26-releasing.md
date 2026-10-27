# 26 Releasing

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

The strategy runs a loop - design, build, verify, review - and this is where it ends.
Everything up to here makes a change trustworthy; this makes it shipped, and reversible
if it should not have been. Recording what changed and why is
[25](25-shipping.md); what you decided against is [10](10-decision-records.md).

**Rules**

- Suites green before the tag, never after (26.1)
- A script asserts every file carrying the version agrees (26.2)
- The tagged version has a changelog entry saying what was tried and rejected, asserted mechanically; tags are annotated and pushed with their commits (26.2)
- Decide what undoes the release before pushing it; schema changes go additive first, destructive last and alone (26.4)
- A personal tool with no consumers needs only green suites, the version assertion and the changelog entry (26.5)

### 26.1 Suites green before the tag, never after

A tag is a promise about a commit. If the
suite runs after tagging, the tag is a promise you had not checked.

### 26.2 The three-step contract

1. **Bump the version, and assert the files agree.** Any project carries the version in
   more than one place - a manifest, a module constant, a lockfile, a docs header. Write
   the script that reads all of them and fails when they diverge, and run it in the same
   gate that runs the tests. Two files claiming different versions is a release that
   cannot be reasoned about afterwards.
2. **Write the changelog entry, including what was tried and rejected.** The version
   being tagged has an entry - assert that mechanically, as
   [16.6](16-checking-what-you-claim.md) describes, so it holds whether or
   not anyone remembers this procedure. The entry's value is the part most often left
   out: the approach that did not work, so the next release does not retry it.
3. **Push an annotated tag, and push it with the commits.** An annotated tag carries who
   and when; a lightweight one is a bookmark. Push tags together with the commits they
   name, so a tag never points at something nobody else can fetch.

### 26.3 What a release changes that nothing else does

A release is the moment several documented numbers move at once - counts of tests,
supported versions, feature lists across README, docs and context files. Adding one test
changed a documented count in six files in one project, and a doc-truth check named which
six. Without that check the release is where documentation quietly goes wrong, because
it is the one commit nobody re-reads.

Two more things a release breaks that ordinary commits do not:

- **Your checks read the tree; your users get the artifact.** Build it and assert the
  invariant there ([16.1](16-checking-what-you-claim.md)). A release is
  exactly when the gap between the two becomes someone else's problem.
- **A generated file that ships is a claim about its source.** Regenerate and diff as
  part of the release, rather than trusting that whoever touched the source also ran the
  generator.

### 26.4 Before it is reversible, decide that it is

Ask what undoes this *before* pushing, not after: yanking a package, reverting a
migration, rolling back a deployment. Where the answer is "nothing", that is not a reason
to skip the question - it is the one release that needs a staged rollout or a flag, and
it is a [31.3](31-briefing-an-unattended-run.md) one-way action when an agent is doing
the pushing. Where the answer is "revert the commit", say so in the changelog entry; the
person who needs it will be reading under pressure.

"Revert the commit" only holds if the schema still fits the old code. So a release never
renames or drops a column in the same release that stops using it: add the new shape
alongside, switch reads and writes, and drop the old one in a later release once nothing
references it. Additive first, destructive last and alone. Prior art: addyosmani/agent-skills'
deprecation skill.

### 26.5 Scale this to the project

A personal tool with no consumers needs green suites, the
version assertion and the changelog entry, and nothing else. The rest earns its place the first
time someone other than you installs a release.
