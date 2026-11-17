#!/usr/bin/env bash
# PreToolUse (Bash): `git commit` / `git push` need an explicit user confirmation.
# Disable with `commit_guard=off` in .baton.conf.
#
# This is a safety net against accidental commits, not a security boundary: it
# matches the raw tool input without parsing shell. It also asks for aliases that
# resolve to commit/push (read from git config) and for `-c alias.*` overrides.
# Permission rules in settings still apply on top of it.
set -u
. "$(dirname "$0")/lib.sh"

input="$(cat)"
[ "$(wf_conf commit_guard)" = "off" ] && exit 0

# Verbs to guard: commit, push, plus any configured alias that expands to them.
verbs="commit|push"
while read -r key value; do
  name="${key#alias.}"
  [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]] || continue
  if printf '%s' "$value" | grep -qE '(^|[[:space:]!])(commit|push)([^A-Za-z0-9_-]|$)'; then
    verbs="$verbs|$name"
  fi
done < <(git -C "$(wf_root)" config --get-regexp '^alias\.' 2>/dev/null)

# Separator: whitespace, or the JSON escapes \t and \n that the raw input carries.
sep='([[:space:]]|\\[tn])+'
opt="-[^[:space:]\\\\]+(${sep}[^[:space:]\\\\-][^[:space:]\\\\]*)?"
# After the verb: anything but a word char or '-', so `commit;` matches and `commit-tree` does not.
re="git(${sep}${opt})*${sep}(${verbs})([^A-Za-z0-9_-]|\$)"

if printf '%s' "$input" | grep -qE "$re" \
   || printf '%s' "$input" | grep -qE "git${sep}(.*${sep})?-c${sep}alias\."; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"baton: commits and pushes need your explicit confirmation."}}
JSON
fi
exit 0
