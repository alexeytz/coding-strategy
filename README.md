# coding-strategy

Language-agnostic patterns for running a software project with coding agents — structure,
design docs, resilience, testing, reviews, unattended runs, releases, data architecture.

It ships **documentation, not code**. The product is [`SKILL.md`](SKILL.md) and the files it
routes to.

## The idea

Most strategy documents fail the same way: they grow until nobody loads them, and then nobody
follows them. This one is a **routing table**. You never load the whole strategy — `SKILL.md`
maps a trigger ("about to commit", "auditing code you did not write", "running for hours with
nobody watching") to exactly one file, and that file is one job, sized to be loaded on its own.

Twenty-one phase files hold twenty-five numbered sections. Each section lives in exactly one
file, and a test asserts it.

## Using it

**As a skill.** Drop the repo where your agent runner looks for skills. `SKILL.md`'s frontmatter
describes when it should fire; the routing table decides what gets read.

**By hand.** Open [`SKILL.md`](SKILL.md), find the row matching what you are about to do, read
that one file.

**Under a tight context budget.** Load [`references/rules-card.md`](references/rules-card.md)
(building) or [`references/rules-card-operating.md`](references/rules-card-operating.md) (docs,
delegation, review, unattended runs) instead. One line per rule, no rationale — they are a
selection of what changes an agent's behaviour on an ordinary task, not an index of everything.

**Driving a small or local model?** Read
[`references/small-model-operation.md`](references/small-model-operation.md) first. It covers why
small models degrade — distractor load, constraint capacity, positional dilution — and the
working-set budget that answers it.

## Adopting it in your project

[`config/`](config/) holds copy targets, documented in [`config/README.md`](config/README.md):
AGENTS.md templates, a pre-commit secret-scanning hook with a gitleaks config, a feature tracker,
a doc-update matrix, an `.env.example`. Copy them, then edit the copy — they are meant to be
overwritten cleanly by a later update.

Start with [`references/project-checklist.md`](references/project-checklist.md), which tiers the
ceremony by project size. **Most projects should skip most of this.** A fifteen-file tool does
not need a findings backlog or a handover protocol, and the checklist says so.

## Why the rules have arguments attached

Every rule here came from something that broke, and most carry the incident that bought them:
the pipeline that exited with `head`'s status so a CI check could only ever pass; the secret
scanner that allowlisted `docs/`, so the same token blocked in `src/` and committed clean in
`docs/`; the pre-commit hook that blocked *every* commit because its scanner's self-update failed
before it scanned anything.

Rules without their reasons get followed until they are inconvenient, then dropped. Rules with a
paid-for example attached tend to survive contact.

Most sections also carry the argument **against** the rule. That is deliberate — a rule you
cannot argue against is one nobody finished thinking about.

## It enforces its own rules

```sh
tests/check-docs.sh              # structural checks. No network, no install.
tests/check-docs.sh --self-test  # seed a break for each guard, require it to fail
```

The suite asserts what the strategy claims: links resolve, the routing table matches what is on
disk, sections appear exactly once, no reference file exceeds its size budget, prose cross-
references point at the file that actually holds the section.

`--self-test` exists because guards rot. Three of this project's own bugs were checks that had
silently stopped matching the tree — one of them reported **PASS** on input it could not parse.
A green check is not evidence until you have seen it go red.

## Honest limits

- **Extracted, not derived.** These patterns come from real projects, so they carry those
  projects' shapes. Multi-service and polyrepo layout is
  [deliberately out of scope](references/phase-6-reference.md), with the reason.
- **The suite tests the documents, never the behaviour.** Nothing here proves an agent follows
  the rules; it proves the documents are internally consistent. Closing that gap needs enough
  repeated runs to separate compliance from noise, which is an expense rather than a check.
- **Not dogma.** Every phase file says so in its own header. Scale it down; the checklist tells
  you where.

## Repository map

| Path | What |
|---|---|
| [`SKILL.md`](SKILL.md) | The routing table. This is the product |
| [`references/`](references/) | 21 phase files, the two rules cards, the tiering checklist, small-model guidance |
| [`config/`](config/) | Copy targets for projects adopting this |
| [`operator-guide.md`](operator-guide.md) | The human's half: quota, tool routing, hosting custody, decisions an agent must not make alone |
| [`tests/`](tests/) | The structural suite that keeps the above honest |

Development of this skill — design docs, the backlog of lessons harvested from other projects,
the bug log, and session handovers — lives in a separate repository. This one carries the skill.

## Licence

MIT — see [LICENSE](LICENSE).

Rules in this skill are illustrated with incidents observed in real projects. Where a phase file
quotes or cites an outside project, it is cited as prior art and attributed by name — not
endorsed by, nor affiliated with, this project.
