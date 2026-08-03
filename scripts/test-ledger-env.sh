#!/usr/bin/env bash
# test-ledger-env.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export WORK_LEDGER_DIR="$(mktemp -d)"
. "$DIR/ledger-env.sh"
[ "$LEDGER_FILE" = "$WORK_LEDGER_DIR/work-ledger.md" ] || { echo "FAIL LEDGER_FILE"; exit 1; }
got="$(transcript_dir_for /Users/david/Projects/Foo)"
want="$HOME/.claude/projects/-Users-david-Projects-Foo"
[ "$got" = "$want" ] || { echo "FAIL transcript_dir_for: $got != $want"; exit 1; }
echo "PASS"
