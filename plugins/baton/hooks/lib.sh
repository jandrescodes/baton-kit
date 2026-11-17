#!/usr/bin/env bash
# Shared helpers. Pure bash + coreutils: no jq, no python.

# Project root as seen by the session; falls back to the current directory.
wf_root() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

# wf_conf KEY -> last value of KEY in <root>/.baton.conf (empty if absent).
# The file is parsed, never sourced, so it cannot execute anything.
wf_conf() {
  local f; f="$(wf_root)/.baton.conf"
  [ -f "$f" ] || return 0
  grep -E "^$1=" "$f" | tail -1 | cut -d= -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# wf_field NAME <<< json -> value of a top-level string field (no nesting).
wf_field() { sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -1; }
