#!/bin/bash
# SessionStart hook — weekly-throttled, non-blocking vendored-skills drift check.
#
# Surfaces upstream changes to vendored third-party skills (and any new
# executable file that warrants a re-audit) as session-start context, so drift
# never piles up silently. The actual `--check` (which clones each upstream) runs
# in the BACKGROUND at most once every 7 days — gated by a global stamp in the
# kit's state dir — so it never delays session start. Silent when every skill is
# at its pin. Honours the kit's "reviewed updates" model: it only REPORTS; it
# never bumps a pin or edits a file. bash 3.2 / BSD-safe.
set -u

# Resolve the kit dir even when invoked via an app's .claude/scripts symlink.
SCRIPT_DIR="$(cd -P "$(dirname "$0")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE="$KIT_DIR/.claude/state"
STAMP="$STATE/vendored-check.stamp"
REPORT="$STATE/vendored-drift.txt"
MANIFEST="$KIT_DIR/skills/vendored.manifest"
INTERVAL=$((7 * 24 * 60 * 60))   # 7 days, in seconds

[ -f "$MANIFEST" ] || exit 0                 # no vendored skills → nothing to do
mkdir -p "$STATE" 2>/dev/null || exit 0

# 1) Surface the most recent drift result (if any) as session context.
if [ -s "$REPORT" ]; then
  echo "⚠️  Vendored third-party skills have upstream changes to review:"
  echo
  cat "$REPORT"
  echo
  echo "To act: re-run 'scripts/sync-vendored-skills.sh --check', re-audit, then bump"
  echo "the SHA in skills/vendored.manifest and re-run the sync. Dismiss: rm '$REPORT'"
fi

# 2) Throttle — only launch a fresh check once per INTERVAL.
now="$(date +%s)"
last=0
[ -f "$STAMP" ] && last="$(cat "$STAMP" 2>/dev/null || echo 0)"
case "$last" in ''|*[!0-9]*) last=0 ;; esac
[ $((now - last)) -lt "$INTERVAL" ] && exit 0
printf '%s' "$now" > "$STAMP"

# 3) Run the check detached; record full output only when there's real drift.
nohup bash -c '
  sd="$1"; rep="$2"
  out="$("$sd/sync-vendored-skills.sh" --check 2>&1)" || true
  if printf "%s" "$out" | grep -q "⬆"; then
    printf "%s\n" "$out" > "$rep"
  else
    rm -f "$rep"
  fi
' _ "$SCRIPT_DIR" "$REPORT" >/dev/null 2>&1 &

exit 0
