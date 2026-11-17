#!/usr/bin/env bash
# SessionStart: short reminder injected as context.
set -u
. "$(dirname "$0")/lib.sh"
cat >/dev/null
cmd="$(wf_conf verify_command)"
echo "baton plugin active: for non-trivial tasks follow the 'workflow' skill (reader for lookups, planner for plans, implementer for approved tasks)."
[ -n "$cmd" ] && echo "Verification command for this project: $cmd (run it before reporting a change as done)."
exit 0
