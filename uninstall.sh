#!/usr/bin/env bash
# Reverse ./install.sh. Removes ONLY the ~/.claude symlinks this kit created
# (recorded in ~/.claude/.work-claude-kit), never a file that isn't ours.
# Also restores a global CLAUDE.md that an OLDER install.sh may have backed
# up. Your ledger data (~/work-ledger) is PRESERVED — deleting it is a
# separate, explicit choice.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
UC="$HOME/.claude"
STAMP="$UC/.work-claude-kit"
LEDGER_DIR="${WORK_LEDGER_DIR:-$HOME/work-ledger}"
removed=0

if [ -f "$STAMP" ]; then
  # Preferred path: remove exactly what we recorded linking.
  while IFS= read -r dest; do
    [ -n "$dest" ] || continue
    if [ -L "$dest" ]; then rm -f "$dest"; removed=$((removed+1)); fi
  done < "$STAMP"
  rm -f "$STAMP"
else
  # Fallback for installs from before the manifest existed: remove any
  # ~/.claude symlink that points into this kit checkout.
  for d in "$UC"/skills/* "$UC"/agents/* "$UC"/scripts/*; do
    [ -L "$d" ] || continue
    case "$(readlink "$d" 2>/dev/null)" in
      "$KIT_DIR"/*) rm -f "$d"; removed=$((removed+1));;
    esac
  done
fi

# Restore a pre-work-kit global if a previous install.sh repointed one.
GC="$UC/CLAUDE.md"
if [ -L "$GC" ] && [ "$(readlink "$GC" 2>/dev/null)" = "$KIT_DIR/CLAUDE.global.md" ]; then
  if [ -e "$GC.pre-work-kit" ] || [ -L "$GC.pre-work-kit" ]; then
    rm -f "$GC"; mv "$GC.pre-work-kit" "$GC"
    echo "uninstall: restored your previous ~/.claude/CLAUDE.md"
  else
    rm -f "$GC"
    echo "uninstall: removed the kit's ~/.claude/CLAUDE.md link (no prior global to restore)"
  fi
fi

echo "uninstall: removed $removed kit link(s) from ~/.claude."
echo "uninstall: your ledger at $LEDGER_DIR is PRESERVED. To remove it too (this deletes your work record): rm -rf \"$LEDGER_DIR\""
