#!/usr/bin/env bash
# PreToolUse (Bash): `git commit` / `git push` need an explicit user confirmation.
# Disable with `commit_guard=off` in .baton.conf.
set -u
. "$(dirname "$0")/lib.sh"

input="$(cat)"
[ "$(wf_conf commit_guard)" = "off" ] && exit 0

if printf '%s' "$input" | grep -qE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]-][^[:space:]]*)?)*[[:space:]]+(commit|push)([[:space:]]|\\|"|$)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"baton: commits and pushes need your explicit confirmation."}}
JSON
fi
exit 0
