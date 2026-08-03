#!/bin/bash
# statusLine: ambient usage-limit awareness, calm B&W styling.
# Reads the Claude Code statusline JSON on stdin. Costs zero model tokens —
# runs out-of-band, output never enters the model context.
# bash 3.2 / BSD-safe. jq is a kit dependency (/usr/bin/jq).
#
# Hardened for cost: the JSON is parsed in ONE jq call, and the git
# branch/dirty lookup is cached for ~3s per repo so rapid statusline refreshes
# never re-spawn `git status` (which walks the whole working tree) on a large
# repo, no matter how often the bar refreshes or how many sessions are open.
#
# Segments: <dir> · <branch> [✎dirty] · ctx N% · 5h N% · 7d N%
#   ctx N%      — context window used (⚠ when ≥85%, autocompact looms)
#   5h / 7d N%  — usage credits consumed; ⚠ + reset time when a window
#                 climbs to ≥85% used. Both rate-limit segments are
#                 subscriber-only and absent otherwise.
set -uo pipefail

IN="$(cat)"

# Single jq pass → fields joined by the unit separator (\037). We use a
# NON-whitespace separator on purpose: `read` collapses consecutive whitespace
# (incl. tabs), which would drop empty fields and misalign everything when a
# field like .cwd is absent. \037 preserves empty fields positionally.
IFS=$'\037' read -r dir cwd ctx five fresets seven sresets <<EOF
$(jq -r '[.workspace.current_dir // "", .cwd // "", .context_window.used_percentage // "", .rate_limits.five_hour.used_percentage // "", .rate_limits.five_hour.resets_at // "", .rate_limits.seven_day.used_percentage // "", .rate_limits.seven_day.resets_at // ""] | map(tostring) | join("\u001f")' <<<"$IN" 2>/dev/null)
EOF

[ -z "$dir" ] && dir="$cwd"
[ -z "$dir" ] && dir="$PWD"

# Cache the git lookup for ~3s per repo. `git status` walking the working tree
# is the only expensive call here; caching bounds it to at most once per 3s.
safe="$(printf '%s' "$dir" | tr -c 'A-Za-z0-9' '_')"
cache="${TMPDIR:-/tmp}/pl-statusline-$safe"
now="$(date +%s 2>/dev/null || echo 0)"
gitline=""
if [ -f "$cache" ]; then
  mtime="$(stat -f %m "$cache" 2>/dev/null || echo 0)"
  [ "$((now - mtime))" -lt 3 ] 2>/dev/null && gitline="$(cat "$cache" 2>/dev/null)"
fi
if [ -z "$gitline" ]; then
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null | grep -c . || true)"
  gitline="$(printf '%s\037%s' "$branch" "$dirty")"
  # Atomic write so concurrent sessions never read a half-written cache.
  printf '%s' "$gitline" > "$cache.$$" 2>/dev/null && mv -f "$cache.$$" "$cache" 2>/dev/null || rm -f "$cache.$$" 2>/dev/null
fi
IFS=$'\037' read -r branch dirty <<EOF
$gitline
EOF

seg="$(basename "$dir") · ${branch:--}"
[ "${dirty:-0}" -gt 0 ] 2>/dev/null && seg="$seg ✎$dirty"

# Context window used. ⚠ once we're near the autocompact ceiling.
if [ -n "$ctx" ]; then
  cp="${ctx%.*}"; case "$cp" in ''|*[!0-9]*) cp=0;; esac
  if [ "$cp" -ge 85 ] 2>/dev/null; then
    seg="$seg · ⚠ ctx ${cp}%"
  else
    seg="$seg · ctx ${cp}%"
  fi
fi

# Usage credits consumed. ⚠ + reset time when a window runs low (≥85% used).
if [ -n "$five" ]; then
  fp="${five%.*}"; case "$fp" in ''|*[!0-9]*) fp=0;; esac
  if [ "$fp" -ge 85 ] 2>/dev/null; then
    when=""
    [ -n "$fresets" ] && when=" · resets $(date -r "${fresets%.*}" +%H:%M 2>/dev/null || echo '?')"
    seg="$seg · ⚠ 5h ${fp}%${when}"
  else
    seg="$seg · 5h ${fp}%"
  fi
fi

if [ -n "$seven" ]; then
  sp="${seven%.*}"; case "$sp" in ''|*[!0-9]*) sp=0;; esac
  if [ "$sp" -ge 85 ] 2>/dev/null; then
    when=""
    [ -n "$sresets" ] && when=" · resets $(date -r "${sresets%.*}" +%H:%M 2>/dev/null || echo '?')"
    seg="$seg · ⚠ 7d ${sp}%${when}"
  else
    seg="$seg · 7d ${sp}%"
  fi
fi

printf '%s' "$seg"
