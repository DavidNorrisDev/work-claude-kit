#!/usr/bin/env bash
# test-list-unledgered-sessions.sh — uses fake transcript dirs + ledger.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export WORK_LEDGER_DIR="$(mktemp -d)"
. "$DIR/ledger-env.sh"
# Fake a repo + its transcript dir with two sessions.
REPO="$(mktemp -d)"; RepoName="$(basename "$REPO")"
TDIR="$(transcript_dir_for "$REPO")"; mkdir -p "$TDIR"
echo '{}' > "$TDIR/aaaa1111.jsonl"
echo '{}' > "$TDIR/bbbb2222.jsonl"
printf '# repos\n| %s | %s | %s | active |\n' "$RepoName" "$REPO" "$RepoName" > "$WORK_REPOS_FILE"
# Ledger already has session aaaa1111 -> only bbbb2222 should list.
printf '# ledger\n## x\n<!-- session-id: aaaa1111 -->\n' > "$LEDGER_FILE"
out="$(bash "$DIR/list-unledgered-sessions.sh")"
echo "$out" | grep -q bbbb2222 || { echo "FAIL: bbbb2222 missing"; exit 1; }
echo "$out" | grep -q aaaa1111 && { echo "FAIL: aaaa1111 should be excluded"; exit 1; }
echo "PASS"
