#!/bin/bash
# PostToolUse: format Swift files Claude just touched.
# Claude generates good code; this handles the last 10% so CI never fails on style.
set -euo pipefail

# Claude Code passes the tool payload on stdin as JSON.
FILE=$(jq -r '.tool_input.file_path // empty' 2>/dev/null <<<"$(cat)")

[ -z "${FILE:-}" ] && exit 0
case "$FILE" in
  *.swift) ;;
  *) exit 0 ;;
esac

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat "$FILE" --quiet || true
fi
exit 0
