#!/bin/bash
# SessionStart hook — non-blocking context-budget check (passive nudge).
#
# Measures the per-session EAGER files (the project CLAUDE.md and the injected
# RESUME.md) against soft budgets and prints a one-line warning ONLY when one is
# over. Silent when healthy — same "stay calm" design as resume-context.sh. The
# check is a couple of `wc` calls, so it runs every session (no throttle needed).
# It NEVER edits anything: it nudges; the fix (demote learned-patterns to
# docs/LEARNED.md, trim RESUME) stays human-greenlit. bash 3.2 / BSD-safe.
set -u

IN="$(cat 2>/dev/null)"
src="$(printf '%s' "$IN" | jq -r '.source // empty' 2>/dev/null)"
[ "$src" = "clear" ] && exit 0
dir="$(printf '%s' "$IN" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$dir" ] && dir="$PWD"

CLAUDE_MAX=16000   # chars (~4k tokens) — project CLAUDE.md loads every session
RESUME_MAX=110     # lines — soft warn in the danger zone before resume-context.sh's hard 120-line injection cap (normal active RESUMEs run 50-100 lines)

warn=""

c="$dir/CLAUDE.md"
if [ -f "$c" ]; then
  n="$(wc -c < "$c" 2>/dev/null | tr -d ' ')"
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  if [ "$n" -gt "$CLAUDE_MAX" ]; then
    warn="${warn}- CLAUDE.md is ${n} chars (~$((n / 4)) tok, budget ${CLAUDE_MAX}). Demote dated/detail entries to docs/LEARNED.md (loaded on demand) and leave a pointer.
"
  fi
fi

r="$dir/.claude/state/RESUME.md"
if [ -f "$r" ]; then
  rl="$(wc -l < "$r" 2>/dev/null | tr -d ' ')"
  case "$rl" in ''|*[!0-9]*) rl=0 ;; esac
  if [ "$rl" -gt "$RESUME_MAX" ]; then
    warn="${warn}- RESUME.md is ${rl} lines (soft budget ${RESUME_MAX}; injection hard-caps at 120). Archive + trim to a terse checkpoint.
"
  fi
fi

[ -z "$warn" ] && exit 0

printf '⚠️  Context budget — eager files over budget (they load every session):\n\n%s\nThis is a nudge, not a block. Run /token-audit for the full picture.\n' "$warn"
exit 0
