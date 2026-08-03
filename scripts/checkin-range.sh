#!/usr/bin/env bash
# Echo "<since-epoch> <until-epoch> <label>" for a check-in period.
set -euo pipefail
period="${1:?period}"; today="${2:?today YYYY-MM-DD}"; last="${3:-}"
e() { date -j -f '%Y-%m-%d %H:%M:%S' "$1 $2" +%s; }   # date, time -> epoch
year="${today%%-*}"
now="$(e "$today" '23:59:59')"
case "$period" in
  standup)     since="$(date -v-1d -j -f '%Y-%m-%d %H:%M:%S' "$today 00:00:00" +%s)"; until="$now"; label=standup;;
  ytd)         since="$(e "$year-01-01" '00:00:00')"; until="$now"; label=ytd;;
  mid-year)    since="$(e "$year-01-01" '00:00:00')"; until="$(e "$year-06-30" '23:59:59')"; label=mid-year;;
  full-year)   since="$(e "$year-01-01" '00:00:00')"; until="$(e "$year-12-31" '23:59:59')"; label=full-year;;
  since-last)  since="$(e "${last:-$year-01-01}" '00:00:00')"; until="$now"; label=since-last;;
  *:*)         since="$(e "${period%%:*}" '00:00:00')"; until="$(e "${period##*:}" '23:59:59')"; label="$period";;
  *) echo "unknown period: $period" >&2; exit 1;;
esac
printf '%s %s %s\n' "$since" "$until" "$label"
