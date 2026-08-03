#!/usr/bin/env bash
# List Claude Code sessions not yet in the ledger, optionally within a range.
#   list-unledgered-sessions.sh [since-epoch] [until-epoch]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/ledger-env.sh"

SINCE="${1:-0}"
UNTIL="${2:-9999999999}"
[ -f "$WORK_REPOS_FILE" ] || exit 0
[ -f "$LEDGER_FILE" ] || : > "$LEDGER_FILE"

# Read active repo rows: "| name | abs-path | scheme | status |"
while IFS='|' read -r _ name path _scheme status _rest; do
  name="$(echo "$name" | sed 's/^ *//;s/ *$//')"
  path="$(echo "$path" | sed 's/^ *//;s/ *$//')"
  status="$(echo "$status" | sed 's/^ *//;s/ *$//')"
  case "$path" in ''|'/absolute/repo/path'|'---'*) continue;; esac
  [ "$status" = "active" ] || continue
  tdir="$(transcript_dir_for "$path")"
  [ -d "$tdir" ] || continue
  for f in "$tdir"/*.jsonl; do
    [ -e "$f" ] || continue
    sid="$(basename "$f" .jsonl)"
    case "$sid" in agent-*) continue;; esac   # skip subagent transcripts — not sessions
    grep -q "session-id: $sid" "$LEDGER_FILE" && continue
    mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)"
    [ "$mtime" -ge "$SINCE" ] && [ "$mtime" -le "$UNTIL" ] || continue
    printf '%s\t%s\t%s\n' "$name" "$sid" "$f"
  done
done < "$WORK_REPOS_FILE"
