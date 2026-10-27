#!/usr/bin/env bash
# Pre-push gate - the enforcement half of 25.6: main only advances on green.
#
# Why: once unverified work lands on main, main stops being the version you can fall back to.
# This runs your scripts/verify.sh on a push to a protected branch and refuses the push if it
# fails or if the checkout it verified is not the commit being pushed. More: config/README.md.
#
# Install into a project:
#   cp config/pre-push-verify.sh <project>/.githooks/pre-push
#   chmod +x <project>/.githooks/pre-push
#   git -C <project> config core.hooksPath .githooks
#   git -C <project> add .githooks && git -C <project> commit -m "docs: install hooks"
#
# Commit it: the gate refuses untracked files, its own included, and an uncommitted hook is not
# installed for anyone else either.
#
# It holds no verification logic of its own. Per 4.4 the sequence lives
# in scripts/verify.sh and hooks call it, so this hook decides only *whether* to
# run it and what a failure means.
#
# Configuration, all optional:
#   PREPUSH_VERIFY             command to run (default: ./scripts/verify.sh)
#   PREPUSH_MAIN_BRANCHES      space-separated protected branches (default: "main master")
#   PREPUSH_PUBLIC             1 or 0 to override public-remote detection
#   PREPUSH_ALLOW_UNVERIFIED   set to any value to override the gate for one push
set -uo pipefail

VERIFY="${PREPUSH_VERIFY:-./scripts/verify.sh}"
PROTECTED="${PREPUSH_MAIN_BRANCHES:-main master}"
remote_url="${2:-}"

# --- Is this push touching a protected branch? -------------------------------
# Pushes to anything else exit silently. That is the whole reason the gate is
# affordable: 25.7 makes work-preservation commits free on a branch, and
# a hook that fired on every push would be the one that teaches --no-verify
# (pre-commit-secret-scan.sh records the incident: a scanner that blocked
# every commit; 20.5 traces its cause).
touches_protected=0
pushed=""
while read -r _local_ref local_sha remote_ref remote_sha; do
  [ -z "${remote_ref:-}" ] && continue
  # A branch deletion arrives here too (local_sha all zeroes) and is gated the
  # same way: removing the protected branch is a change to it.
  for b in $PROTECTED; do
    if [ "$remote_ref" = "refs/heads/$b" ]; then
      touches_protected=1
      case "$local_sha" in *[!0]*) pushed="$pushed $local_sha" ;; esac
    fi
  done
done
[ "$touches_protected" -eq 0 ] && exit 0

# --- Public or private remote? -----------------------------------------------
# A heuristic, deliberately overridable: the hook cannot know whether a host is
# reachable by strangers. 25.8 asks for a louder warning on a public
# remote because a public ref is copied within minutes and cannot be unpublished.
is_public=0
if [ -n "${PREPUSH_PUBLIC:-}" ]; then
  is_public="$PREPUSH_PUBLIC"
else
  case "$remote_url" in
    *github.com*|*gitlab.com*|*bitbucket.org*|*codeberg.org*|*sr.ht*) is_public=1 ;;
  esac
fi

# --- Operator override --------------------------------------------------------
# 25.8: the operator can override this; it is their repository. Warn once
# on a public remote, then proceed. Do not warn twice - a second objection to a
# reaffirmed instruction is refusing the operator's call in slow motion.
if [ -n "${PREPUSH_ALLOW_UNVERIFIED:-}" ]; then
  if [ "$is_public" = "1" ]; then
    printf '\n  pre-push: PUSHING UNVERIFIED WORK TO A PUBLIC REMOTE\n'
    printf '    remote:   %s\n' "${remote_url:-<unknown>}"
    printf '    verify:   %s (not run)\n' "$VERIFY"
    printf '    A public ref is copied by clones, forks, mirrors and other CI within\n'
    printf '    minutes. It cannot be unpublished. The fallback ref is now unverified.\n\n'
  else
    printf '  pre-push: gate overridden by PREPUSH_ALLOW_UNVERIFIED (private remote)\n'
  fi
  exit 0
fi

