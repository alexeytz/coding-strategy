#!/usr/bin/env bash
# Pre-commit secret scan — the enforcement half of phase-3e §11.
#
# Install into a project:
#   cp config/pre-commit-secret-scan.sh <project>/.githooks/pre-commit
#   chmod +x <project>/.githooks/pre-commit
#   git -C <project> config core.hooksPath .githooks
#
# Uses whichever scanner is installed, in order of preference. If none is
# installed the hook FAILS rather than passing silently — a secret scan that
# quietly no-ops is worse than none, because you'll trust it.
set -euo pipefail

staged="$(git diff --cached --name-only --diff-filter=ACM)"
[ -z "$staged" ] && exit 0

if command -v gitleaks >/dev/null 2>&1; then
  # `gitleaks protect` is deprecated in 8.x and absent from `gitleaks --help`'s
  # command list, though still accepted; `gitleaks git --staged` is the current
  # spelling. Probe rather than assume, so this keeps working on both sides of
  # the rename instead of silently falling through to the "no scanner" branch.
  # Found 2026-09-05 installing this into a real repo against gitleaks 8.30.1.
  if gitleaks git --help >/dev/null 2>&1; then
    _gl=(gitleaks git --staged --redact --verbose)
  else
    _gl=(gitleaks protect --staged --redact --verbose)
  fi
  # A config gitleaks cannot load is not a leak, but it exits 1 either way — the same
  # code as a real finding, so the exit status cannot tell them apart (checked against
  # 8.30.1 on 2026-09-14: bad --config on a CLEAN tree also exits 1). Validate the path
  # here instead, or a typo'd GITLEAKS_CONFIG is reported as a secret and the operator
  # goes looking for a false positive in a file gitleaks never read.
  if [ -n "${GITLEAKS_CONFIG:-}" ] && [ ! -r "$GITLEAKS_CONFIG" ]; then
    echo "
Commit blocked: GITLEAKS_CONFIG is set to '$GITLEAKS_CONFIG', which does not exist or
cannot be read. That is a configuration error, not a secret. Fix the path or unset the
variable — gitleaks finds .gitleaks.toml in the repo root on its own." >&2
    exit 1
  fi
  "${_gl[@]}" ${GITLEAKS_CONFIG:+--config "$GITLEAKS_CONFIG"} || {
      echo "
Commit blocked: gitleaks found a secret in staged changes.
If it is a false positive, add a rule to .gitleaks.toml — do not use --no-verify." >&2
      exit 1
    }
elif command -v trufflehog >/dev/null 2>&1; then
  # NOTE: trufflehog has no reliable staged-changes mode. Scanning committed
  # history (git file://.) misses the staged-but-uncommitted changes a pre-commit
  # hook exists to catch, so this branch is intentionally conservative: scan the
  # working tree files that are actually staged, file by file.
  # `--fail` exits **183** when results are found (`trufflehog filesystem --help`), not 1.
  # Treating any nonzero as a finding is wrong twice, and the second way is the bad one:
  # without --no-update trufflehog tries to self-update first, and when it cannot write its
  # binary it exits 1 having scanned nothing. Checked on 3.86.0, 2026-09-14 — a file reading
  # "nothing secret here" exited 1 with `error occurred with trufflehog updater: cannot move
  # binary`, and exits 0 with --no-update. So this branch used to block every commit, naming
  # every staged file as a verified secret, on any box whose trufflehog cannot self-update.
  # A hook that cries wolf on every commit is the one that teaches you to pass --no-verify.
  fail=0
  for f in $staged; do
    [ -f "$f" ] || continue
    trufflehog filesystem "$f" --only-verified --fail --no-update >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 183 ]; then
      echo "
Commit blocked: trufflehog found a verified secret in: $f" >&2
      fail=1
    elif [ "$rc" -ne 0 ]; then
      echo "
Commit blocked: trufflehog could not scan $f (exit $rc). That is a scanner failure, not a
secret — run it by hand to see why. Do not bypass this hook with --no-verify." >&2
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
  # shellcheck disable=SC2086
  detect-secrets-hook --baseline .secrets.baseline $staged || {
      echo "
Commit blocked: detect-secrets found a new secret.
Review, then update the baseline deliberately if it is a false positive." >&2
      exit 1
    }
else
  echo "
Commit blocked: no secret scanner installed.
Install one of: gitleaks | trufflehog | detect-secrets
  brew install gitleaks    # or: go install github.com/gitleaks/gitleaks/v8@latest
Then re-commit. Do not bypass this hook with --no-verify." >&2
  exit 1
fi
