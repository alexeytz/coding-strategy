# 27 Handover

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

The document a new session reads first, so it can start where the last one stopped.
Declaring a milestone done is [23](23-audit-milestones.md).

**Rules**

- `handover.md` carries load order, current state, recent commits, test status, remaining work, known limitations, session chain - commands and bands, not counts (27.1)
- Keep "settled with measurements" and "traps, each one paid for", symptom first (27.2)
- A wrong entry is corrected in place, not left beside its correction (27.4)
- A session's notes are merged into the current state, never appended; keep it near 300 lines, checked by a test; over it, condense and move detail recorded nowhere else to `handover-details.md` (27.6)
- Create `handover.md` only where 32 lists it or the project already keeps one; otherwise the hand-back is a message (27.5)

### 27.1 Required sections

Structured markdown, for session continuity:
- Load order (what to read first, in order)
- Current state (version, key features - cite bands, not counts: [16.7](16-checking-what-you-claim.md))
- Recent commits (the command that lists them, e.g. `git log --oneline -15` - a hand-kept table goes stale)
- Testing status (the command, and the date and verdict of the last run - not a test count)
- Remaining work (prioritized table)
- Known limitations (bullet list)
- Session chain (the commit log, or the session file where the project keeps one)

### 27.2 Two sections worth more than the rest

- **Settled with measurements - do not re-open without new evidence.** Each entry:
  the question, the number that answered it, the date. This is what stops a later
  session (or a review) from proposing the change that caused the bug the code
  exists to prevent.
- **Traps, each one paid for.** The things that are expensive to relearn: the
  environment quirk, the flag that must be passed, the command that looks like it
  worked. Write the symptom first - that is what the next reader will be searching
  for - then the cause, then the fix.

### 27.3 How it ends, and where it lives

**Ends with an instruction:** "Load these docs in order above, then ask the user: What do you need to do?"

**Location:** `handover.md` in repo root. Updated after every significant session.

### 27.4 Correct it in place when it is wrong

One project's handover carried a note
saying a set of test failures was environmental and must not be fixed in code; five
of the six were a real bug. The note stayed for weeks and cost real time. A handover
is a claim about the present, so an entry that turns out to be wrong is rewritten
with what was learned - not left standing beside its correction.

### 27.5 Only where the project keeps one

`handover.md` is standing project apparatus: Tier 3 in [1.3](01-sizing-to-the-project.md), or an
exception the project's `AGENTS.md` records. A session or an unattended run in a project without
one does not create it. Its hand-back is the final message ([32.4](32-running-unattended.md)),
and what must outlive the session goes in the commits. Where a project has one, update it -
that is what 27.3's "after every significant session" means.

In a test of this skill, 8 of 20 overnight runs on a two-file repository wrote a `handover.md`
nobody had asked for, citing this file and [32](32-running-unattended.md); the small-project tier says not to.

### 27.6 Merge a session in; do not append it

A handover that grows by a section per session stops being read: one reached 2,759 lines, and
a new session loads the history to find the present. 27.4 says to correct a wrong entry in
place; this is its mechanism. At the end of a session, fold what changed into the sections
that hold it - current state, settled, traps, remaining work - and delete what no longer holds;
the commits and their messages keep the history. Budget it like a domain doc, near 300 lines
([6.1](06-maintaining-context-docs.md)), as a prompt to decide rather than a cap, and put the
count in the project's doc checks ([16.5](16-checking-what-you-claim.md)) so the growth is
seen when it happens, not when a session runs out of room.

Over the budget, condense before you delete. Cut an entry to its conclusion and move the detail
that is recorded nowhere else - in no commit message, test record or other doc - word for word
into `handover-details.md`, linked from the entry. Grep each fact where it is said to live before
cutting it: one trim here found four with no other record. Measure the cut in bytes as well as
lines; a table row is one line however long it is.