# --- Fail closed if there is nothing to run ----------------------------------
# Same rule as the secret-scan hook: a gate that cannot verify must block, not
# pass. A pre-push hook that silently no-ops is worse than none, because the
# green main branch it is supposed to guarantee becomes an assumption again.
verify_cmd="${VERIFY%% *}"
if [ ! -x "$verify_cmd" ] && ! command -v "$verify_cmd" >/dev/null 2>&1; then
  printf '\n  pre-push: BLOCKED - cannot verify, so cannot let main advance\n'
  printf '    tried:  %s\n' "$VERIFY"
  printf '    This is a setup error, not a test failure. Either create the script\n'
  printf '    (4.4: one verification entry point that hooks and CI call),\n'
  printf '    point PREPUSH_VERIFY at your suite, or override for this push with\n'
  printf '    PREPUSH_ALLOW_UNVERIFIED=1 git push\n\n'
  exit 1
fi

# --- The checkout must be what is being pushed ----------------------------------
# Verification runs on the working tree, so a green run proves only what is checked
# out. A commit with an uncommitted fix on top, or `git push origin feature:main`
# from a clean main, passed this gate red (found in review, 2026-10-20), and so did a
# commit that imports a file never `git add`ed (found in review). Refuse all three
# rather than check out each pushed commit: a fresh worktree lacks the ignored
# files a real suite needs (.venv, node_modules, .env) and would fail green work,
# and a gate that cries wolf is the one people skip. What it cannot see: a commit
# that depends on an *ignored* file still passes. Untracked scratch belongs in
# .gitignore, or it blocks the push - including what verify itself writes: in a
# repo that does not ignore __pycache__/, the push after the first verify run is
# refused until it does (found in review). Not exempted: remembering verify's own
# output would also exempt a needed file that existed before it ran.
head="$(git rev-parse HEAD 2>/dev/null || echo none)"
dirty="$(git status --porcelain --untracked-files=normal)"  # whatever status.showUntrackedFiles says
for sha in $pushed; do
  if [ "$sha" != "$head" ] || [ -n "$dirty" ]; then
    printf '\n  pre-push: BLOCKED - the checkout does not match the push to %s\n' "$PROTECTED"
    printf '    pushing: %s   checked out: %s\n' "${sha:0:12}" "${head:0:12}"
    [ -n "$dirty" ] && printf '    uncommitted or untracked:\n%s\n' "$(printf '%s\n' "$dirty" | head -n 5 | sed 's/^/      /')"
    printf '    Verification runs on the checkout. Check out the commit you are pushing,\n'
    printf '    commit, ignore or remove what is listed, and push again. Build output from\n'
    printf '    a verify run (__pycache__/, dist/, coverage files) belongs in .gitignore.\n\n'
    exit 1
  fi
done

# --- Run it -------------------------------------------------------------------
printf '  pre-push: %s advances only on green - running %s\n' "$PROTECTED" "$VERIFY"
# Capture the status directly, not after an `if`. `if cmd; then ...; fi` completes
# with status 0 when cmd fails and no else branch runs, so reading $? after the
# `fi` reports 0 for a failed command - which made the 126/127 discrimination
# below dead code and printed "failed (exit 0)". Found by probing this hook, not
# by reading it, on 2026-09-29. Same class as the mistake below: the exit code
# was not the one being read.
$VERIFY
rc=$?
[ "$rc" -eq 0 ] && exit 0

# Distinguish "failed to run" from "found something". Three bugs in the skill's own
# scripts were one mistake: treating any nonzero exit as a finding. 126 and
# 127 are the shell telling you it could not execute the thing at all.
case "$rc" in
  126|127)
    printf '\n  pre-push: BLOCKED - the verification command could not be executed (exit %s)\n' "$rc"
    printf '    tried:  %s\n' "$VERIFY"
    printf '    A setup error, not a test failure. Fix the command or set PREPUSH_VERIFY.\n\n' ;;
  *)
    printf '\n  pre-push: BLOCKED - verification failed (exit %s), so main does not advance\n' "$rc"
    printf '    Fix it, or push to a branch instead: that is free and keeps the fallback\n'
    printf '    ref known good (25.6). To override: PREPUSH_ALLOW_UNVERIFIED=1 git push\n\n' ;;
esac
exit 1
