#!/bin/bash
# test-verify-wiring.sh — fixture test for verify-wiring.sh (bash 3.2 / BSD safe)
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); }
bad()  { FAIL=$((FAIL+1)); printf 'test FAIL: %s\n' "$1"; }

# --- fixture kit ------------------------------------------------------------
KIT="$TMP/kit"
mkdir -p "$KIT/scripts" "$KIT/agents" "$KIT/skills"
cp "$HERE/verify-wiring.sh" "$KIT/scripts/verify-wiring.sh"
chmod +x "$KIT/scripts/verify-wiring.sh"
echo "agent" > "$KIT/agents/a.md"
echo "{}" > "$KIT/settings.json"
echo "# global doctrine" > "$KIT/CLAUDE.global.md"

# --- fixture app, fully wired ------------------------------------------------
APP="$TMP/GoodApp"
mkdir -p "$APP/.claude/state"
ln -s "$KIT/skills"  "$APP/.claude/skills"
ln -s "$KIT/agents"  "$APP/.claude/agents"
ln -s "$KIT/scripts" "$APP/.claude/scripts"
ln -s "$KIT/settings.json" "$APP/.claude/settings.json"
ln -s "$KIT/CLAUDE.global.md" "$APP/CLAUDE.global.md"
echo 'export SCHEME="GoodApp"' > "$APP/.claude/.envrc"
printf '@CLAUDE.global.md\n\n# GoodApp\n' > "$APP/CLAUDE.md"

# Resolve the same way verify-wiring.sh resolves $APP_DIR (cd -P), so the
# roster row's path column is byte-identical to what the tool will compare
# against — this is what makes the fixture exercise the REAL schema instead
# of standing in for it.
APP_ABS="$(cd -P "$APP" && pwd)"

# --- fixture ledger (work-repos.md, resolved via WORK_LEDGER_DIR) -----------
# Canonical 4-column roster schema: "| name | abs-path | scheme | status |"
# — the same shape wire-repo.sh writes and list-unledgered-sessions.sh reads.
LEDGER="$TMP/ledger"
mkdir -p "$LEDGER"
cat > "$LEDGER/work-repos.md" <<EOF
| name | path | scheme | status |
|---|---|---|---|
| GoodApp | $APP_ABS | GoodApp | active |
EOF
export WORK_LEDGER_DIR="$LEDGER"

V="$KIT/scripts/verify-wiring.sh"

# 1. fully wired passes
"$V" "$APP" >/dev/null 2>&1 && ok || bad "wired app should pass"

# 2. invoked via the app's .claude/scripts symlink also passes (cd -P resolution)
"$APP/.claude/scripts/verify-wiring.sh" "$APP" >/dev/null 2>&1 \
  && ok || bad "symlinked invocation should pass"

# 3. kit dir itself is skipped silently
OUT="$("$V" "$KIT" 2>&1)"; [ -z "$OUT" ] && ok || bad "kit dir should be silent skip"

# 4. real directory instead of symlink fails
rm "$APP/.claude/agents"; mkdir "$APP/.claude/agents"
"$V" "$APP" >/dev/null 2>&1 && bad "real agents dir should fail" || ok
rm -rf "$APP/.claude/agents"; ln -s "$KIT/agents" "$APP/.claude/agents"

# 5. missing kit import in CLAUDE.md fails
printf '# GoodApp\n' > "$APP/CLAUDE.md"
"$V" "$APP" >/dev/null 2>&1 && bad "missing import should fail" || ok
printf '@CLAUDE.global.md\n\n# GoodApp\n' > "$APP/CLAUDE.md"

# 6. missing SCHEME fails
rm "$APP/.claude/.envrc"
"$V" "$APP" >/dev/null 2>&1 && bad "missing .envrc should fail" || ok
echo 'export SCHEME="GoodApp"' > "$APP/.claude/.envrc"

# 7. missing ledger row fails (ledger present, app just isn't in it)
MV="$TMP/BadApp"; cp -R "$APP" "$MV" 2>/dev/null
rm -rf "$MV/.claude/skills" "$MV/.claude/agents" "$MV/.claude/scripts" "$MV/.claude/settings.json" "$MV/CLAUDE.global.md"
ln -s "$KIT/skills"  "$MV/.claude/skills";  ln -s "$KIT/agents" "$MV/.claude/agents"
ln -s "$KIT/scripts" "$MV/.claude/scripts"; ln -s "$KIT/settings.json" "$MV/.claude/settings.json"
ln -s "$KIT/CLAUDE.global.md" "$MV/CLAUDE.global.md"
"$V" "$MV" >/dev/null 2>&1 && bad "unlisted app should fail" || ok

