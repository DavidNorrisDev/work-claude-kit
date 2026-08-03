#!/bin/bash
# Run the test suite the safe way: NO simulator cloning, so an interrupted run
# can't leak "Clone N of ..." simulators (these have reached 150GB+ across
# projects). Use this instead of raw `xcodebuild test`.
#
#   SCHEME=MyApp ./.claude/scripts/verify-test.sh
#   ./.claude/scripts/verify-test.sh -only-testing:MyAppTests/ExampleTests
#
# Extra args pass through to xcodebuild. `-parallel-testing-enabled NO` keeps the
# run on the single named simulator — zero clones, nothing to leak. (Swift
# Testing parallelises in-process anyway, so this barely changes wall-clock for
# unit suites.) Output is capped like verify-build.sh: the failure tail lands in
# context, not the whole log.
set -uo pipefail

: "${SCHEME:?SCHEME env var not set — set it in the app CLAUDE.md / shell}"

HERE="$(cd -P "$(dirname "$0")" && pwd)"
# Belt-and-braces: reap any leaked clones however we exit (incl. interruption).
cleanup() { "$HERE/reap-sim-clones.sh" >/dev/null 2>&1 || true; }
trap cleanup EXIT INT TERM

# Destination + container from verify-resolve.sh: VERIFY_DESTINATION wins
# verbatim; macOS-only projects get platform=macOS; simulator names resolve to
# a UDID on the newest iOS runtime. pl_resolve_container honours
# VERIFY_WORKSPACE, else passes the single discovered workspace/project.
. "$HERE/verify-resolve.sh"
DESTINATION="$(pl_resolve_destination)"
pl_resolve_container
if [ -n "$PL_CONTAINER_FLAG" ]; then
  OUT="$(xcodebuild "$PL_CONTAINER_FLAG" "$PL_CONTAINER_PATH" -scheme "$SCHEME" -destination "$DESTINATION" \
          -parallel-testing-enabled NO \
          test "$@" 2>&1)"
else
  OUT="$(xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" \
          -parallel-testing-enabled NO \
          test "$@" 2>&1)"
fi
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  echo "TESTS FAILED. Fix the root cause (do not suppress):" >&2
  echo "$OUT" | grep -E 'error:|: error|failed|XCTAssert|Test Case .* failed|Testing failed' | tail -n 30 >&2
  exit 2
fi
echo "Tests passed."
exit 0
