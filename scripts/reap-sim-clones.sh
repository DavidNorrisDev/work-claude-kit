#!/bin/bash
# Reap leaked simulator clones left behind by interrupted `xcodebuild test` runs.
#
# Parallel testing creates "Clone N of <device>" simulators, one per worker, and
# normally deletes them when the run finishes. A run killed mid-flight — usage
# limit, timeout, /clear, a closed laptop — orphans its whole clone set. Across
# many projects those leaked clones have reached 150GB+. This sweeps them up.
#
# SAFE under concurrent sessions: only *Shutdown* clones are deleted. A clone
# that belongs to a live test run in another session is Booted and is never
# touched. Used by the SessionStart hook (silent unless it frees space) and
# runnable by hand (prints a one-line summary).
set -uo pipefail

command -v xcrun >/dev/null 2>&1 || exit 0
command -v jq    >/dev/null 2>&1 || exit 0

# UDIDs of shutdown clones (name starts with "Clone ").
clones="$(xcrun simctl list devices -j 2>/dev/null \
  | jq -r '.devices | to_entries[] | .value[]
           | select(.name | startswith("Clone "))
           | select(.state == "Shutdown")
           | .udid' 2>/dev/null)"

n=0
while IFS= read -r udid; do
  [ -n "$udid" ] || continue
  xcrun simctl delete "$udid" >/dev/null 2>&1 && n=$((n + 1))
done <<<"$clones"

# Also drop devices whose runtime is gone (cheap, always safe).
xcrun simctl delete unavailable >/dev/null 2>&1 || true

[ "$n" -gt 0 ] && echo "Reaped $n leaked simulator clone(s)."
exit 0
