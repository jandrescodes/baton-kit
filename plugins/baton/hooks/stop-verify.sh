#!/usr/bin/env bash
# Stop: if files were edited and the project's verify command was not run
# afterwards, block once and ask for verification. Needs `verify_command=` in
# .baton.conf; without it the hook does nothing.
#
# Edits and verification are looked up in the main transcript and in the
# subagent transcripts next to it (<session>/subagents/*.jsonl), ordered by
# the timestamp each tool call carries.
set -u
. "$(dirname "$0")/lib.sh"

input="$(cat)"
cmd="$(wf_conf verify_command)"
[ -n "$cmd" ] || exit 0

# Already continuing because of a Stop hook: never loop.
printf '%s' "$input" | grep -q '"stop_hook_active" *: *true' && exit 0

transcript="$(printf '%s' "$input" | wf_field transcript_path)"
session="$(printf '%s' "$input" | wf_field session_id)"
[ -f "$transcript" ] || exit 0

files=("$transcript")
for f in "${transcript%.jsonl}"/subagents/*.jsonl; do [ -f "$f" ] && files+=("$f"); done

# Only real tool calls: transcripts also list tool definitions with the same names.
use='"type" *: *"tool_use", *"id" *: *"[^"]*", *"name" *: *'

# latest_ts TOOL_REGEX [FIXED_STRING] -> newest timestamp of a matching tool call.
latest_ts() {
  local f
  for f in "${files[@]}"; do
    if [ -n "${2:-}" ]; then
      grep -E "${use}\"$1\"" "$f" | grep -F -- "$2"
    else
      grep -E "${use}\"$1\"" "$f"
    fi
  done | sed -n 's/.*"timestamp" *: *"\([^"]*\)".*/\1/p' | sort | tail -1
}

last_edit="$(latest_ts '(Edit|Write|MultiEdit|NotebookEdit)')"
[ -n "$last_edit" ] || exit 0

last_verify="$(latest_ts 'Bash' "$cmd")"
[ -n "$last_verify" ] && [[ "$last_verify" > "$last_edit" ]] && exit 0

# Block at most once per last edit, so a deliberate skip is not nagged forever.
state="${TMPDIR:-/tmp}/baton-kit-stop-${session:-unknown}"
[ "$(cat "$state" 2>/dev/null)" = "$last_edit" ] && exit 0
printf '%s' "$last_edit" > "$state"

printf '{"decision":"block","reason":"baton: files were edited but `%s` has not run since. Run it and report the result, or say why it cannot run."}\n' "$cmd"
exit 0
