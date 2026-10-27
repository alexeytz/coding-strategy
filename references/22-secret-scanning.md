# 22 Secret scanning

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Keeping a credential out of history in the first place, and what to do once one is in.
Everything after the hook is worse than the hook, which is the whole argument for it.
Making the code itself survive real inputs is [11](11-resilient-code.md).

Automated secret scanning as a strict pre-commit hook. Catch secrets before they're committed - don't wait for a milestone audit.

**Rules**

- Secret scanning runs as a blocking pre-commit hook, and fails closed when no scanner is installed (22.1)
- Probe the hook in both directions: a random live-looking token (not a typed sequence) must block, a clean commit must pass; a scanner that blocks only verified secrets is probed by hand without that flag (22.2)
- A secret that reached a remote is burned: rotate first, clean history second, fix the hook third; scan redacted (22.3)
- Call gitleaks as the shipped hook does; an allowlist regex with lookaround panics the scan, and 8.19.0-8.19.2 pass a staged secret (22.4)

### 22.1 A blocking hook that fails closed

Run `gitleaks`, `trufflehog`, or `detect-secrets` on `git commit`. Block the commit if secrets are found, and also when no scanner is installed, because a hook that passes when it cannot scan looks installed while protecting nothing. The shipped `config/pre-commit-secret-scan.sh` fails closed this way.

**Why:** The "Never commit secrets" rule ([3.1](03-configuration.md)) is meaningless without enforcement. A pre-commit hook is the closest thing to guaranteed compliance - it runs locally on every commit, not just at audit time.

**Pattern:** `.gitleaks.toml` or `.secrets.baseline` (detect-secrets' default name, the one the shipped hook reads) shipped in the repo. The baseline tracks false positives; the hook blocks new secrets.

### 22.2 Verify the hook with a probe the scanner actually detects

Installing this
into a real repo on 2026-09-05, the first control used AWS's published
documentation key (`AKIAIOSFODNN7EXAMPLE`) - which gitleaks allowlists
upstream, precisely because it is famously not a secret. The scan came back
clean and the hook was briefly recorded as inert when it was working. Probe
with a live-looking token, random rather than typed - gitleaks passes a sequential
`ghp_abcdef...` even at full length, so the probe would call a working hook inert:
`echo "key=ghp_$(head -c 300 /dev/urandom | base64 | tr -dc A-Za-z0-9 | head -c 36)"`.
Confirm the commit is *blocked*, then confirm a clean commit still *passes*, with a harmless change staged:
with nothing staged a hook can exit before it scans. Both directions, or you have tested nothing. Then once more as a rename (`git mv` a tracked file and
add the token in the same commit), once with the token staged and the file
on disk cleaned, and once replacing a tracked symlink with a file that holds it. A hook that lists staged files by status can skip renames, and
one that scans disk passes the second; the shipped one did both until 2026-10-20. A scanner that blocks
only *verified* secrets (trufflehog's `--only-verified`) passes a made-up token
by design; probe that one by hand without the flag. Run every such probe in a throwaway
copy (`mktemp -d`, `cp -r`, or a worktree), never in the checkout that holds uncommitted
work: undoing a seeded break is how a tree gets lost.

### 22.3 A secret that reached a remote is burned - rotate it, do not tidy it

The hook above
exists because everything after this point is worse. Once a commit has been pushed, `git`
history rewriting is not a remedy: clones already hold it, and a host keeps the dangling
commit reachable by direct reference for a while after a force-push. On a public host the
scrapers arrive in seconds. So the order is **rotate the credential first**, then clean the
history, then work out how it got past the hook - and the hook gets the new case before you
move on. A rewritten history with a live credential still in it is the same failure as an
inert scanner: it looks handled. Run every scan redacted (`--redact` on gitleaks, as the
shipped hook does): an unredacted match puts the secret in the agent's transcript, and from
there in logs, summaries and commit messages. Report the rule and the location, never the
value.

### 22.4 Scanner traps that make a hook look installed

Two traps that each cost a cycle: `gitleaks protect` is deprecated in 8.x in
favour of `gitleaks git --staged`, so a hook pinned to the old spelling can
fall through to its own "no scanner installed" branch on a new install; and
allowlist regexes compile under Go's RE2, which has **no lookaround** - a
`(?!` there panics the whole scan rather than failing that rule, leaving the
repo unprotected while the hook still appears installed. A third: on 8.19.1 and 8.19.2
`gitleaks git --staged` scans committed history, not the index, and passes a
staged secret, so the shipped hook prefers `protect --staged` while it exists. And
8.19.0 starts no scan at all; a hook blocking clean commits may be the release.
