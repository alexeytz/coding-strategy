#!/usr/bin/env bash
# Pre-commit secret scan - the enforcement half of 22.1.
#
# Why: a key that reaches a pushed commit is in every clone for good, and the only fix is to
# rotate it. This scans what is staged before each commit and blocks on a finding, or when no
# scanner is installed at all. More: config/README.md.
#
# Install into a project:
#   cp config/pre-commit-secret-scan.sh <project>/.githooks/pre-commit
#   chmod +x <project>/.githooks/pre-commit
#   git -C <project> config core.hooksPath .githooks
#   git -C <project> add .githooks && git -C <project> commit -m "docs: install hooks"
#
# Uses whichever scanner is installed, in order of preference. If none is
# installed the hook FAILS rather than passing silently - a secret scan that
# quietly no-ops is worse than none, because you'll trust it.
set -euo pipefail

# Everything but deletions, not a list of statuses: ACM missed renames (R) and ACMR missed type
# changes (T) - each committed a secret unscanned (rounds nine and ten, 2026-10-20). Exclude what
# cannot carry a secret rather than list what can. NUL-separated, so a name with a space is one
# file, not two that do not exist.
staged=()
while IFS= read -r -d '' f; do staged+=("$f"); done \
  < <(git diff --cached --name-only -z --diff-filter=d)
[ "${#staged[@]}" -eq 0 ] && exit 0

# The branches below that scan files scan what is staged, not what is on disk: `git add -p`, or
# an edit after `git add`, makes them differ, and a disk scan passed a staged secret (found in review).
# gitleaks reads the index itself; trufflehog gets an export of the staged blobs; detect-secrets
# needs the repo (it runs `git diff` to refresh its baseline), so it refuses instead when a staged
# file differs from disk.
export_staged() {
  scan_dir="$(mktemp -d)"
  trap 'rm -rf "$scan_dir"' EXIT
  printf '%s\0' "${staged[@]}" | git checkout-index -z --stdin --prefix="$scan_dir/"
}

if command -v gitleaks >/dev/null 2>&1; then
  # `gitleaks protect` is deprecated in 8.x and absent from `gitleaks --help`'s
  # command list, though still accepted; `gitleaks git --staged` is the current
  # spelling. Probe rather than assume, so this keeps working on both sides of
  # the rename instead of silently falling through to the "no scanner" branch.
  # Found 2026-09-05 installing this into a real repo against gitleaks 8.30.1.
  # Prefer `protect` while it exists: on 8.19.1 and 8.19.2 `git --staged` scans committed
  # history, not the index, so a staged secret passes with exit 0 (8.20.0 is fixed;
  # found in review, 2026-10-25). Probe the help text, not the exit code: `gitleaks <anything> --help` exits 0.
  # Run 2026-10-25, a secret and a clean change staged: 8.18.4, 8.19.1, 8.19.2, 8.20.0, 8.21.2,
  # 8.22.1, 8.23.1, 8.24.3 and 8.30.1 block the one and pass the other. 8.19.0 cannot start a
  # scan in either spelling ("flag accessed but not defined: source"), so it blocks every
  # commit; the message below names it (found in review).
  # grep without -q reads all of the help: under pipefail, -q's early exit can SIGPIPE gitleaks
  # and send the hook to `git --staged`, the spelling that passes secrets on 8.19.1 and 8.19.2.
  if gitleaks protect --help 2>&1 | grep -- '--staged' >/dev/null; then
    _gl=(gitleaks protect --staged --redact --verbose)
  else
    _gl=(gitleaks git --staged --redact --verbose)
  fi
  # A config gitleaks cannot load is not a leak, but it exits 1 either way - the same
  # code as a real finding, so the exit status cannot tell them apart (checked against
  # 8.30.1 on 2026-09-14: bad --config on a CLEAN tree also exits 1). Validate the path
  # here instead, or a typo'd GITLEAKS_CONFIG is reported as a secret and the operator
  # goes looking for a false positive in a file gitleaks never read.
  if [ -n "${GITLEAKS_CONFIG:-}" ] && [ ! -r "$GITLEAKS_CONFIG" ]; then
    echo "
