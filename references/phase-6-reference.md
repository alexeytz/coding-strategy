# Phase 6: Reference

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

### Anti-Patterns (Learned from HLM)

| Anti-pattern | What happened | Rule |
|-------------|--------------|------|
| Inline everything | backend.py hit 3105 lines | ~2000 lines is a soft limit — when exceeded, evaluate: is the file doing too many things? Split if yes; document why if no. Don't split blindly. |
| Docs after the fact | Design docs written AFTER code for early features | Design doc FIRST, always |
| Silent failures | Qdrant failures swallowed, stale data served | Log at minimum debug, surface at warning |
| No rollback plan | Compaction merged records, no way to restore | Every destructive action has a rollback section in its design doc |
| Hardcoded paths | An absolute path baked into the source broke the moment `HOME` was overridden | Configurable paths with documented defaults |
| Framework fighting | pytest rejected relative imports, wasted time | Custom runner when framework fights structure |
| Agent-built without data review | Agent generates features the data layer can't support | Human always owns the data schema; agent proposes, human approves |
| Silent AI bloat | Agent accumulates 100 features no one uses, codebase becomes unmaintainable | Human retains taste and selectivity; say no to features individually reasonable but collectively madness |
| Half-applied fix | A guard added to one of three archive paths, a SELECT normalised but not its COUNT — 3 of 20 findings in one review round were incomplete halves of the three preceding releases' fixes | Fixing one member of a class is not fixing the class. Search for every instance, then add a mechanical check comparing the halves ([phase 7a §19](phase-7a-running-a-review.md)) |
| Copies that drift | A skill directory copied into two profiles; both drifted, one asserting a version and test count three releases stale. The guard test lived in the repo and could not see either copy | Symlink instead of copying, and add a check that fails if a real directory reappears at that path |
| Counting your own tooling | `ps -ef \| grep -c` reported three leftover servers where there were none — the pipeline matched itself | A count is not a membership test, and the rule is forgotten first in instrumentation ([phase 8b §23](phase-8a-unattended-runs.md)) |
| Two surfaces, one backend | Plugin and MCP server could not share code; only a reachability test held them level, so every fix had to be applied twice and the second was forgotten | Prefer a shared constant or data file over a parity test: a test tells you the two have diverged, a shared definition makes divergence unrepresentable. Reach for the test only where the surfaces genuinely cannot share code, and even then share the *data* they both consume; reviews then compare the twins side by side, never file by file |

### Patterns Intentionally Excluded

These are language- or tool-specific and belong in language-specific skills:

- **Background processing** — goroutines, promises, tokio tasks, threads. The concept is "non-blocking expensive work" but implementation is entirely language-dependent.
- **Database-specific sync** — FTS5 triggers (SQLite), generated columns (PostgreSQL), compound indexes (MongoDB). The concept is "keep search indexes in sync" but each DB handles it differently.
- **Multi-service and polyrepo layout.** The Interface/Engine/Features tree, the
  two-file invariant and the working-set argument under them all assume one deployable
  unit in one checkout, and "one feature touches at most 2 source files" has no meaning
  across a service boundary where one feature is a change in two deployables. Excluded
  rather than guessed: these patterns were extracted from single-service projects, so a
  rule for where a service boundary goes would be invented here, not learned. Applying
  the tree once across several services flattens a real boundary; applying it per service
  is fine and needs no permission from this document.
- **Session auto-tracking** — Hermes Agent lifecycle hooks. The concept (track which sessions worked on a project) is universal, but auto-tracking is platform-specific.
