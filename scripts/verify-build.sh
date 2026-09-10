#!/bin/bash
# PostToolUse: incremental build so Claude gets a tight verify loop.
# "Give Claude a way to verify its work" is the single highest-leverage practice.
# Exit non-zero with the error on stderr -> Claude sees it and fixes the root cause.
#
# Hardened against concurrent builds: many Claude sessions across many projects
# would otherwise launch many simultaneous xcodebuilds and thrash the machine.
# A self-healing counting semaphore caps how many verify-builds run at once
# (VERIFY_MAX_BUILDS, default 2). Excess invocations wait their turn; if the
# machine stays saturated past VERIFY_BUILD_WAIT seconds the build is skipped
# (exit 0 — not reported as a failure) rather than piled on.
set -uo pipefail

# Only build on Swift edits.
case "$(jq -r '.tool_input.file_path // empty' <<<"$(cat)")" in
  *.swift) ;;
  *) exit 0 ;;
esac

: "${SCHEME:?SCHEME env var not set — set it in the app CLAUDE.md / shell}"

# Destination + container come from verify-resolve.sh: VERIFY_DESTINATION wins
# verbatim; otherwise macOS-only projects get platform=macOS and simulator
# names resolve to a UDID on the newest iOS runtime (by-name is ambiguous on
# machines with duplicate device names across runtimes).
HERE="$(cd -P "$(dirname "$0")" && pwd)"
. "$HERE/verify-resolve.sh"
pl_resolve_destination >/dev/null
DESTINATION="$PL_DESTINATION"
if [ -n "${PL_DEST_NOTE:-}" ]; then printf '⚠️  %s\n' "$PL_DEST_NOTE"; fi
MAX_BUILDS="${VERIFY_MAX_BUILDS:-2}"
WAIT_BUDGET="${VERIFY_BUILD_WAIT:-240}"
STALE_AFTER=1800   # reclaim a slot whose holder has run longer than this (s)

# --- Counting semaphore: caps concurrent xcodebuilds machine-wide -----------
SEM_DIR="${TMPDIR:-/tmp}/pl-verify-build"
mkdir -p "$SEM_DIR" 2>/dev/null || true
MY_SLOT=""

release_slot() { [ -n "$MY_SLOT" ] && rm -rf "$MY_SLOT" 2>/dev/null; MY_SLOT=""; }
trap release_slot EXIT INT TERM

try_acquire() {
  i=1
  while [ "$i" -le "$MAX_BUILDS" ]; do
    slot="$SEM_DIR/slot.$i"
    if mkdir "$slot" 2>/dev/null; then
      echo $$ > "$slot/pid" 2>/dev/null
      MY_SLOT="$slot"
      return 0
    fi
    # Slot held — reclaim it if the holder died or has been building absurdly long.
    pid="$(cat "$slot/pid" 2>/dev/null || echo '')"
    agem="$(stat -f %m "$slot/pid" 2>/dev/null || echo 0)"
    nowt="$(date +%s 2>/dev/null || echo 0)"
    if { [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; } \
       || { [ "$agem" -gt 0 ] && [ "$((nowt - agem))" -ge "$STALE_AFTER" ]; }; then
      rm -rf "$slot" 2>/dev/null
      continue   # retry the same slot index
    fi
    i=$((i + 1))
  done
  return 1
}

start="$(date +%s 2>/dev/null || echo 0)"
until try_acquire; do
  now="$(date +%s 2>/dev/null || echo 0)"
  if [ "$((now - start))" -ge "$WAIT_BUDGET" ]; then
    # Saturated too long — skip rather than add to the pileup. Exit 0 so Claude
    # is not told the code is broken (it simply got no fresh verification here).
    exit 0
  fi
  sleep 2
done

# --- Build (slot held; released by the trap on any exit) --------------------
# pl_resolve_container honours VERIFY_WORKSPACE, else passes the single
# discovered workspace/project explicitly (root-level OR one level down);
# zero or several candidates fall back to xcodebuild's own cwd discovery.
pl_resolve_container
if [ -n "$PL_CONTAINER_FLAG" ]; then
  OUT="$(xcodebuild "$PL_CONTAINER_FLAG" "$PL_CONTAINER_PATH" -scheme "$SCHEME" -destination "$DESTINATION" build 2>&1)"
else
  OUT="$(xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" build 2>&1)"
fi
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  echo "BUILD FAILED. Fix the root cause (do not suppress):" >&2
  echo "$OUT" | grep -E 'error:|warning:.*deprecated' | tail -n 25 >&2
  exit 2   # exit code 2 surfaces stderr back into Claude's context
fi

# House rule: builds stay warning-free. Surface any warning in the app's OWN sources
# (third-party packages under SourcePackages/DerivedData are out of our control) so it gets
# resolved this turn rather than accruing. Exit 2 pushes the list back into Claude's context.
WARNINGS="$(echo "$OUT" | grep -E 'warning:' | grep -vE 'SourcePackages/checkouts|/DerivedData/' | sort -u)"
if [ -n "$WARNINGS" ]; then
  echo "BUILD SUCCEEDED but introduced warnings — resolve them (house rule: warning-free builds):" >&2
  echo "$WARNINGS" | tail -n 25 >&2
  exit 2
fi
exit 0
