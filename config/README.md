# config/

Files you copy into a project that adopts this strategy. Nothing here is loaded by the skill,
and nothing here runs on its own: each file does its job only once it sits in your project.
Take what fits. A small tool needs none of the scripts, and
[1](../references/01-sizing-to-the-project.md) says which tier needs what.

| File | Copy to | Mandated by |
|------|---------|-------------|
| `AGENTS.root.template.md` | `<project>/AGENTS.md` | [5](../references/05-context-docs.md) (context docs); its first rule, load the skill, is [5.9](../references/05-context-docs.md), and its two delegation lines are [28.5](../references/28-delegating.md) and [28.6](../references/28-delegating.md) |
| `AGENTS.child.template.md` | `<project>/<domain>/AGENTS.md` | [5.5](../references/05-context-docs.md) (child doc shape) |
| `pre-commit-secret-scan.sh` | `<project>/.githooks/pre-commit` | [22.1](../references/22-secret-scanning.md) (a blocking hook that fails closed) |
| `pre-push-verify.sh` | `<project>/.githooks/pre-push` | [25.6](../references/25-shipping.md) (main advances on green) |
| `gitleaks.default.toml` | `<project>/.gitleaks.toml` | [22](../references/22-secret-scanning.md) |
| `env.example` | `<project>/.env.example` | [3.1](../references/03-configuration.md) (config split) |
| `feature-tracker.template.md` | `<project>/docs/consider-features.md` | [10.1](../references/10-decision-records.md) (decision records) |
| `doc-update-matrix.template.md` | `<project>/docs/doc-update-matrix.md` | [25.5](../references/25-shipping.md) (the pre-commit sweep) |
| `guard-shrink.py` | `<project>/scripts/guard-shrink.py`, called before a sync's delete | [13.2](../references/13-data-architecture.md) (refuse an empty, short or uncountable authority, and a disjoint one when given the overlap count) |
| `safe-delete.sh` | `<project>/scripts/safe-delete.sh`, the project's way to delete | [12.3](../references/12-trust-boundaries.md), [11.7](../references/11-resilient-code.md) (allowlisted root, dry-run, reversible) |
| `delete-guard-hook.py` | `<project>/.claude/hooks/`, registered as a `PreToolUse` hook | [24.5](../references/24-quality-gates.md) (the guard at the agent's tool layer, refusing with its reason) |

Copy, then edit the copy ([3.5](../references/03-configuration.md)'s `default.*` convention).
Don't edit these in place: an updated skill should be able to overwrite them cleanly.

## Templates

### `AGENTS.root.template.md`

**What it is.** The root context doc an agent reads first in your project: what the project is,
its rules, how to verify, what not to do. **Why it is here.** An agent that starts without one
rediscovers the project every session and repeats the mistakes the last session paid for
([5](../references/05-context-docs.md)). Its first rule tells the agent to load this skill: in
the skill's tests, with that one line the skill was opened in every run under every agent tried
(OpenCode, Pi, Hermes, oh-my-pi); without it, one agent opened it in none of 16 runs. Fill in the `TODO:` markers; a copy with markers left is
unfinished.

### `AGENTS.child.template.md`

**What it is.** The same for one domain of a larger project (`<project>/api/AGENTS.md`).
**When you need it.** Only once a domain folder has rules of its own that the root doc cannot
carry ([5.3](../references/05-context-docs.md)); [5.2](../references/05-context-docs.md) is how
to tell. Most projects never need one.

### `feature-tracker.template.md`

**What it is.** One list of every feature idea with its decision: planned, done, skipped or
deferred, and why. **Why.** Ideas declined in a chat get proposed again by the next session;
a recorded "no, because" stops that ([10.1](../references/10-decision-records.md)).

### `doc-update-matrix.template.md`

**What it is.** A table of "when this changes, that has to change too", walked before a commit.
**Why.** The docs that go stale are the ones nobody remembered were downstream of an edit
([25.5](../references/25-shipping.md)). Where a row can be checked by a script, write the check
instead.

### `env.example`

**What it is.** The committed list of every environment variable the project reads, each marked
required or optional with its default. **Why.** The real `.env` holds per-host values and keys and
is never committed, so without this file nobody, human or agent, can tell what the project needs
to run ([3.1](../references/03-configuration.md)).

## Hooks

Install either hook the same way. Install a scanner first (gitleaks, trufflehog or
detect-secrets) for the secret hook: with none on `PATH` it blocks every commit, this one included,
by design ([22.1](../references/22-secret-scanning.md)).

```sh
mkdir -p .githooks
cp <skill>/config/pre-commit-secret-scan.sh .githooks/pre-commit
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
git add .githooks && git commit -m "docs: install hooks"
```

Commit the hooks: an uncommitted hook protects only the checkout it was installed in.

### `pre-commit-secret-scan.sh`

**The problem.** An API key gets committed. Once it is pushed, deleting it does not help: it is in
the history and in every clone, and the only fix is to rotate the key. Agents commit often and
read `.env` files, so this happens more with them than without.

**What it does.** Before each commit it scans what is staged (not what is on disk, which can
differ) with whichever scanner is installed: gitleaks, trufflehog or detect-secrets. If none is
installed it **blocks the commit** rather than passing silently, because a scan that quietly does
nothing is worse than none: you trust it.

**When you need it.** Any repo that can see a credential, which is most of them. Pair it with
`gitleaks.default.toml`. It is a first line, not the only one: a hook can be skipped with
`--no-verify`, so server-side scanning still earns its place ([22](../references/22-secret-scanning.md)).

### `gitleaks.default.toml`

**What it is.** A gitleaks config: the default rules, plus an allowlist where every entry carries
its reason. **Why.** An allowlist on `docs/` once let the same token that was blocked in `src/` be
committed cleanly in `docs/`, and setup docs are exactly where someone pastes a live token. So
`docs/` stays scanned here, and a fake value in a doc is allowlisted by its pattern, not by its
folder. Copy it to `.gitleaks.toml`.

### `pre-push-verify.sh`

**The problem.** Something lands on `main` that was never verified, and `main` stops being the
version you can trust and fall back to ([25.6](../references/25-shipping.md)).

**What it does.** On a push to `main` or `master` (configurable) it runs your project's
verification script, `scripts/verify.sh` by default, and refuses the push if it fails. It checks
that the checkout it verified is exactly the commit being pushed, untracked files included, so a
green run on uncommitted work cannot vouch for a different commit. Pushes to other branches pass
untouched, so work-in-progress stays cheap. It holds no test logic of its own: your
`verify.sh` decides what "green" means ([4](../references/04-setup-and-dependencies.md)).

**When you need it.** When more than one session or person pushes to `main`, or when the suite is
slow enough that people skip it. Not when you already run the suite before every commit and it
takes seconds; this repo does not install it, for that reason.

## Guards for deletes you cannot undo

These scripts exist because of one finding: a rule in a model's context does not stop a model
that will not apply it. In the skill's own tests, weaker local models given a sync task with a
truncated export deleted the live data every time, with the rule loaded, and reported the job
verified ([24.5](../references/24-quality-gates.md)). A failure you cannot undo needs something
that runs, not a sentence. Each script refuses by default, prints the reason it decided on, and
carries `--self-test`. `guard-shrink.py` and `safe-delete.sh` go in your project's code;
`delete-guard-hook.py` goes in the agent's settings, so it sees every command the agent runs.

**Where they help, and where they don't.** A guard protects only the path it sits on. Called from
your project's own code (the sync job, the cleanup step), it holds for every caller. Named only in
a README as "the way to delete", it holds for the people and agents who use it: in the tests, an
agent that wrote its own `DELETE` never touched the project's guard script. To stop an agent
that goes around it, also keep the data recoverable (in git, or backed up) or put a guard at the
agent's tool layer, a host hook or permission rule ([24.5](../references/24-quality-gates.md)).

### `guard-shrink.py`

**The problem.** A sync deletes from your store whatever is missing from the source: "remove from
the cache anything not in today's export". If the export is empty, cut short, or from the wrong
environment, the sync deletes almost everything, correctly by its own logic. One project lost
vector indexes twice this way ([13.2](../references/13-data-architecture.md)).

**What it does.** Called before the delete with the counts, it refuses when the source is empty,
smaller than it declares (a manifest), would remove more than a set share of the target (5% by
default), shares none of the target's keys, or could not be counted. Exit 0 means go ahead, 3
means refused.

```sh
python3 scripts/guard-shrink.py --authority exports/today.csv --header \
    --manifest exports/today.manifest.json --target-count "$N" \
    --overlap-count "$SHARED" || exit 1   # target keys also in the authority; omit it and the
                                          # disjoint check does not run
```

The manifest is JSON with an integer `rows` field, what the source says it sent:
`{"rows": 410}`. Without `--manifest` the short-export check does not run.

**When you need it.** Any job that deletes on the strength of another store: a cache refresh, an
orphan sweep, a mirror. Not for deletes a person types and watches.

### `safe-delete.sh`

**The problem.** A delete on a path the code computed: joined from config, built from an ID, or
proposed by a model. An empty variable turns `rm -rf "$DIR/"*` into a delete of the wrong tree; a
symlink points outside where you meant; a typo in an environment name picks the wrong root. `rm`
does what it is told and cannot be undone ([12.3](../references/12-trust-boundaries.md)).

**What it does.** It is the project's one door for deleting files. It deletes only below roots you
list in `SAFE_DELETE_ROOTS`, and only in a root that carries a marker file
(`.safe-delete-root`), so a misconfigured root fails rather than widening. The roots are set once,
in the project's `.env` (or a committed `.safe-delete.conf`), relative to the project root, so a
call is just `scripts/safe-delete.sh PATH`. The script reads those files as text and never runs
them, and a value in the environment wins. It resolves symlinks
before deciding. Without `ALLOW_DESTRUCTIVE=1` it only prints what it would do
([11.7](../references/11-resilient-code.md)). With it, it moves the files to a dated trash
directory inside that root instead of deleting them, so a mistake can be put back.

```sh
chmod +x scripts/safe-delete.sh                 # once, after copying
touch data/.safe-delete-root                    # once: mark data/ as a root deletes may happen under
echo 'SAFE_DELETE_ROOTS=data' >> .env           # once: or in .safe-delete.conf, to commit it
scripts/safe-delete.sh data/tmp/old.csv                       # dry run
ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh data/tmp/old.csv   # moves it to the trash
```

**`.env` or `.safe-delete.conf`?** Roots relative to the project are the same on every machine,
so a committed `.safe-delete.conf` means a fresh checkout works with no setup. `.env` is never
committed, so a new clone refuses every delete until someone sets the roots: safe, but a surprise.
Use `.env` when the roots differ per host. **`ALLOW_DESTRUCTIVE` never goes in either file:** it is
the per-call grant that turns a dry run into a move, and the script ignores it there.

**When you need it.** When your project's code or scripts delete files on computed paths (cleanup
jobs, cache pruning, temp directories, generated output), or when you want agents working in the
project to delete through one door you can audit. Empty the trash directories on your own
schedule. Not for a project that never deletes files at run time.

### `delete-guard-hook.py`

**The problem.** The two guards above protect the routes that call them. An agent asked to "clean
up the cache" may not: it writes its own `rm -rf` or `DELETE FROM`, and the guard sits unused. In
the skill's tests that happened every time with a weaker model, and only a guard at the agent's
tool layer held ([24.5](../references/24-quality-gates.md)).

**What it does.** It runs before every shell command the agent issues and refuses the common
delete routes that do not go through a guard: a recursive or forced `rm`, an `rm` on a variable or
wildcard, `find -delete`, `shutil.rmtree`, an SQL `DELETE`, `DROP` or `TRUNCATE`, `git clean -f`,
`git reset --hard`. It also refuses a command or file edit that changes the guard's own
configuration: setting `SAFE_DELETE_ROOTS` or `SAFE_DELETE_MARKER` inline, creating or editing a
`.safe-delete-root` marker or `.safe-delete.conf`, or writing a `SAFE_DELETE_` line into `.env`.
Only the user widens where deletes may happen. The refusal tells the model why and what to do instead: use `safe-delete.sh`,
run `guard-shrink.py` first, or ask the user. A guard that refused silently was fought in the
tests; one that explains is followed. It allows a command that goes through `safe-delete.sh`, and a
delete chained after `guard-shrink.py` with `&&`.

**When you need it.** When agents work in a project whose data you cannot easily restore. It reads
the command text, so it stops the usual routes, not a determined one (a delete inside a script the
agent wrote and then ran is invisible to it), and it also refuses a harmless `grep 'delete from'`.
Keep the data recoverable as well. Written for Claude Code. Another agent can use it only if it
has a hook that runs before each tool call and can pass the call as JSON; if yours has none, this
layer is not available to you, and recoverable data (git, a backup, a snapshot) is what is left
([24.5](../references/24-quality-gates.md)).

## Real use

Each example below was run against a small shop project: `cache.db` holds 412 items, and
today's export stopped after 12 rows with `connection reset` in its log.

### A sync job that cannot empty the cache

The project's one way to refresh the cache, `scripts/refresh_cache.py`, counts before it deletes
and lets `guard-shrink.py` decide:

```python
"""Make cache.db match today's warehouse export. The only way this project syncs the cache."""
import csv, sqlite3, subprocess, sys

EXPORT = sys.argv[1] if len(sys.argv) > 1 else "exports/today.csv"
with open(EXPORT, newline="") as f:
    keep = {row["sku"] for row in csv.DictReader(f)}
db = sqlite3.connect("cache.db")
cached = [sku for (sku,) in db.execute("SELECT sku FROM items")]
stale = [sku for sku in cached if sku not in keep]

# The guard decides on the counts; it prints its reason either way.
guard = subprocess.run([sys.executable, "scripts/guard-shrink.py", "--authority", EXPORT, "--header",
                        "--target-count", str(len(cached)), "--delete-count", str(len(stale)),
                        "--overlap-count", str(len(cached) - len(stale))])
if guard.returncode != 0:
    sys.exit("refresh_cache: not deleting anything; fix the export, or delete by hand if you are sure")
db.executemany("DELETE FROM items WHERE sku = ?", [(s,) for s in stale])
db.commit()
print(f"refresh_cache: removed {len(stale)} of {len(cached)}")
```

On the truncated export, and then on yesterday's complete one:

```
$ python3 scripts/refresh_cache.py exports/2026-03-10.csv
REFUSED: authority has 12 rows, fewer than the 400 about to be deleted: refusing
refresh_cache: not deleting anything; fix the export, or delete by hand if you are sure
$ python3 scripts/refresh_cache.py exports/2026-03-09.csv
ok: authority 410 rows, target 412, removing 2: within limits
refresh_cache: removed 2 of 412
```

The protection holds for whoever runs the job: you, cron, CI or an agent that calls it.

### A cleanup step that can be undone

Once: mark the directory deletes may happen under, set the root, and keep the trash out of git:

```sh
touch var/.safe-delete-root
echo 'SAFE_DELETE_ROOTS=var' >> .env      # or .safe-delete.conf, committed
echo 'var/.trash/' >> .gitignore
```

Then delete through the script, from a `Makefile` target or by hand:

```
$ scripts/safe-delete.sh var/cache/a.json
dry run: would move /srv/shop/var/cache/a.json -> /srv/shop/var/.trash/20261026-170043.*/cache/a.json (set ALLOW_DESTRUCTIVE=1 to act)
$ ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh var/cache/a.json
moved /srv/shop/var/cache/a.json -> /srv/shop/var/.trash/20261026-170043.vICJ/cache/a.json   (undo: mv '/srv/shop/var/.trash/20261026-170043.vICJ/cache/a.json' '/srv/shop/var/cache/a.json')
$ ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh exports/2026-03-09.csv
REFUSED: /srv/shop/exports/2026-03-09.csv is not strictly below an allowlisted root marked with .safe-delete-root (roots '/srv/shop/var', from /srv/shop/.env)
$ X=""; ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh "var/$X"
REFUSED: /srv/shop/var is not strictly below an allowlisted root marked with .safe-delete-root (roots '/srv/shop/var', from /srv/shop/.env)
```

The last one is the empty-variable case: `rm -rf "var/$X"` would have removed the whole of `var/`.
With no roots set anywhere, every delete is refused, and the refusal says where to set them.

### Telling the agent

Agents read the project's `AGENTS.md` first, so name the routes there, under Global Rules:

```markdown
- Delete files only through `scripts/safe-delete.sh`: run it without `ALLOW_DESTRUCTIVE` first and
  show the output, then with `ALLOW_DESTRUCTIVE=1`. Never `rm -rf` a computed path. Don't change
  `SAFE_DELETE_ROOTS`, the `.safe-delete-root` markers or `.safe-delete.conf`; if a path is outside
  the roots, ask.
- `scripts/refresh_cache.py` is the only way to sync the cache. If its guard refuses, stop and
  report the reason; do not delete the rows by hand.
```

This holds for an agent that follows its instructions. For one that does not, add the hook.

### Holding the agent to it

Copy the hook into the project and register it in `.claude/settings.json`:

```sh
mkdir -p .claude/hooks
cp <skill>/config/delete-guard-hook.py .claude/hooks/
```

```json
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash|Write|Edit|MultiEdit",
       "hooks": [{"type": "command",
                  "command": "python3 \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/delete-guard-hook.py"}]}
    ]
  }
}
```

Run with a local 27B model under Claude Code and asked to "delete the exports folder with
`rm -rf exports`", the agent's command was refused before it ran. Its reply opened "The delete
did **not** happen", named the project's delete guard as what blocked it, and confirmed `exports/`
was untouched.

Asked instead to sync the cache from the truncated export, the same model read the log, compared
the 12 rows with yesterday's export and stopped without attempting a delete, so the hook never
had to fire. That is the usual case for a strong model; the hook is for the run that is not.
