#!/usr/bin/env bash
# Wire a work repo to the shared work-claude-kit. Idempotent.
#   ./wire-repo.sh /path/to/CompanyApp CompanyAppScheme
set -euo pipefail

APP_DIR="${1:?Usage: wire-repo.sh <repo-dir> <scheme>}"
SCHEME="${2:?Usage: wire-repo.sh <repo-dir> <scheme>}"
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEDGER_DIR="${WORK_LEDGER_DIR:-$HOME/work-ledger}"

mkdir -p "$APP_DIR/.claude/state"
ln -sfn "$KIT_DIR/skills"            "$APP_DIR/.claude/skills"
ln -sfn "$KIT_DIR/agents"            "$APP_DIR/.claude/agents"
ln -sfn "$KIT_DIR/scripts"           "$APP_DIR/.claude/scripts"
ln -sf  "$KIT_DIR/settings.json"     "$APP_DIR/.claude/settings.json"
ln -sfn "$KIT_DIR/CLAUDE.global.md"  "$APP_DIR/CLAUDE.global.md"
chmod +x "$KIT_DIR/scripts/"*.sh 2>/dev/null || true

# .envrc holds the export for direnv (or a manual `. .claude/.envrc`) to load
# into the shell that runs the verify hooks — it is not sourced by anything
# in the kit itself. Idempotent: only appended when the line isn't there yet.
if ! grep -q "export SCHEME=" "$APP_DIR/.claude/.envrc" 2>/dev/null; then
  printf 'export SCHEME="%s"\n' "$SCHEME" >> "$APP_DIR/.claude/.envrc"
fi

if [ -L "$APP_DIR/CLAUDE.md" ]; then
  # A symlinked CLAUDE.md is left exactly alone — rewriting it would silently
  # replace the link with a plain file. Warn only if the import looks absent
  # (through the link, at whatever it points to).
  grep -q "@CLAUDE.global.md" "$APP_DIR/CLAUDE.md" 2>/dev/null \
    || echo "wire-repo: $APP_DIR/CLAUDE.md is a symlink — not touching it. Add the @CLAUDE.global.md import to its target by hand." >&2
else
  if [ ! -f "$APP_DIR/CLAUDE.md" ]; then
    cp "$KIT_DIR/CLAUDE.app-template.md" "$APP_DIR/CLAUDE.md"
    echo "Seeded $APP_DIR/CLAUDE.md — fill in bundle IDs / schemes / tokens."
  fi

  # Make sure the kit-managed import is present. A freshly-seeded CLAUDE.md
  # already carries it (from CLAUDE.app-template.md, cp'd above with a sane
  # mode from umask); an existing CLAUDE.md that predates this only gets the
  # one line prepended, untouched otherwise. Written via a unique temp file +
  # `mv -f` (never a fixed ".tmp" name, never a bare `mv` that a BSD tty
  # prompt could turn into a silent no-op against a read-only CLAUDE.md) with
  # a trap so the temp file cannot survive any exit path — success, failure,
  # or an unrelated abort mid-block. `mktemp` defaults to mode 0600, so the
  # original file's permission bits are read first (BSD `stat -f %Lp`; BSD
  # `chmod` has no `--reference`) and reapplied to the temp file before the
  # swap, so the rewrite never silently changes CLAUDE.md's mode. Falls back
  # to 644 if the mode can't be read for some reason.
  if ! grep -q "@CLAUDE.global.md" "$APP_DIR/CLAUDE.md" 2>/dev/null; then
    ORIG_MODE="$(stat -f %Lp "$APP_DIR/CLAUDE.md" 2>/dev/null || echo '')"
    TMP_CLAUDE="$(mktemp "$APP_DIR/.CLAUDE.md.XXXXXX")"
    trap 'rm -f "$TMP_CLAUDE"' EXIT
    { printf '@CLAUDE.global.md\n\n'; cat "$APP_DIR/CLAUDE.md"; } > "$TMP_CLAUDE"
    chmod "${ORIG_MODE:-644}" "$TMP_CLAUDE"
    if mv -f "$TMP_CLAUDE" "$APP_DIR/CLAUDE.md"; then
      trap - EXIT
      echo "Added @CLAUDE.global.md import to $APP_DIR/CLAUDE.md."
    else
      rc=$?
      trap - EXIT
      rm -f "$TMP_CLAUDE"
      echo "wire-repo: failed to write $APP_DIR/CLAUDE.md (mv exit $rc)." >&2
      exit 1
    fi
  fi
fi

# Record the repo in the ledger roster so the miner and check-in sweep it.
# Physical (-P) path: verify-wiring.sh and Claude Code's own transcript
# naming both resolve through symlinks, so a logical path here would never
# match on a repo reached via a symlinked component (a `/var` mount, a `~/work`
# symlink, an external volume) — verify-wiring would then warn "not on the
# roster" forever, for a repo that was correctly wired seconds earlier.
ABS="$(cd -P "$APP_DIR" && pwd)"
mkdir -p "$LEDGER_DIR"
touch "$LEDGER_DIR/work-repos.md"

# Migrate a stale pre-fix row that recorded this same repo under its logical
# (non -P) path, so re-wiring after this fix updates the existing row in
# place rather than leaving the old one stale and appending a duplicate.
LOGICAL_ABS="$(cd "$APP_DIR" && pwd)"
if [ "$LOGICAL_ABS" != "$ABS" ] && grep -q "| $LOGICAL_ABS |" "$LEDGER_DIR/work-repos.md" 2>/dev/null; then
  TMP_ROSTER="$(mktemp "$LEDGER_DIR/.work-repos.md.XXXXXX")"
  trap 'rm -f "$TMP_ROSTER"' EXIT
  sed "s#| $LOGICAL_ABS |#| $ABS |#" "$LEDGER_DIR/work-repos.md" > "$TMP_ROSTER"
  mv -f "$TMP_ROSTER" "$LEDGER_DIR/work-repos.md"
  trap - EXIT
  echo "Migrated stale roster row from $LOGICAL_ABS to the physical path $ABS."
fi

if ! grep -q "| $ABS |" "$LEDGER_DIR/work-repos.md" 2>/dev/null; then
  echo "| $SCHEME | $ABS | $SCHEME | active |" >> "$LEDGER_DIR/work-repos.md"
  echo "Recorded $ABS in $LEDGER_DIR/work-repos.md."
fi
echo "Wired $APP_DIR to the work kit."
