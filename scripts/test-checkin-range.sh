#!/usr/bin/env bash
# test-checkin-range.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# ytd for 2026-07-07 => since = 2026-01-01 00:00
read -r s u label < <("$DIR/checkin-range.sh" ytd 2026-07-07)
sy="$(date -j -f '%Y-%m-%d %H:%M:%S' '2026-01-01 00:00:00' +%s)"
[ "$s" = "$sy" ] || { echo "FAIL ytd since: $s != $sy"; exit 1; }
[ "$label" = "ytd" ] || { echo "FAIL label"; exit 1; }
# mid-year (H1) => 2026-01-01 .. 2026-06-30
read -r s2 u2 l2 < <("$DIR/checkin-range.sh" mid-year 2026-07-07)
[ "$s2" = "$sy" ] || { echo "FAIL h1 since"; exit 1; }
echo "PASS"
