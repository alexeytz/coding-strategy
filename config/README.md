# config/

Copyable assets for projects adopting this strategy. Nothing here is loaded by the
skill — these are files you copy into a target project.

| File | Copy to | Mandated by |
|------|---------|-------------|
| `AGENTS.root.template.md` | `<project>/AGENTS.md` | phase-5a §15 (Context Docs) |
| `AGENTS.child.template.md` | `<project>/<domain>/AGENTS.md` | phase-5a §15 |
| `pre-commit-secret-scan.sh` | `<project>/.githooks/pre-commit` | phase-3e §11 (Pre-commit Security) |
| `gitleaks.default.toml` | `<project>/.gitleaks.toml` | phase-3e §11 |
| `env.example` | `<project>/.env.example` | phase-1b §2 (Config Split) |
| `feature-tracker.template.md` | `<project>/docs/consider-features.md` | phase-2b §5 (Decision Records) |
| `doc-update-matrix.template.md` | `<project>/docs/doc-update-matrix.md` | phase-2b §6 (the pre-commit sweep) |

The `*.template.md` files carry `TODO:` markers as the fill-in convention — a copied template
with markers still in it is an unfinished doc, not a finished one. This repo's own root
`AGENTS.md` is the filled-in reference if you want to see the shape of a completed one.

Per the `default.*` convention in phase-1b §3: copy, then edit the copy. Don't edit
these in place — an updated skill should be able to overwrite them cleanly.

Install the hook:

```sh
mkdir -p .githooks
cp <skill>/config/pre-commit-secret-scan.sh .githooks/pre-commit
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

The hook fails closed: if no scanner is installed it blocks the commit rather than
passing silently.
