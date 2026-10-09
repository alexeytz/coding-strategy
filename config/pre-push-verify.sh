#!/usr/bin/env bash
# Pre-push gate — the enforcement half of phase-2c §6: main only advances on green.
#
# Install into a project:
#   cp config/pre-push-verify.sh <project>/.githooks/pre-push
#   chmod +x <project>/.githooks/pre-push
#   git -C <project> config core.hooksPath .githooks
#
# It holds no verification logic of its own. Per phase-1b §3 the sequence lives
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
# affordable: phase-2c §6 makes work-preservation commits free on a branch, and
# a hook that fired on every push would be the one that teaches --no-verify
# (phase-3e §11 paid for that lesson with a scanner that blocked every commit).
touches_protected=0
while read -r _local_ref _local_sha remote_ref remote_sha; do
  [ -z "${remote_ref:-}" ] && continue
  # A branch deletion arrives here too (remote_sha all zeroes) and is gated the
  # same way: removing the protected branch is a change to it.
  for b in $PROTECTED; do
    [ "$remote_ref" = "refs/heads/$b" ] && touches_protected=1
  done
done
[ "$touches_protected" -eq 0 ] && exit 0

# --- Public or private remote? -----------------------------------------------
# A heuristic, deliberately overridable: the hook cannot know whether a host is
# reachable by strangers. phase-2c §6 asks for a louder warning on a public
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
# phase-2c §6: the operator can override this; it is their repository. Warn once
# on a public remote, then proceed. Do not warn twice — a second objection to a
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
  printf '\n  pre-push: BLOCKED — cannot verify, so cannot let main advance\n'
  printf '    tried:  %s\n' "$VERIFY"
  printf '    This is a setup error, not a test failure. Either create the script\n'
  printf '    (phase-1b §3: one verification entry point that hooks and CI call),\n'
  printf '    point PREPUSH_VERIFY at your suite, or override for this push with\n'
  printf '    PREPUSH_ALLOW_UNVERIFIED=1 git push\n\n'
  exit 1
fi

# --- Run it -------------------------------------------------------------------
printf '  pre-push: %s advances only on green — running %s\n' "$PROTECTED" "$VERIFY"
# Capture the status directly, not after an `if`. `if cmd; then ...; fi` completes
# with status 0 when cmd fails and no else branch runs, so reading $? after the
# `fi` reports 0 for a failed command — which made the 126/127 discrimination
# below dead code and printed "failed (exit 0)". Found by probing this hook, not
# by reading it, on 2026-09-29. Same class as bugs 19, 21 and 22: the exit code
# was not the one being read.
$VERIFY
rc=$?
[ "$rc" -eq 0 ] && exit 0

# Distinguish "failed to run" from "found something". Bugs 19, 21 and 22 in this
# project were all one mistake: treating any nonzero exit as a finding. 126 and
# 127 are the shell telling you it could not execute the thing at all.
case "$rc" in
  126|127)
    printf '\n  pre-push: BLOCKED — the verification command could not be executed (exit %s)\n' "$rc"
    printf '    tried:  %s\n' "$VERIFY"
    printf '    A setup error, not a test failure. Fix the command or set PREPUSH_VERIFY.\n\n' ;;
  *)
    printf '\n  pre-push: BLOCKED — verification failed (exit %s), so main does not advance\n' "$rc"
    printf '    Fix it, or push to a branch instead: that is free and keeps the fallback\n'
    printf '    ref known good (phase-2c §6). To override: PREPUSH_ALLOW_UNVERIFIED=1 git push\n\n' ;;
esac
exit 1
