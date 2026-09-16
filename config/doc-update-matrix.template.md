# TODO: Project name — documentation update matrix

What else has to move when something changes. Walk this before every commit; the point is
that "docs ship with the change" needs a *list*, because the docs that go stale are the ones
nobody remembered were downstream of the edit.

Fill in the right-hand column with real paths for this project. A row whose targets you
cannot name is a row you will skip.

**Wherever a row's target can be checked by a script, write the check instead of trusting the
row.** The matrix is the fallback for what cannot be automated, not the primary mechanism —
a rule enforced only by a human reading a table drifts at the same rate as the docs it
guards.

---

## The matrix

| The change | What else must move | Guarded by |
|---|---|---|
| A test added, renamed or removed | TODO: every file stating a test count; the living test plan's case list and results table | TODO: doc-truth test |
| A behavioural change to a public surface | TODO: generated tool/API reference; README; the acceptance or e2e script that exercises it | TODO: |
| A new config key or environment variable | TODO: `.env.example`; the config reference; the precedence note if it interacts with a layer | TODO: |
| A new file, module or directory | TODO: the nearest owning `AGENTS.md`; any file-inventory or line-count table | TODO: |
| A file deleted | TODO: every doc citing it — and if it carried reasoning, leave the `git show <sha>^:<path>` pointer that still resolves | TODO: link/path check |
| A bug fixed | TODO: changelog entry saying *why*, including what was tried and rejected; a regression test that fails against the pre-fix tree; a handover "trap" entry if it was expensive to find | TODO: |
| A version bumped | TODO: changelog entry naming that version; the tag | TODO: release check |
| A new rule or invariant stated in a doc | TODO: the guard that makes it fail mechanically — a rule with no check is a preference | TODO: |
| A decision made, deferred or rejected | TODO: the decision log entry, dated and numbered | TODO: |

Add a row the first time a doc goes stale for a reason not already listed. That is the only
way this file stays honest — it is a postmortem list, and every row should be traceable to
something that actually drifted.

---

## The sweep, before each commit

1. **Run the doc-truth checks.** They answer the mechanical half — counts, references,
   generated files, cited paths.
2. **Read `git diff --cached --name-only` against the matrix.** For each change class present
   in the staged diff, open the targets and confirm they still say something true.
3. **Write the changelog entry now, not at release time.** The reasoning is in your head today
   and gone next week; a changelog reconstructed at tag time records what changed and loses
   why, which is the half that stops the change being re-litigated.
4. **Fix what drifted, in the same commit.** A follow-up commit is a promise, and the docs
   that go stale are the ones whose follow-up never came.

If step 2 finds the same class of drift twice, stop doing step 2 for it and write a check.
