#!/usr/bin/env bash
# Ledger health check — run anytime to confirm capture is working and nothing
# has been lost. Reports entries, date span, the unledgered gap (sessions on
# disk not yet captured), backup status, and the transcript retention edge.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/ledger-env.sh"

echo "== work-ledger health =="
echo "ledger dir:       $WORK_LEDGER_DIR"
if [ ! -f "$LEDGER_FILE" ]; then
  echo "STATUS: no ledger file yet — run install.sh, then the ledger-backfill skill."
  exit 1
fi

# Real entries are dated headers "## 2026-...". (The seed's format example
# starts "## <YYYY-..." so it is correctly not counted.)
entries="$(grep -c '^## 2' "$LEDGER_FILE" 2>/dev/null)" || entries=0
first="$(grep -m1 '^## 2' "$LEDGER_FILE" 2>/dev/null | awk '{print $2}')" || first=""
last="$(grep '^## 2' "$LEDGER_FILE" 2>/dev/null | tail -1 | awk '{print $2}')" || last=""
echo "captured entries: $entries"
echo "date span:        ${first:-none} .. ${last:-none}"

# The gap: real session transcripts on disk not yet in the ledger.
if [ -f "$WORK_REPOS_FILE" ] && grep -q '| active |' "$WORK_REPOS_FILE" 2>/dev/null; then
  gap="$(bash "$DIR/list-unledgered-sessions.sh" 2>/dev/null | wc -l | tr -d ' ')" || gap=0
  if [ "${gap:-0}" -eq 0 ]; then
    echo "unledgered gap:   0 — every session on disk is captured. Healthy."
  else
    echo "unledgered gap:   $gap session(s) on disk not yet captured — run the ledger-backfill skill (or the scheduled job) to close it."
  fi
else
  echo "unledgered gap:   (no active repos in work-repos.md yet — add your work repo paths)"
fi

# Backup status — local history + whether there's an off-machine remote.
if [ -d "$WORK_LEDGER_DIR/.git" ]; then
  lc="$(cd "$WORK_LEDGER_DIR" && git log -1 --format='%cd' --date=short 2>/dev/null)" || lc="none"
  dirty="$(cd "$WORK_LEDGER_DIR" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')" || dirty=0
  remote="$(cd "$WORK_LEDGER_DIR" && git remote get-url origin 2>/dev/null)" || remote=""
  echo "backup (git):     last commit ${lc:-none}; ${dirty:-0} uncommitted change(s)"
  if [ -n "$remote" ]; then
    echo "off-machine:      $remote"
  else
    echo "off-machine:      NONE — local history only. Add a private remote for real durability (see docs/LEDGER.md)."
  fi
else
  echo "backup (git):     NOT git-backed — no history or backup. Re-run install.sh."
fi

# Retention edge: the oldest session transcript still on disk. Anything older
# survives ONLY in the ledger, so capture must stay current.
oldest="$(find "$HOME/.claude/projects" -name '*.jsonl' ! -name 'agent-*' -print0 2>/dev/null | xargs -0 stat -f '%m' 2>/dev/null | sort -n | head -1)" || oldest=""
if [ -n "$oldest" ]; then
  echo "transcripts:      oldest session on disk $(date -r "$oldest" '+%Y-%m-%d') — sessions older than this survive only in the ledger."
fi
