# 19 Instrumentation

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Being able to believe what you measured. Most rules here cost a debugging session,
and most are this strategy's own rules applied to its tooling - which is exactly
where they get forgotten. Running the loop itself is [32](32-running-unattended.md).

**Rules**

- Verify instrumentation before believing it; a measurement disagreeing with the system's own health check is the suspect (19.1)
- Count by listing what you found and reading the list; gate a background waiter on its output file, never a process match (19.3, 19.4)
- Bound log inspection to the session, and stamp the entry point on a shared log (19.6, 19.7)
- A setting handed to a tool you did not write is a claim until you see it at the boundary; check every request, not one (19.8)
- A check opens what it reads read-only and must-exist, and a test asserts it wrote nothing (19.9)

### 19.1 Verify the instrumentation before believing it

A debug spy that consumed an
error response body made a working repair look broken. A census script that opened
the store under a slightly misspelled name reported zero records for a healthy
system, and the "restore" that followed was the only thing that ever damaged it.
**When a measurement disagrees with the system's own health check, suspect the
measurement.**

### 19.2 Prove the instrument can fail before the run, not during it

"Verify the
instrumentation" is the rule; the mechanism is a known-good input that must pass
and a plausible-wrong one that must fail, run as a precondition rather than as a
flag - one project's judge refuses the whole matrix when it cannot rank the pair
correctly. See [24.4](24-quality-gates.md).

### 19.3 A count is not a membership test

`ps -ef | grep -c` reported three leftover
servers where there were none - the pipeline matched itself. Count by listing what
you found and reading the list.

### 19.4 Process-matching predicates match themselves

An
`until ! pgrep -f "run-regression.py"; do sleep 15; done` waiter contains that
string, matches its own command line and never exits; it polled for hours before
anyone noticed, because it was blocked before its first line of output. Gate
background waiters on their **output file** instead. In the same environment
`kill`/`pkill` aborted the calling shell command, so run them alone and verify
afterwards rather than chaining.

### 19.5 A silent background task is indistinguishable from an absent one

A monitor
whose patterns match only failures prints nothing on a healthy run and outlives
what it was watching - one survived sixteen hours. Enumerate what you started, and
at the end confirm each is stopped by *listing*, not by counting.

### 19.6 Bound log inspection to the session

An incident report once named the wrong
root cause because a bare `HH:MM` grep against a log that appends across sessions
for weeks read every previous day at that clock time as one timeline. Scan between
the session's own start markers, and build that boundary into the gate script
rather than trusting each reader to remember.

### 19.7 Stamp the entry point on a shared log

The same failure on the other axis: when a
scheduler, the CLI and a replay all write to one log, attribution falls back to guessing.
Record which entry point started the run beside its run ID, set where the run begins and
carried through queues and headers, never inferred downstream; a field that merely
correlates with an entry point is a hint, not an attribution. Prior art, not an incident
here: addyosmani/agent-skills' observability skill.

### 19.8 A setting handed to someone else's tool is a claim until you see it on the wire

A dependency can accept a setting and not apply it: no error, no warning, the run looks
configured. One measurement project found four agent harnesses doing it - thinking turned off
went out as "low", sampling settings were never sent, a level reached a custom provider as
nothing - and one of them only after 156 runs had been voided for other reasons. 19.1 is about
your own instruments; this is the one you configured and cannot read. Check the effect where it
leaves your hands: the request on the wire, the file the tool wrote, the flag in the child's
command line. And check it on every request, not once: a proxy that compares each request with
what was configured and refuses a mismatch is what held there, because a dependency's next
release can change what it drops.

### 19.9 A check must not create what it checks

`sqlite3` handed a path with a literal `~` created an empty database, and the residue check
read zero rows - in two consecutive cycles. Elsewhere a read-only reader issued a write pragma,
a diagnostic registered ids that a delete gate then honoured, and an environment check imported
a module whose import ran a sync that evicted a plugin from seven configs. Open what a check
reads read-only and must-exist, keep imports with side effects out of it, and assert in a test
that it changed nothing.
