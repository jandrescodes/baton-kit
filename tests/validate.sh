#!/usr/bin/env bash
# Structural checks that need no network and no Claude CLI.
set -u
R="$(cd "$(dirname "$0")/.." && pwd)"; P="$R/plugins/baton"
fail=0
bad() { echo "FAIL: $1"; fail=1; }
fm() { sed -n '/^---$/,/^---$/p' "$1" | sed '1d;$d' | grep -E "^$2:" | head -1 | cut -d: -f2- | sed 's/^[[:space:]]*//'; }

for j in "$R/.claude-plugin/marketplace.json" "$P/.claude-plugin/plugin.json" "$P/hooks/hooks.json"; do
  python3 -m json.tool "$j" >/dev/null 2>&1 || bad "invalid JSON: ${j#$R/}"
done

for a in "$P"/agents/*.md; do
  n="$(basename "$a" .md)"
  [ "$(fm "$a" name)" = "$n" ] || bad "agent $n: frontmatter name must equal file name"
  [ -n "$(fm "$a" description)" ] || bad "agent $n: missing description"
  case "$(fm "$a" model)" in opus|sonnet|haiku|fable|inherit) ;; *) bad "agent $n: model must be an alias (opus|sonnet|haiku|fable|inherit), got '$(fm "$a" model)'";; esac
done

for s in "$P"/skills/*/; do
  n="$(basename "$s")"; f="$s/SKILL.md"
  [ -f "$f" ] || { bad "skill $n: missing SKILL.md"; continue; }
  [ "$(fm "$f" name)" = "$n" ] || bad "skill $n: frontmatter name must equal folder name"
  [ -n "$(fm "$f" description)" ] || bad "skill $n: missing description"
done

for c in "$P"/commands/*.md; do
  [ -n "$(fm "$c" description)" ] || bad "command $(basename "$c" .md): missing description"
done
[ -f "$P/templates/CLAUDE.md" ] || bad "missing templates/CLAUDE.md"
grep -q 'templates/CLAUDE.md' "$P"/commands/init.md || bad "init command no longer references the template"

for cmd in $(grep -o 'hooks/[A-Za-z0-9._-]*\.sh' "$P/hooks/hooks.json" | sort -u); do
  [ -x "$P/$cmd" ] || bad "hook script missing or not executable: $cmd"
done
for sh in "$P"/hooks/*.sh "$R"/tests/*.sh; do bash -n "$sh" || bad "syntax: ${sh#$R/}"; done

[ "$fail" -eq 0 ] && echo "validate: ok"
exit "$fail"
