#!/usr/bin/env bash
set -euo pipefail
repo="${1:?repo}"; since="${2:?since}"; until="${3:?until}"
[ -d "$repo/.git" ] || { echo "(no git repo at $repo)" >&2; exit 0; }
me="$(git -C "$repo" config user.email 2>/dev/null || echo '')"
[ -n "$me" ] || { echo "(git user.email unset in $repo — skipping)" >&2; exit 0; }
git -C "$repo" log --author="$me" --since="$since" --until="$until 23:59:59" \
  --pretty='%h %s' 2>/dev/null || true
