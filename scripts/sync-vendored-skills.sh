#!/bin/bash
# Vendor third-party agent skills into skills/ from pinned upstream commits.
#
#   scripts/sync-vendored-skills.sh            # materialise every skill at its pinned SHA
#   scripts/sync-vendored-skills.sh --check    # report which upstreams moved past their pin
#   scripts/sync-vendored-skills.sh --help
#
# Model: vendored + pinned + reviewed (never live auto-update). The manifest
# (skills/vendored.manifest) is the single source of truth: dest dir, repo,
# pinned commit, subpath, license, audit date. `sync` reproduces exactly what
# the manifest pins — idempotent, safe after a `git pull`. `--check` only
# REPORTS upstream drift (commits + a non-.md/script re-audit flag) so a human
# reviews the diff, bumps the SHA in the manifest, re-runs `sync`, and commits.
# Nothing is fetched into a live session and no pin advances on its own.
#
# Vendored skills are kept PRISTINE (no hand edits) so update diffs stay clean;
# a sync rewrites each dest from scratch, dropping files removed upstream.
# bash 3.2 / BSD-safe (macOS stock): no associative arrays, no GNU-only flags.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$KIT_DIR/skills/vendored.manifest"
MODE="sync"

case "${1:-}" in
  --check) MODE="check" ;;
  --help|-h)
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1 (use --check or --help)"; exit 2 ;;
esac

[ -f "$MANIFEST" ] || { echo "No manifest at $MANIFEST"; exit 1; }

# A tmp area for clones; cleaned on exit.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/vendored-skills.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

short() { printf '%s' "${1:0:9}"; }

# Files we never expect in a pure-markdown skill — surfacing them on --check is
# the re-audit trigger (something executable appeared upstream since the pin).
flag_executables() { # <dir>
  find "$1" -not -path '*/.git/*' -type f \
    \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.rb' \
       -o -name '*.command' -o -name '*.pl' -o -perm -u+x \) 2>/dev/null \
    | sed "s#^$1/##" || true
}

changed=0
errors=0

# Manifest columns: dest | repo_url | pin_sha | subpath | license | audited
while IFS='|' read -r dest repo pin subpath license audited; do
  case "$dest" in ''|\#*) continue ;; esac          # skip blanks/comments
  dest="$(printf '%s' "$dest" | tr -d ' ')"
  repo="$(printf '%s' "$repo" | tr -d ' ')"
  pin="$(printf '%s' "$pin" | tr -d ' ')"
  subpath="$(printf '%s' "$subpath" | tr -d ' ')"
  license="$(printf '%s' "$license" | sed 's/^ *//;s/ *$//')"
  audited="$(printf '%s' "$audited" | tr -d ' ')"

  clone="$WORK/$dest"
  if ! git clone -q --filter=blob:none "$repo" "$clone" 2>/dev/null; then
    echo "  ✗ $dest: clone failed ($repo)"; errors=$((errors+1)); continue
  fi

  if [ "$MODE" = "check" ]; then
    head_sha="$(git -C "$clone" rev-parse HEAD)"
    if [ "$(short "$head_sha")" = "$(short "$pin")" ] || git -C "$clone" merge-base --is-ancestor "$head_sha" "$pin" 2>/dev/null; then
      echo "  ✓ $dest: up to date (pinned $(short "$pin"))"
    else
      changed=$((changed+1))
      echo "  ⬆ $dest: upstream moved $(short "$pin") → $(short "$head_sha")"
      git -C "$clone" --no-pager log --oneline "$pin..$head_sha" -- "$subpath" 2>/dev/null \
        | sed 's/^/      /' | head -20 || true
      git -C "$clone" checkout -q "$head_sha" 2>/dev/null || true
      execs="$(flag_executables "$clone/$subpath")"
      [ -n "$execs" ] && { echo "      ⚠ NEW NON-MARKDOWN/EXECUTABLE FILES — re-audit before bumping:"; printf '%s\n' "$execs" | sed 's/^/        /'; }
    fi
    continue
  fi

  # --- sync: materialise the pinned version ---
  if ! git -C "$clone" checkout -q "$pin" 2>/dev/null; then
    echo "  ✗ $dest: pin $pin not found"; errors=$((errors+1)); continue
  fi
  src="$clone/$subpath"
  [ -f "$src/SKILL.md" ] || { echo "  ✗ $dest: no SKILL.md at subpath '$subpath'"; errors=$((errors+1)); continue; }

  out="$KIT_DIR/skills/$dest"
  rm -rf "$out"; mkdir -p "$out"
  # Copy only markdown + references/; -L resolves any symlinks to real files.
  for f in "$src"/*.md; do [ -e "$f" ] && cp -L "$f" "$out/"; done
  [ -d "$src/references" ] && cp -RL "$src/references" "$out/references"
  # Preserve the upstream LICENSE for attribution (MIT etc. require it).
  if [ -f "$src/LICENSE" ]; then cp -L "$src/LICENSE" "$out/LICENSE"
  elif [ -f "$clone/LICENSE" ]; then cp -L "$clone/LICENSE" "$out/LICENSE"; fi

  cat > "$out/UPSTREAM" <<EOF
# Vendored third-party skill — DO NOT EDIT.
# Managed by scripts/sync-vendored-skills.sh from skills/vendored.manifest.
# Local edits are overwritten on the next sync. To change it: edit upstream,
# or bump the pin in the manifest (after reviewing the diff and re-auditing).
upstream: $repo
subpath:  $subpath
pinned:   $pin
license:  $license
audited:  $audited
EOF
  echo "  ✓ $dest @ $(short "$pin")  ($license)"
done < "$MANIFEST"

echo
if [ "$MODE" = "check" ]; then
  if [ "$changed" -eq 0 ]; then echo "All vendored skills are at their pinned upstream. Nothing to review."
  else echo "$changed skill(s) have upstream changes. Review the log above, bump the SHA in"
       echo "skills/vendored.manifest, run this script without --check, then commit."; fi
else
  echo "Vendored skills materialised. Skills reach a repo via the wire-repo.sh symlink"
  echo "(.claude/skills -> skills/), so any wired repo picks this up automatically —"
  echo "no separate sync step needed."
fi
[ "$errors" -eq 0 ] || { echo "($errors error(s) above)"; exit 1; }
