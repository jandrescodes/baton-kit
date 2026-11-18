#!/usr/bin/env bash
# Behavior tests for the plugin hooks. Pure bash, runs offline.
# Transcript fixtures mirror the real Claude Code format: one JSON object per
# line, tool calls as {"type":"tool_use","id":...,"name":...} with a timestamp,
# subagent transcripts under <session>/subagents/.
set -u
H="$(cd "$(dirname "$0")/.." && pwd)/plugins/baton/hooks"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export CLAUDE_PROJECT_DIR="$T/proj" TMPDIR="$T/tmp"
mkdir -p "$CLAUDE_PROJECT_DIR" "$TMPDIR"
pass=0; fail=0
ok()   { pass=$((pass+1)); }
bad()  { fail=$((fail+1)); echo "FAIL: $1"; }
expect() { # name, actual, wanted-substring ('' = must be empty)
  if [ -z "$3" ]; then [ -z "$2" ] && ok || bad "$1 (expected silence, got: $2)"
  else case "$2" in *"$3"*) ok;; *) bad "$1 (expected '$3', got: $2)";; esac; fi
}

# ---- guard-commit -----------------------------------------------------------
guard() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | bash "$H/guard-commit.sh"; }
rm -f "$CLAUDE_PROJECT_DIR/.baton.conf"
for c in 'git commit -m x' 'git -C /p commit -m x' 'git push origin main' 'git add . \&\& git commit -m z' 'git commit'; do
  expect "guard asks: $c" "$(guard "$c")" '"permissionDecision":"ask"'
done
for c in 'git commit;echo' 'git push\&\&true' "bash -c 'git commit -m x'" '(git commit -m x)' 'git -c alias.ci=commit ci -m x'; do
  expect "guard asks (shell forms): $c" "$(guard "$c")" '"permissionDecision":"ask"'
done
expect "guard asks: JSON-escaped tab" "$(printf '{"tool_name":"Bash","tool_input":{"command":"git\\tcommit -m x"}}' | bash "$H/guard-commit.sh")" '"permissionDecision":"ask"'
git -C "$CLAUDE_PROJECT_DIR" init -q
git -C "$CLAUDE_PROJECT_DIR" config alias.ci commit
git -C "$CLAUDE_PROJECT_DIR" config alias.up push
git -C "$CLAUDE_PROJECT_DIR" config alias.sh '!git commit -a'
git -C "$CLAUDE_PROJECT_DIR" config alias.st status
for c in 'git ci -m x' 'git up' 'git sh'; do
  expect "guard asks (configured alias): $c" "$(guard "$c")" '"permissionDecision":"ask"'
done
expect "guard silent: alias to status" "$(guard 'git st')" ''
for c in 'git status' 'git log --grep commit' 'git commit-tree abc' 'echo git commitment' 'git pull'; do
  expect "guard silent: $c" "$(guard "$c")" ''
done
printf 'commit_guard=off\n' > "$CLAUDE_PROJECT_DIR/.baton.conf"
expect "guard off" "$(guard 'git commit -m x')" ''

# ---- stop-verify ------------------------------------------------------------
printf 'verify_command=bash check.sh\n' > "$CLAUDE_PROJECT_DIR/.baton.conf"
SID=sess; TR="$T/$SID.jsonl"; SUB="$T/$SID/subagents"; mkdir -p "$SUB"
tool() { # name timestamp [command]
  printf '{"message":{"content":[{"type":"tool_use","id":"toolu_1","name":"%s","input":{"command":"%s"}}]},"timestamp":"%s"}\n' "$1" "${3:-}" "$2"
}
noise() { # tool definitions share the names but are not calls
  printf '{"type":"system","tools":[{"name":"Edit"},{"name":"Write"},{"name":"Bash"}],"timestamp":"2026-01-01T09:00:00.000Z"}\n'; }
