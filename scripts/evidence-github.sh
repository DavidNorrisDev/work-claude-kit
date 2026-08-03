#!/usr/bin/env bash
set -euo pipefail
repo="${1:?repo}"; since="${2:?since}"; until="${3:?until}"
command -v gh >/dev/null 2>&1 || { echo "(gh not installed — skipping PR/issue evidence)" >&2; exit 0; }
( cd "$repo" 2>/dev/null ) || { echo "(no repo)" >&2; exit 0; }
echo "### merged PRs"
gh -R "$(cd "$repo" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" \
  pr list --author @me --state merged --search "merged:$since..$until" \
  --json number,title -q '.[] | "PR #\(.number) \(.title)"' 2>/dev/null || echo "(none / unavailable)"
echo "### closed issues"
gh -R "$(cd "$repo" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" \
  issue list --assignee @me --state closed --search "closed:$since..$until" \
  --json number,title -q '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(none / unavailable)"
