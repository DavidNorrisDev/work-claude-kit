#!/usr/bin/env bash
# work-claude-kit — ledger installer (user-level, additive, non-destructive).
#
# Installs ONLY the work-ledger + /check-in tooling into ~/.claude, so it works
# in every repo WITHOUT touching any repo's own .claude/. No auth gate, no
# sudo. It never overwrites a user file that isn't ours, and records exactly
# what it linked so ./uninstall.sh can reverse it cleanly. Your ledger data
# (~/work-ledger) is created here and is NEVER removed by uninstall.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEDGER_DIR="${WORK_LEDGER_DIR:-$HOME/work-ledger}"
UC="$HOME/.claude"
STAMP="$UC/.work-claude-kit"   # manifest of what we linked, for uninstall

mkdir -p "$UC/skills" "$UC/scripts"
chmod +x "$KIT_DIR/scripts/"*.sh "$KIT_DIR"/*.sh 2>/dev/null || true

added=0; skipped=0
: > "$STAMP.tmp"
link_item() {  # <source-abs> <dest>
  src="$1"; dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "$dest" >> "$STAMP.tmp"; return 0            # already ours
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "install: $(basename "$dest") exists at user level and is not ours — skipped."
    skipped=$((skipped+1)); return 0
  fi
  ln -s "$src" "$dest"; echo "$dest" >> "$STAMP.tmp"; added=$((added+1))
}

# The two ledger skills + the scripts they call.
for s in check-in ledger-backfill; do
  [ -d "$KIT_DIR/skills/$s" ] && link_item "$KIT_DIR/skills/$s" "$UC/skills/$s"
done
for f in ledger-env.sh list-unledgered-sessions.sh checkin-range.sh \
         evidence-git.sh evidence-github.sh evidence-jira.sh ledger-health.sh; do
  [ -f "$KIT_DIR/scripts/$f" ] && link_item "$KIT_DIR/scripts/$f" "$UC/scripts/$f"
done
mv "$STAMP.tmp" "$STAMP"

# Ledger store — scaffold, then git-init for local history + a backup target.
mkdir -p "$LEDGER_DIR/reviews"
[ -f "$LEDGER_DIR/work-ledger.md" ] || cp "$KIT_DIR/templates/work-ledger.seed.md" "$LEDGER_DIR/work-ledger.md"
[ -f "$LEDGER_DIR/work-repos.md" ] || printf '# Work repos the ledger sweeps — one row per repo under the header.\n# | name | /absolute/repo/path | scheme | status |\n' > "$LEDGER_DIR/work-repos.md"
if [ ! -d "$LEDGER_DIR/.git" ] && command -v git >/dev/null 2>&1; then
  ( cd "$LEDGER_DIR" \
      && git init -q \
      && printf '# machine-local scratch\n.DS_Store\n' > .gitignore \
      && git add -A \
      && git -c user.email=ledger@local -c user.name="work-ledger" commit -q -m "Initialise work-ledger" ) \
    && echo "install: git-initialised $LEDGER_DIR for history + off-machine backup."
fi

echo "install: done. Linked $added item(s) at user level ($skipped skipped)."
echo "install: ledger at $LEDGER_DIR. Check it anytime with ~/.claude/scripts/ledger-health.sh."
echo "install: reverse with ./uninstall.sh (your ledger data is kept)."
