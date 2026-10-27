# 31 Briefing an unattended run

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

The contract agreed before the operator leaves. Running the loop, when to stop and what to hand
back is [32](32-running-unattended.md); delegating a bounded task to a subagent is
[28](28-delegating.md).

The operator leaves; an agent runs for hours and must not need a decision. **Write
the contract down.** One project reconstructed its overnight procedure from memory
twice before writing the file, which is the reason the file exists.

**Rules**

- Agree scope, autonomy, effort and what to do on failure before the operator leaves, in a table the run re-reads at its start (31.1)
- Grants are named fields in the brief that default to refusing; every step that could spend money or destroy something cites the one that allows it, and the grants that matter are also enforced where the action happens (31.2)
- Carry a budget proxy the agent can read - clock or cycles, not spend; list the one-way actions for this run (31.3)
- Ask only for what the handover did not settle - one question, then run (31.4)

### 31.1 The standing protocol

Four things, agreed before the operator leaves, kept in a table the agent re-reads
at the start of every run:

| | |
|---|---|
| **Scope** | what to work on, and what to do when that is done |
| **Autonomy** | which of: verify, fix, run suites, commit, push |
| **Effort** | how hard the agent works each item - the runner's effort or reasoning setting where it has one, else a bigger model or more passes - plus "repeat a rung before climbing" ([30.5](30-handing-work-to-a-small-model.md)) |
| **On failure** | repair what is documented, record it, continue - or stop |

### 31.2 Grants are named fields, not a sentence in the conversation

An agreement that
lives in chat cannot be cited by the agent mid-run, checked afterwards, or reused next
time. Put each permission in the brief as a named field that defaults to refusing -
`ALLOW_DESTRUCTIVE`, `ALLOW_PUSH`, `ALLOW_LONG_RUN` - and have every step that could
spend money or destroy something cite the field that authorises it: "do not delete
outputs or kill remote jobs unless `ALLOW_DESTRUCTIVE` is set and the exact target is
confirmed." A brief that will run more than once is a template plus a config, and the
renderer refuses to emit one with an unfilled slot. For a single run this layer is
overhead - write the fields inline. And note what it is not: an agent honouring a grant
it can read is a compliance assumption, not a mechanism, so the grants that matter are
also enforced where the action happens ([11.7](11-resilient-code.md)
on dry-run defaults).

### 31.3 Two more fields, because the four above are all about correctness

An agent doing
correct work passes every one of them while the money runs out or while it does
something it cannot take back.

- **A budget it can actually check.** Not spend - an agent usually cannot see its own
  spend, which is why quota sits in the operator's guide. Pick a proxy it *can* read:
  wall clock, cycles, iterations. Check it between iterations, and cross it into the
  hand-back ([32.4](32-running-unattended.md)) rather than into a new mechanism - stop cleanly at a cycle boundary
  instead of half-finishing one. The operator calibrates the proxy; a wrong calibration
  stops a healthy run, which is the cost of having one at all.
- **Reversibility, named rather than judged.** "Can this be undone?" is not decidable in
  general - a push usually can, a deploy usually cannot, a delete depends on a backup
  you have not checked. So do not ask the agent to judge it. List the actions that are
  one-way for *this* run, and make that list a stop condition ([32.3](32-running-unattended.md)).

### 31.4 Ask only if the handover did not say

One question, about whichever field of 31.1's table the handover left open, then run.
Do not stop mid-run to ask something the table already answers.

### 31.5 A scenario that does not fit is split like a review is

If the work itself is
larger than one session, splitting it is the same problem
[36.3](36-what-a-round-is-worth.md) solves for an oversized review, with a
worse failure mode: a run that hits the cap partway through leaves the last parts
unrun, nothing cleaned up and no verdict, which reads as *stalled* rather than
*failed*. Generate the parts with a script, pass the budget and turn cap explicitly
rather than inheriting a profile default, and add a check that fails when a part stops
being reachable or when state that one part sets up crosses into the next without being
carried.