run() { rm -f "$TMPDIR"/baton-kit-stop-*; printf '{"session_id":"%s","transcript_path":"%s","stop_hook_active":%s}' "$SID" "$TR" "${1:-false}" | bash "$H/stop-verify.sh"; }
reset() { : > "$TR"; rm -f "$SUB"/*.jsonl; }

reset; noise >> "$TR"
expect "stop: tool definitions are not edits" "$(run)" ''
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$TR"
expect "stop: edit without verify blocks" "$(run)" '"decision":"block"'
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$TR"; tool Bash 2026-01-01T10:01:00.000Z 'bash check.sh' >> "$TR"
expect "stop: verify after edit is silent" "$(run)" ''
reset; tool Bash 2026-01-01T10:00:00.000Z 'bash check.sh' >> "$TR"; tool Write 2026-01-01T10:01:00.000Z >> "$TR"
expect "stop: edit after verify blocks" "$(run)" '"decision":"block"'
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$TR"
expect "stop: stop_hook_active is silent" "$(run true)" ''
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$TR"; run >/dev/null
expect "stop: same edit is blocked only once" "$(printf '{"session_id":"%s","transcript_path":"%s"}' "$SID" "$TR" | bash "$H/stop-verify.sh")" ''
reset; tool Read 2026-01-01T10:00:00.000Z >> "$TR"
expect "stop: no edits is silent" "$(run)" ''
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$SUB/agent-a.jsonl"
expect "stop: subagent edit blocks" "$(run)" '"decision":"block"'
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$SUB/agent-a.jsonl"; tool Bash 2026-01-01T10:02:00.000Z 'bash check.sh' >> "$SUB/agent-a.jsonl"
expect "stop: subagent verify is silent" "$(run)" ''
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$SUB/agent-a.jsonl"; tool Bash 2026-01-01T10:02:00.000Z 'bash check.sh' >> "$TR"
expect "stop: main verify after subagent edit is silent" "$(run)" ''
fedit() { # tool timestamp file_path (input shape captured from a real transcript)
  printf '{"message":{"content":[{"type":"tool_use","id":"toolu_1","name":"%s","input":{"file_path":"%s","content":"x"},"caller":{"type":"direct"}}]},"timestamp":"%s"}\n' "$1" "$3" "$2"
}
reset; fedit Write 2026-01-01T10:00:00.000Z /p/.baton.conf >> "$TR"
expect "stop: writing .baton.conf is not an edit" "$(run)" ''
reset; fedit Write 2026-01-01T10:00:00.000Z /p/src/app.txt >> "$TR"
expect "stop: file_path edit blocks" "$(run)" '"decision":"block"'
reset; fedit Write 2026-01-01T10:00:00.000Z /p/src/app.txt >> "$TR"; fedit Write 2026-01-01T10:01:00.000Z /p/.baton.conf >> "$TR"
expect "stop: real edit plus later .baton.conf write still blocks" "$(run)" '"decision":"block"'
reset; fedit Write 2026-01-01T10:00:00.000Z /p/my.baton.conf.bak >> "$TR"
expect "stop: similar filename is still an edit" "$(run)" '"decision":"block"'
reset; tool Edit 2026-01-01T10:00:00.000Z >> "$TR"
rm -f "$CLAUDE_PROJECT_DIR/.baton.conf"
expect "stop: no verify_command does nothing" "$(run)" ''

# ---- session-start ----------------------------------------------------------
printf 'verify_command=make test\n' > "$CLAUDE_PROJECT_DIR/.baton.conf"
out="$(bash "$H/session-start.sh" </dev/null)"
expect "session: mentions the skill" "$out" "'workflow' skill"
expect "session: mentions verify command" "$out" 'make test'
rm -f "$CLAUDE_PROJECT_DIR/.baton.conf"
expect "session: no config, no verify line" "$(bash "$H/session-start.sh" </dev/null | grep -c 'Verification command')" '0'

echo "hooks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
