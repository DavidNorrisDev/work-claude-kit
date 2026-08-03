#!/bin/bash
# SessionStart hook: re-ground a new, resumed, or post-compaction session.
# No hook fires when a usage limit kills a session — recovery happens HERE,
# by reading git (always current) + RESUME.md (intent). Stays silent when
# there's nothing worth saying. Excludes the `clear` source (deliberate fresh
# slate) UNLESS /handoff left a one-shot `.handoff-active` marker, which this
# hook consumes to re-ground once. bash 3.2 / BSD-safe. jq is a kit dependency (/usr/bin/jq).
set -uo pipefail

IN="$(cat)"

src="$(jq -r '.source // empty' <<<"$IN" 2>/dev/null)"

dir="$(jq -r '.cwd // empty' <<<"$IN" 2>/dev/null)"
[ -z "$dir" ] && dir="$PWD"

# A deliberate /clear is a blank slate — stay silent — UNLESS this clear was
# initiated by /handoff, which drops a one-shot marker. Consume it so the NEXT
# plain /clear is silent again. ($dir is needed here, so this runs after it.)
if [ "$src" = "clear" ]; then
  [ -f "$dir/.claude/state/.handoff-active" ] || exit 0
  rm -f "$dir/.claude/state/.handoff-active"
fi

state="$dir/.claude/state/RESUME.md"

dirty="$(git -C "$dir" status --porcelain 2>/dev/null)"
# Nothing to resume: no notes AND a clean tree -> say nothing (stay calm).
[ ! -f "$state" ] && [ -z "$dirty" ] && exit 0

ctx="Session resume context — verify against the tree before acting.

"
if [ -f "$state" ]; then
  # Backstop: a terse checkpoint is short; cap a bloated RESUME.md so it can never
  # silently dump thousands of tokens into every session. Whole file on disk regardless.
  cap=120
  lines="$(wc -l < "$state" | tr -d ' ')"
  ctx="${ctx}## Resume notes (.claude/state/RESUME.md)
$(head -n "$cap" "$state")
"
  if [ "${lines:-0}" -gt "$cap" ]; then
    ctx="${ctx}
… [RESUME.md truncated at ${cap}/${lines} lines to protect context — trim it; full file is on disk]
"
  fi
  ctx="${ctx}
"
fi
ctx="${ctx}## Working tree now (git is the source of truth)
\`\`\`
$(git -C "$dir" status --short 2>/dev/null | head -n 40)
\`\`\`
Recent commits:
\`\`\`
$(git -C "$dir" log --oneline -3 2>/dev/null)
\`\`\`
Uncommitted changes vs HEAD:
\`\`\`
$(git -C "$dir" diff --stat HEAD 2>/dev/null | tail -n 15)
\`\`\`"

jq -n --arg c "$ctx" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
exit 0
