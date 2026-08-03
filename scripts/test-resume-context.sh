#!/bin/bash
# Tests the clear-source marker gating in resume-context.sh.
# bash 3.2 / BSD-safe. Run: bash scripts/test-resume-context.sh
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/resume-context.sh"
fail=0

setup() {
  work="$(mktemp -d)"
  mkdir -p "$work/.claude/state"
  printf '# RESUME\nsingle next action: ship it\n' > "$work/.claude/state/RESUME.md"
}
teardown() { rm -rf "$work"; }
run() { printf '{"source":"%s","cwd":"%s"}' "$1" "$work" | bash "$hook"; }

# 1. clear + NO marker -> silent (empty stdout)
setup
out="$(run clear)"
if [ -n "$out" ]; then echo "FAIL: clear without marker should be silent, got: $out"; fail=1; else echo "PASS: clear without marker is silent"; fi
teardown

# 2. clear + marker -> injects AND consumes marker
setup
touch "$work/.claude/state/.handoff-active"
out="$(run clear)"
if printf '%s' "$out" | grep -q "Resume notes"; then echo "PASS: clear with marker injects"; else echo "FAIL: clear with marker should inject, got: $out"; fail=1; fi
if [ -f "$work/.claude/state/.handoff-active" ]; then echo "FAIL: marker should be consumed"; fail=1; else echo "PASS: marker consumed"; fi
teardown

# 3. non-clear source (startup) -> injects regardless of marker
setup
out="$(run startup)"
if printf '%s' "$out" | grep -q "Resume notes"; then echo "PASS: startup injects"; else echo "FAIL: startup should inject, got: $out"; fail=1; fi
teardown

exit $fail