# 7b. no ledger file at all: the roster check no-ops (nothing to check against
#     yet, so a fully-wired app still passes even though it's listed nowhere)
NO_LEDGER="$TMP/no-such-ledger-dir"
WORK_LEDGER_DIR="$NO_LEDGER" "$V" "$APP" >/dev/null 2>&1 && ok || bad "missing ledger file should no-op (pass)"

# 8. --warn mode: reports all problems, exits 0, on a broken app
rm "$APP/.claude/.envrc"; printf '# GoodApp\n' > "$APP/CLAUDE.md"
OUT="$("$V" --warn "$APP" 2>&1)"; RC=$?
[ "$RC" = "0" ] || bad "--warn must exit 0"
echo "$OUT" | grep -q "SCHEME" && echo "$OUT" | grep -q "CLAUDE.md" \
  && ok || bad "--warn must report both problems (got: $OUT)"

# 9. --warn mode is silent on a clean app
echo 'export SCHEME="GoodApp"' > "$APP/.claude/.envrc"
printf '@CLAUDE.global.md\n\n# GoodApp\n' > "$APP/CLAUDE.md"
OUT="$("$V" --warn "$APP" 2>&1)"
[ -z "$OUT" ] && ok || bad "--warn must be silent when clean (got: $OUT)"

# 10. CLAUDE.global.md missing/broken fails (verbose) and is reported (--warn)
rm "$APP/CLAUDE.global.md"
"$V" "$APP" >/dev/null 2>&1 && bad "missing CLAUDE.global.md should fail" || ok
OUT="$("$V" --warn "$APP" 2>&1)"; RC=$?
[ "$RC" = "0" ] && echo "$OUT" | grep -q "CLAUDE.global.md" \
  && ok || bad "--warn should report missing CLAUDE.global.md and still exit 0 (got: $OUT)"
ln -s "$KIT/CLAUDE.global.md" "$APP/CLAUDE.global.md"

# 11. --warn against a non-existent directory still exits 0 (never breaks
#     the "always exit 0" SessionStart contract, even on a bogus invocation)
OUT="$("$V" --warn "$TMP/no-such-app-dir" 2>&1)"; RC=$?
[ "$RC" = "0" ] || bad "--warn on a missing directory must still exit 0 (got rc=$RC)"

# 12. verbose (non-warn) mode against a non-existent directory still fails loudly
"$V" "$TMP/no-such-app-dir" >/dev/null 2>&1 && bad "verbose mode on a missing directory should fail" || ok

# 13-15. regression: a repo reached through a symlinked path component must
# still verify clean after wire-repo.sh wires it. wire-repo.sh used to record
# the roster path with a logical `cd` (no -P) while verify-wiring.sh always
# resolves $APP_DIR with `cd -P` — on macOS TMPDIR itself sits under
# /var -> /private/var, so the two disagreed for every repo under a plain
# `mktemp -d`, and verify-wiring --warn would report "not on the roster"
# forever for a repo that had just been wired correctly. A manual symlink is
# added on top so the regression doesn't depend on the host's own TMPDIR
# happening to be symlinked.
KITROOT="$(cd -P "$HERE/.." && pwd)"
cp "$KITROOT/wire-repo.sh" "$KIT/wire-repo.sh"
chmod +x "$KIT/wire-repo.sh"
cp "$KITROOT/CLAUDE.app-template.md" "$KIT/CLAUDE.app-template.md"

mkdir -p "$TMP/real-place"
ln -s "$TMP/real-place" "$TMP/symlinked-parent"
SYMAPP="$TMP/symlinked-parent/SymApp"
mkdir -p "$SYMAPP"
LEDGER2="$TMP/ledger-symlink-regression"
WORK_LEDGER_DIR="$LEDGER2" "$KIT/wire-repo.sh" "$SYMAPP" "SymScheme" >/dev/null 2>&1

SYMAPP_PHYSICAL="$(cd -P "$SYMAPP" && pwd)"
grep -q "| $SYMAPP_PHYSICAL |" "$LEDGER2/work-repos.md" 2>/dev/null \
  && ok || bad "wire-repo.sh should record the PHYSICAL path in the roster"

WORK_LEDGER_DIR="$LEDGER2" "$V" "$SYMAPP" >/dev/null 2>&1 \
  && ok || bad "verify-wiring should pass a repo wired through a symlinked path"

OUT="$(WORK_LEDGER_DIR="$LEDGER2" "$V" --warn "$SYMAPP" 2>&1)"
[ -z "$OUT" ] && ok \
  || bad "--warn should be silent for a repo wired through a symlinked path (got: $OUT)"

printf 'test-verify-wiring: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = "0" ]
