#!/usr/bin/env bash
# Sourced by ledger scripts. Resolves ledger paths + transcript mapping.
: "${WORK_LEDGER_DIR:=$HOME/work-ledger}"
export WORK_LEDGER_DIR
export LEDGER_FILE="$WORK_LEDGER_DIR/work-ledger.md"
export WORK_REPOS_FILE="$WORK_LEDGER_DIR/work-repos.md"
export REVIEWS_DIR="$WORK_LEDGER_DIR/reviews"

# Map an absolute repo path to its Claude Code transcript directory.
transcript_dir_for() {
  # Claude Code replaces every "/" in the abs path with "-".
  printf '%s/.claude/projects/%s' "$HOME" "$(printf '%s' "$1" | sed 's#/#-#g')"
}
