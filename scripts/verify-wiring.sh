#!/bin/bash
# verify-wiring.sh — full audit that an app's kit wiring is live and complete:
# the five symlinks (skills/agents/scripts/settings.json/CLAUDE.global.md)
# resolve into the kit, CLAUDE.md imports the shared conventions, SCHEME is
# exported for the hooks, .claude/state exists, and the repo is on the
# roster. Guards against the failure mode where a repo silently stops
# receiving kit improvements.
#
#   verify-wiring.sh [app-dir]          # verbose, exit 1 on first failure
#   verify-wiring.sh --warn [app-dir]   # print all drift, always exit 0,
#                                       # SILENT when clean (SessionStart use)
#
# bash 3.2 / BSD safe. Works invoked from the kit path or via an app's
# .claude/scripts symlink (kit resolved physically from $0).
set -u

WARN=false
[ "${1:-}" = "--warn" ] && { WARN=true; shift; }
APP_DIR_ARG="${1:-$PWD}"
RESOLVED_APP_DIR="$(cd -P "$APP_DIR_ARG" 2>/dev/null && pwd)"
if [ -z "$RESOLVED_APP_DIR" ]; then
  if $WARN; then
    # --warn's contract is "always exit 0, silent when clean" — a missing
    # directory isn't clean, so it still gets reported, just without dying.
    printf 'kit-wiring drift (%s): no such directory\n' "$APP_DIR_ARG"
    exit 0
  fi
  echo "verify-wiring: no such dir: $APP_DIR_ARG" >&2
  exit 1
fi
APP_DIR="$RESOLVED_APP_DIR"

# Resolve the kit PHYSICALLY from this script's own location, so invocation
# via .claude/scripts (a symlink) still finds the real kit.
KIT_DIR="$(cd -P "$(dirname "$0")/.." && pwd)"

# The kit repo itself is not an app — nothing to verify, say nothing.
[ "$APP_DIR" -ef "$KIT_DIR" ] && exit 0

fail() {
  if $WARN; then
    printf 'kit-wiring drift (%s): %s\n' "$(basename "$APP_DIR")" "$1"
  else
    printf 'verify-wiring: FAIL — %s\n' "$1" >&2
    exit 1
  fi
}

# 1. Directory symlinks resolve into the kit.
for item in skills agents scripts; do
  LINK="$APP_DIR/.claude/$item"
  if [ ! -e "$LINK" ]; then
    fail ".claude/$item missing (run ./wire-repo.sh <repo-dir> <scheme>)"
  elif [ ! -L "$LINK" ]; then
    fail ".claude/$item is a real directory, not a symlink — kit updates will NOT appear here; re-run ./wire-repo.sh <repo-dir> <scheme>"
  else
    RESOLVED="$(cd -P "$LINK" 2>/dev/null && pwd)"
    [ "$RESOLVED" = "$KIT_DIR/$item" ] || fail ".claude/$item resolves to ${RESOLVED:-broken}, expected $KIT_DIR/$item"
  fi
done

# 2. settings.json symlink resolves to the kit's.
SJ="$APP_DIR/.claude/settings.json"
if [ ! -L "$SJ" ]; then
  fail ".claude/settings.json is not a symlink into the kit"
elif [ ! "$SJ" -ef "$KIT_DIR/settings.json" ]; then
  fail ".claude/settings.json does not resolve to the kit's settings.json"
fi

# 3. CLAUDE.global.md symlink resolves to the kit's (wire-repo.sh creates
#    this; deleting it leaves CLAUDE.md's @CLAUDE.global.md import dangling
#    even though check 4 below still finds the import line itself).
GC="$APP_DIR/CLAUDE.global.md"
if [ ! -L "$GC" ]; then
  fail "CLAUDE.global.md is not a symlink into the kit"
elif [ ! "$GC" -ef "$KIT_DIR/CLAUDE.global.md" ]; then
  fail "CLAUDE.global.md does not resolve to the kit's CLAUDE.global.md"
fi

# 4. CLAUDE.md imports the shared conventions.
grep -q "@CLAUDE.global.md" "$APP_DIR/CLAUDE.md" 2>/dev/null \
  || fail "CLAUDE.md missing the @CLAUDE.global.md import (kit-managed block)"

# 5. SCHEME exported for the hooks. Nothing in the kit sources .envrc
#    itself — it's there for direnv (or a manual `. .claude/.envrc`) to load
#    SCHEME into the shell env that verify-build.sh/verify-test.sh then read.
grep -q "export SCHEME=" "$APP_DIR/.claude/.envrc" 2>/dev/null \
  || fail ".claude/.envrc missing 'export SCHEME=' (source it, e.g. via direnv, so SCHEME lands in the shell env the verify hooks read)"

# 6. Per-app working memory dir.
[ -d "$APP_DIR/.claude/state" ] || fail ".claude/state/ missing (session resilience)"

# 7. On the roster (work-ledger's work-repos.md — stood up by a later plan;
#    no-op for now if the ledger doesn't exist yet). Canonical schema is one
#    row per repo, "| name | abs-path | scheme | status |" — the same shape
#    wire-repo.sh writes and list-unledgered-sessions.sh reads. Column 2 is
#    the repo's ABSOLUTE path; membership is an exact match against $APP_DIR,
#    which was already resolved to an absolute, symlink-free path above.
ROSTER="${WORK_LEDGER_DIR:-$HOME/work-ledger}/work-repos.md"
[ -f "$ROSTER" ] || exit 0
FOUND=false
while IFS='|' read -r _ _name path _scheme _status _rest; do
  path="$(echo "$path" | sed 's/^ *//;s/ *$//')"
  case "$path" in ''|'/absolute/repo/path'|'---'*) continue;; esac
  [ "$path" = "$APP_DIR" ] && FOUND=true
done < "$ROSTER"
$FOUND || fail "no work-repos.md row with path '$APP_DIR' — add one (or mark excluded)"

# 8. Agent-count parity (stale-symlink canary).
kit_n=$(ls -1 "$KIT_DIR/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
app_n=$(ls -1 "$APP_DIR/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$kit_n" = "$app_n" ] || fail "app sees $app_n agents but the kit has $kit_n"

if $WARN; then
  exit 0
fi
printf 'verify-wiring: OK — %s wiring is live and complete\n' "$(basename "$APP_DIR")"
