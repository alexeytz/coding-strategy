# Phase 5a: Context docs

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

### 15. Authoring the AGENTS.md hierarchy

When joining a project, inspect it and decide whether AGENTS.md is needed using the rubric
below. For the rules that apply once the docs exist — reading the chain before editing,
updating it after — see [phase 5b](phase-5b-working-and-delegating.md).

**The rubric for what belongs in the top-level doc, in one line:** it is not a
description of the project — that is the README and the architecture doc — **it is
the set of things that are expensive to relearn.** Test it entry by entry: would a
competent reader work this out in two minutes from the code? Then cut it. Did
someone lose an afternoon to it? Then it belongs, with the symptom stated first,
because the symptom is what the next reader will search for.

#### When to create AGENTS.md (evaluation rubric)

Inspect the project before deciding. Run these checks:

```
# Count non-hidden, non-vendor files (excluding build artifacts)
find . -type f \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -path './vendor/*' \
  -not -path './dist/*' \
  -not -path './build/*' \
  -not -path './__pycache__/*' \
  -not -name '*.pyc' \
  | wc -l

# Count top-level directories that look like domains (contain source code)
ls -d */ | while read d; do
  files=$(find "$d" -maxdepth 1 -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" 2>/dev/null | wc -l)
  if [ "$files" -gt 0 ]; then echo "$d ($files source files)"; fi
done
```

**Decision thresholds:**

| Condition | Verdict | Action |
|-----------|---------|--------|
| **< 15 files, < 3 source domains** | SKIP | A README.md is sufficient. No AGENTS.md needed. |
| **15-50 files, or 3-5 source domains** | CREATE ROOT | Create a single `AGENTS.md` at repo root. Cover purpose, structure, conventions. |
| **50+ files, or 5+ source domains** | CREATE HIERARCHY | Root `AGENTS.md` + child `AGENTS.md` in each domain folder. |
| **Existing AGENTS.md but > 30 days since update** | REVIEW | Read it. If structure changed (new domains, renamed modules), update it. |
| **Agent is duplicating code or creating files in wrong place** | CREATE IMMEDIATELY | Symptom of missing context. Stop, create AGENTS.md, resume. |

**Signals that AGENTS.md is overdue (even if thresholds aren't met):**
- Two or more contributors/agents working on the same repo
- Non-obvious conventions (e.g., "tests live in `tests/unit/` and `tests/integration/`, not alongside source")
- Domain-specific naming patterns that differ between folders
- The agent has asked "where should this file go?" during the session

**If the project has no AGENTS.md and meets the CREATE threshold:** create it before writing code. Spend ~5 minutes scanning the repo, then generate the root AGENTS.md with purpose, ownership, key files, and a child index.

**Use hierarchical AGENTS.md files, one per domain folder.**

```
project/
  AGENTS.md              # Root: global rules, project-wide conventions, Child DOX Index
  api/
    AGENTS.md            # Domain: API endpoints, routes, auth, response format
    types/
      AGENTS.md          # Domain: internal types, serialization, validation
  engine/
    AGENTS.md            # Domain: pipeline stages, data flow, error handling
  features/
    AGENTS.md            # Domain: feature list, cross-cutting rules, Child DOX Index
    export/
      AGENTS.md          # Domain: export formats, file naming, output paths
```

#### Hierarchy rules

- Root `AGENTS.md` is the rail: project-wide instructions, global preferences, top-level index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific it must be
- Broad rules in parent docs, concrete details in child docs
- Do not duplicate rules across files unless each scope needs a local version

#### Child doc shape

Create a child `AGENTS.md` when a folder becomes a durable boundary with its own purpose, rules, or workflow.

Default section order:
- **Purpose** — what this folder/domain does
- **Ownership** — who/what owns changes here
- **Local Contracts** — rules specific to this domain
- **Work Guidance** — how to make changes here (conventions, patterns)
- **Verification** — how to test/verify changes
- **Child DOX Index** — list of subfolder AGENTS.md files with one-line descriptions

#### Area-level context schema

Each `areas/<domain>-structure.md` follows a fixed shape:
- **Purpose** — 2-3 sentences on what this domain does
- **Key files** — list of critical files and their role
- **Inputs/outputs** — API endpoints, props, events, data contracts
- **Dependencies** — what other domains this domain relies on
- **Common pitfalls** — non-obvious failure modes specific to this area
- **Change checklist** — what to verify after modifying this domain

This sits between AGENTS.md (rules and conventions) and design docs (architectural decisions) — it's the "what lives here and how does it connect" layer.

#### Cross-reference index

Mandatory rather than optional when driving a small model: the map is what lets it open three
files instead of thirty ([small-model-operation.md](small-model-operation.md)).

**Keep one map, and prefer the flat one.** A hierarchy of docs *and* a flat index of the
same docs is two maps of one territory, and the second is the one nobody updates — the
drift generator this phase otherwise exists to prevent. Where a project wants the quick
lookup, `docs/context-index.md` is a single `File | Domain | When to use` table and the
AGENTS.md files carry no second index of their own; a child doc describes its domain and
stops. Where a project is small enough to walk the tree, skip the flat file. What you
must not do is maintain both and expect them to agree.

```markdown
| File | Domain | When to use |
|------|--------|-------------|
| `areas/backend-api-structure.md` | Backend API | CRUD, routes, auth |
| `areas/frontend-structure.md` | Frontend | Pages, routing, API client |
```

#### Bootstrapping an undocumented repo

When the rubric says CREATE and nothing exists yet: scan every folder, create a child
`AGENTS.md` in each domain folder with purpose, ownership, local contracts, and a child index,
then write the root `AGENTS.md` with the Child DOX Index pointing at them. Budget ~5 minutes of
scanning for a medium repo. No install, no tooling — just markdown files.

The equivalent prompt for a human to paste is in `../operator-guide.md`.
