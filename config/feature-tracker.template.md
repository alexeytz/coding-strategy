# TODO: Project name — Feature Tracker

All planned, implemented, skipped and deferred features in one place.
**Not commitments — ideas, each with a decision or an explicit absence of one.**

**Last updated:** TODO: YYYY-MM-DD

---

## Status legend

| Status | Meaning |
|--------|---------|
| ✅ DONE | Implemented and tested |
| ⏳ BACKLOG | Not urgent, may implement later |
| 🔍 CONSIDER LATER | Worth doing, deferred for now — say what would change the answer |
| ⏭ COVERED BY #N | Already solved by another entry; name it |
| ❌ WON'T IMPLEMENT | Explicitly rejected, with the reasoning |
| ⏭ SKIP | Low value, not pursuing |

Keep the legend in the file. A status vocabulary that lives only in someone's head gets a
sixth value invented for it within a month.

---

## Features

### #0. TODO: Feature name ✅ DONE

TODO: what it is, in two or three sentences — enough that a reader who has never seen the
idea can judge the decision below.

**Decision (TODO: YYYY-MM-DD):** TODO: the verdict, then *why*. What was considered, what
was rejected, and what the alternative was. A verdict with no reasoning is re-litigated at
the next session, which is the failure this file exists to prevent.

**Design doc:** TODO: `designs/<name>.md` — or, if it was deleted, the git incantation that
recovers it: `git show <sha>^:designs/<name>.md`

---

### #1. TODO: Next feature 🔍 CONSIDER LATER

TODO: description.

**Decision (TODO: YYYY-MM-DD):** TODO: deferred, and what would change the answer — a
measurement, a user asking twice, a dependency landing. "Later" without a trigger is "never"
with extra steps.

---

## Rules for maintaining this file

Delete this section when you fill the template in; it is guidance, not content.

- **Numbers are permanent identifiers, not ordering.** Other documents, commit messages and
  review findings cite `#37`. Never renumber, never reuse a number after deleting an entry.
  Append; the file is chronological by number, not by priority.
- **Every entry ends in a dated decision, including the ones still open.** "No decision yet,
  as of YYYY-MM-DD" is a decision record. A bare description with no date is the thing that
  rots.
- **A rejection is worth more than an acceptance.** The entries that earn this file's keep are
  the ones saying *why not* — they stop a future agent proposing the change that a past
  session already priced.
- **`COVERED BY #N` is the most-skipped status and the most useful.** Two entries describing
  one need is how a feature gets built twice.
- **Point at the design doc, and at its grave.** If the design doc was deleted, record the
  `git show <sha>^:<path>` form that still resolves — a decision that outlives its reasoning
  is just an assertion.
- **This is a decision record, not a roadmap.** Nothing here is a commitment, and saying so at
  the top is what lets you write down ideas you will probably never build.