Commit blocked: GITLEAKS_CONFIG is set to '$GITLEAKS_CONFIG', which does not exist or
cannot be read. That is a configuration error, not a secret. Fix the path or unset the
variable - gitleaks finds .gitleaks.toml in the repo root on its own." >&2
    exit 1
  fi
  # The path check cannot see a config that exists but does not load - the project's own
  # .gitleaks.toml, auto-loaded. On 8.30.1 (2026-10-15) a TOML typo exits 1 like a finding,
  # and an RE2-illegal regex panics with exit 2. So name a secret only when gitleaks says it
  # found one ("leaks found: N"); any other failure means it never scanned. Same string and exit
  # codes on 8.18.4, through the `protect` spelling, which it still uses (2026-10-20).
  gl_rc=0
  gl_out="$("${_gl[@]}" ${GITLEAKS_CONFIG:+--config "$GITLEAKS_CONFIG"} 2>&1)" || gl_rc=$?
  [ -n "$gl_out" ] && printf '%s\n' "$gl_out" >&2
  if [ "$gl_rc" -ne 0 ]; then
    if [ "$gl_rc" -ne 1 ] || ! printf '%s' "$gl_out" | grep 'leaks found: [1-9]' >/dev/null; then
      echo "
Commit blocked: gitleaks failed before reporting any leak (exit $gl_rc) - it did not scan.
That is a scanner or configuration error, not a secret. Usually .gitleaks.toml (or
GITLEAKS_CONFIG): TOML syntax, or a '(?!' - Go's RE2 has no lookaround, and one illegal
regex fails the whole config. Or the release itself: 8.19.0 fails every scan with \"flag
accessed but not defined\" - upgrade it. Fix it - do not use --no-verify." >&2
    else
      echo "
Commit blocked: gitleaks found a secret in staged changes.
If it is a false positive, add a rule to .gitleaks.toml - do not use --no-verify." >&2
    fi
    exit 1
  fi
elif command -v trufflehog >/dev/null 2>&1; then
  # NOTE: trufflehog has no reliable staged-changes mode. Scanning committed
  # history (git file://.) misses the staged-but-uncommitted changes a pre-commit
  # hook exists to catch, so this branch scans an export of the staged blobs, file by file.
  # `--fail` exits **183** when results are found (`trufflehog filesystem --help`), not 1.
  # Treating any nonzero as a finding is wrong twice, and the second way is the bad one:
  # without --no-update trufflehog tries to self-update first, and when it cannot write its
  # binary it exits 1 having scanned nothing. Checked on 3.86.0, 2026-09-14 - a file reading
  # "nothing secret here" exited 1 with `error occurred with trufflehog updater: cannot move
  # binary`, and exits 0 with --no-update. So this branch used to block every commit, naming
  # every staged file as a verified secret, on any box whose trufflehog cannot self-update.
  # A hook that cries wolf on every commit is the one that teaches you to pass --no-verify.
  # --only-verified blocks only credentials the provider confirms live, so a made-up token
  # passes this branch by design - probe it with a real revoked one, or by hand without the flag.
  # rc is captured with ||: under set -e a bare call exits the hook on 183 before rc=$? runs,
  # blocking with neither message below (found in review, 2026-10-20).
  export_staged
  fail=0
  for f in "${staged[@]}"; do
    # A symlink's committed content is its target path, and [ -f ] follows it; a submodule entry
    # has no content. Skip both (found in review).
    [ -f "$scan_dir/$f" ] && [ ! -L "$scan_dir/$f" ] || continue
    rc=0
    trufflehog filesystem "$scan_dir/$f" --only-verified --fail --no-update >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq 183 ]; then
      echo "
