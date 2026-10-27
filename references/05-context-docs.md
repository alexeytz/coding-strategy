# 5 Context docs

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

When joining a project, inspect it and decide whether AGENTS.md is needed using the rubric
below. For the rules that apply once the docs exist - reading the chain before editing,
updating it after - see [7](07-working-in-a-documented-repo.md).

**Rules**

- The top-level doc holds what is expensive to relearn, not a description of the project (5.1)
- Under 15 files and 3 domains: no AGENTS.md; 15–49 or 3–4: root only; 50+ or 5+: hierarchy; an agent duplicating code or misplacing files: create it now (5.2)
- A child AGENTS.md defaults to purpose, ownership, local contracts, work guidance, negative constraints, verification, child index (5.5)
- List each doc in one map: a flat context index for topic docs, child indexes for child AGENTS.md files, never the same docs in both (5.7)
- The root AGENTS.md's first rule says to load the `coding-strategy` skill before the first edit (5.9)

### 5.1 What belongs in the top-level doc

The top-level doc is not a
description of the project - that is the README and the architecture doc - **it is
the set of things that are expensive to relearn.** Test it entry by entry: would a
competent reader work this out in two minutes from the code? Then cut it. Did
someone lose an afternoon to it? Then it belongs, with the symptom stated first,
because the symptom is what the next reader will search for.

### 5.2 When to create AGENTS.md

Inspect the project before deciding. Run these checks:

```
git ls-files | wc -l   # in a git repo, the whole answer
# Not a git repo: non-hidden, non-vendor files (add your build dirs)
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
  files=$(find "$d" -maxdepth 1 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) 2>/dev/null | wc -l)
  if [ "$files" -gt 0 ]; then echo "$d ($files source files)"; fi
done
```

**Decision thresholds:**

| Condition | Verdict | Action |
|-----------|---------|--------|
| **< 15 files, < 3 source domains** | SKIP | A README.md is sufficient, unless 01's tier (it counts contributors too) is higher. |
| **15-49 files, or 3-4 source domains** | CREATE ROOT | Create a single `AGENTS.md` at repo root. Cover purpose, structure, conventions. |
| **50+ files, or 5+ source domains** | CREATE HIERARCHY | Root `AGENTS.md` + child `AGENTS.md` in each domain folder. |
| **Existing AGENTS.md but > 30 days since update** | REVIEW | Read it. If structure changed (new domains, renamed modules), update it. |
| **Agent is duplicating code or creating files in wrong place** | CREATE IMMEDIATELY | Symptom of missing context. Stop, create AGENTS.md, resume. |

When both CREATE rows match, the higher verdict applies.

**Signals that AGENTS.md is overdue (even if thresholds aren't met):**
- Two or more contributors/agents working on the same repo
- Non-obvious conventions (e.g., "tests live in `tests/unit/` and `tests/integration/`, not alongside source")
- Domain-specific naming patterns that differ between folders
- The agent has asked "where should this file go?" during the session

**If the project has no AGENTS.md and meets the CREATE threshold:** create it before writing code. Spend ~5 minutes scanning the repo, then generate the root AGENTS.md with purpose, ownership, key files, and a child index.

### 5.3 One AGENTS.md per domain folder

```
project/
  AGENTS.md              # Root: global rules, project-wide conventions, Child Docs Index
  api/
    AGENTS.md            # Domain: API endpoints, routes, auth, response format
    types/
      AGENTS.md          # Domain: internal types, serialization, validation
  engine/
    AGENTS.md            # Domain: pipeline stages, data flow, error handling
  features/
    AGENTS.md            # Domain: feature list, cross-cutting rules, Child Docs Index
    export/
      AGENTS.md          # Domain: export formats, file naming, output paths
```

### 5.4 Hierarchy rules

- Root `AGENTS.md` is the rail: project-wide instructions, global preferences, top-level index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific it must be
- Broad rules in parent docs, concrete details in child docs
- Do not duplicate rules across files unless each scope needs a local version

### 5.5 Child doc shape

Create a child `AGENTS.md` when a folder becomes a durable boundary with its own purpose, rules, or workflow.

Default section order:
- **Purpose** - what this folder/domain does
- **Ownership** - who/what owns changes here
- **Local Contracts** - rules specific to this domain
- **Work Guidance** - how to make changes here (conventions, patterns)
- **Negative Constraints** - what not to do here ([7.3](07-working-in-a-documented-repo.md))
- **Verification** - how to test/verify changes
- **Child Docs Index** - list of subfolder AGENTS.md files with one-line descriptions

### 5.6 Area-level context schema

Each `areas/<domain>-structure.md` follows a fixed shape:
- **Purpose** - 2-3 sentences on what this domain does
- **Key files** - list of critical files and their role
- **Inputs/outputs** - API endpoints, props, events, data contracts
- **Dependencies** - what other domains this domain relies on
- **Common pitfalls** - non-obvious failure modes specific to this area
- **Change checklist** - what to verify after modifying this domain

This sits between AGENTS.md (rules and conventions) and design docs (architectural decisions) - it's the "what lives here and how does it connect" layer.

### 5.7 Cross-reference index: one map

Mandatory rather than optional when driving a small model: the map is what lets it open three
files instead of thirty ([29-small-models.md](29-small-models.md)).

**Keep one map, and prefer the flat one.** A hierarchy of docs *and* a flat index of the
same docs is two maps of one territory, and the second is the one nobody updates - the
drift generator this file otherwise exists to prevent. Where a project wants the quick
lookup, `docs/context-index.md` is a single `File | Domain | When to use` table of the topic
docs, and the AGENTS.md files do not list them again: a child doc's index names its child
AGENTS.md files, describes its domain and stops. Where a project is small enough to walk the tree, skip the flat file. What you
must not do is list the same docs in both and expect them to agree.

```markdown
| File | Domain | When to use |
|------|--------|-------------|
| `areas/backend-api-structure.md` | Backend API | CRUD, routes, auth |
| `areas/frontend-structure.md` | Frontend | Pages, routing, API client |
```

### 5.8 Bootstrapping an undocumented repo

When the rubric says CREATE and nothing exists yet: scan every folder, create a child
`AGENTS.md` in each domain folder with purpose, ownership, local contracts, and a child index,
then write the root `AGENTS.md` with the Child Docs Index pointing at them and, as its first
Global Rule, the line that loads this skill (5.9). Budget ~5 minutes of
scanning for a medium repo. No install, no tooling - just markdown files.

The equivalent prompt for a human to paste is in `../operator-guide.md`.

### 5.9 The root AGENTS.md says to load the skill

Unprompted, an agent often never opens this skill: with 18 other skills installed, OpenCode
loaded it in 4 of 8 runs, Hermes in 0 of 16 with them or alone, and the runs that skipped it
broke its rules. Agents read AGENTS.md unasked, so the root doc's first Global Rule names the skill
and when to load it, as `config/AGENTS.root.template.md` does. With that one line, OpenCode,
Pi and Hermes each loaded it in 8 of 8 runs.