Commit blocked: trufflehog found a verified secret in: $f" >&2
      fail=1
    elif [ "$rc" -ne 0 ]; then
      echo "
Commit blocked: trufflehog could not scan $f (exit $rc). That is a scanner failure, not a
secret - run it by hand to see why. Do not bypass this hook with --no-verify." >&2
      fail=1
    fi
  done
  [ "$fail" -eq 0 ] || exit 1
elif command -v detect-secrets >/dev/null 2>&1; then
  # Same class as the gitleaks config check above: the baseline path is hardcoded, so a
  # repo that never ran `detect-secrets scan > .secrets.baseline` gets "found a new secret"
  # for a file that is missing, not a secret that is present. Validate before scanning.
  if [ ! -r .secrets.baseline ]; then
    echo "
Commit blocked: detect-secrets is installed but .secrets.baseline is missing or unreadable.
That is a setup step, not a secret. Create it with:
  detect-secrets scan > .secrets.baseline" >&2
    exit 1
  fi
  # A baseline that exists but does not load exits 1 like a finding ("Unable to read baseline",
  # "Invalid baseline"; detect-secrets 1.5.0, 2026-10-20) - gitleaks' bug-33 shape. So name a
  # secret only when it says it found one.
  # A staged symlink's content is a path; detect-secrets would read its target (found in review).
  ds_files=()
  while IFS= read -r -d '' e; do
    [ "${e%% *}" = 120000 ] || ds_files+=("${e#*$'\t'}")
  done < <(git ls-files -s -z -- "${staged[@]}")
  [ "${#ds_files[@]}" -eq 0 ] && exit 0
  if ! git diff --quiet -- "${staged[@]}"; then
    echo "
Commit blocked: a staged file differs from the file on disk, and detect-secrets scans disk:
$(git diff --name-only -- "${staged[@]}" | sed 's/^/  /')
Stage the rest (git add) or set it aside (git stash --keep-index), then commit again." >&2
    exit 1
  fi
  # Exit 3 is its own case: the scan ran clean and detect-secrets refreshed the baseline's line
  # numbers - stage the baseline, do not regenerate it (found in review).
  ds_rc=0
  ds_out="$(detect-secrets-hook --baseline .secrets.baseline "${ds_files[@]}" 2>&1)" || ds_rc=$?
  if [ "$ds_rc" -ne 0 ]; then
    [ -n "$ds_out" ] && printf '%s\n' "$ds_out" >&2
    if printf '%s' "$ds_out" | grep 'Potential secrets about to be committed' >/dev/null; then
      echo "
Commit blocked: detect-secrets found a new secret.
Review, then update the baseline deliberately if it is a false positive." >&2
    elif printf '%s' "$ds_out" | grep 'is unstaged' >/dev/null; then
      echo "
Commit blocked: .secrets.baseline has unstaged changes (an audit, or a refresh). No secret was
reported. Review and stage it - git add .secrets.baseline - then commit again." >&2
    elif [ "$ds_rc" -eq 3 ] && printf '%s' "$ds_out" | grep 'baseline file was updated' >/dev/null; then
      echo "
Commit blocked: detect-secrets refreshed .secrets.baseline (line numbers moved). No new secret.
Review and stage it - git add .secrets.baseline - then commit again." >&2
    else
      echo "
Commit blocked: detect-secrets failed before reporting any secret (exit $ds_rc) - it did not
scan. Usually .secrets.baseline does not load: restore it from git, or fix its JSON. Starting
over with \`detect-secrets scan > .secrets.baseline\` works but drops every audit mark in it.
That is a setup error, not a secret. Do not use --no-verify." >&2
    fi
    exit 1
  fi
else
  echo "
Commit blocked: no secret scanner installed.
Install one of: gitleaks | trufflehog | detect-secrets
  brew install gitleaks    # or: go install github.com/gitleaks/gitleaks/v8@latest
Then re-commit. Do not bypass this hook with --no-verify." >&2
  exit 1
fi
