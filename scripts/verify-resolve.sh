#!/bin/bash
# verify-resolve.sh — sourced by verify-build.sh / verify-test.sh (bash 3.2 /
# BSD safe). Resolves WHERE xcodebuild should look (workspace/project) and
# WHAT to build for (a concrete destination), so the hooks stop assuming an
# iOS app with a root-level project and an unambiguously-named simulator —
# each of those assumptions broke a real repo in practice.
#
# Keep it cheap: verify-build.sh runs from a PostToolUse hook on every Swift
# edit. Everything here is find/grep/simctl — no xcodebuild calls.
#
# Env overrides (all optional):
#   VERIFY_DESTINATION  full xcodebuild -destination string, used verbatim
#   VERIFY_PLATFORM     ios | macos — skips the SDKROOT heuristic
#   VERIFY_SIM_NAME     simulator name to resolve (default: iPhone 17 Pro)
#   VERIFY_RUNTIME      pin an iOS runtime (e.g. 27.0, or 26 for the newest 26.x)
#   VERIFY_WORKSPACE    explicit .xcworkspace path (highest container priority)

# --- Container: which workspace/project should xcodebuild open? -------------
# Sets PL_CONTAINER_FLAG (-workspace | -project | "") and PL_CONTAINER_PATH.
# Only a SINGLE unambiguous candidate is passed; with zero or several we leave
# the flag empty and let xcodebuild's own cwd discovery decide (old behaviour)
# rather than guess wrong silently. Standalone workspaces win over projects
# because a workspace embeds its projects.
pl_resolve_container() {
  PL_CONTAINER_FLAG=""
  PL_CONTAINER_PATH=""
  if [ -n "${VERIFY_WORKSPACE:-}" ]; then
    PL_CONTAINER_FLAG="-workspace"
    PL_CONTAINER_PATH="$VERIFY_WORKSPACE"
    return 0
  fi
  # Exclude the project.xcworkspace embedded in every .xcodeproj, and hidden
  # dirs (.swiftpm etc.). maxdepth 2 covers the nested-app layout that broke
  # DevBar without trawling the whole tree.
  found="$(find . -maxdepth 2 -name '*.xcworkspace' \
             -not -path '*.xcodeproj/*' -not -path '*/.*' 2>/dev/null)"
  if [ "$(printf '%s\n' "$found" | grep -c .)" -eq 1 ]; then
    PL_CONTAINER_FLAG="-workspace"; PL_CONTAINER_PATH="$found"; return 0
  fi
  found="$(find . -maxdepth 2 -name '*.xcodeproj' -not -path '*/.*' 2>/dev/null)"
  if [ "$(printf '%s\n' "$found" | grep -c .)" -eq 1 ]; then
    PL_CONTAINER_FLAG="-project"; PL_CONTAINER_PATH="$found"; return 0
  fi
  return 0
}

# --- Platform: is this a macOS-only project? ---------------------------------
# Cheap heuristic, no xcodebuild: if every SDKROOT declared in the pbxproj(s)
# is macosx, an iOS Simulator destination can never work (macOS-only apps).
# Mixed or absent SDKROOTs → ios, the default — multiplatform apps keep
# building their iOS side. VERIFY_PLATFORM overrides for the scheme-level
# cases a project-level heuristic can't see.
pl_detect_platform() {
  case "${VERIFY_PLATFORM:-}" in
    macos|macOS) echo macos; return 0 ;;
    ios|iOS)     echo ios;   return 0 ;;
  esac
  sdkroots="$(find . -maxdepth 3 -name project.pbxproj -path '*.xcodeproj/*' \
                -not -path '*/.*' -print0 2>/dev/null \
              | xargs -0 grep -h 'SDKROOT = ' /dev/null 2>/dev/null \
              | sed 's/.*SDKROOT = \([A-Za-z]*\).*/\1/' | sort -u)"
  if [ -n "$sdkroots" ] && [ "$sdkroots" = "macosx" ]; then
    echo macos
  else
    echo ios
  fi
}

# --- Destination -------------------------------------------------------------
# Prints the -destination string. By-name simulator destinations resolve
# ambiguously on machines with duplicate device names across runtimes (and
# hard-error on uninstalled placeholder runtimes), so resolve the name to the
# UDID of the matching device on the NEWEST installed iOS runtime instead.
#
# "Newest installed" and "newest that has this device" are different things, and
# they diverge in silence: a freshly installed runtime can arrive with NO
# devices created on it, and the search then falls through to an older runtime
# that has one. The resolver sets PL_DEST_NOTE when that happens, and the
# verify scripts print it.
# Sets PL_DESTINATION and PL_DEST_NOTE, and prints the destination. Call it
# WITHOUT a subshell (`pl_resolve_destination >/dev/null`) if you want the note:
# `$(...)` runs in a subshell and the note dies with it.
pl_resolve_destination() {
  PL_DEST_NOTE=""
  PL_DESTINATION=""
  if [ -n "${VERIFY_DESTINATION:-}" ]; then
    PL_DESTINATION="$VERIFY_DESTINATION"
    printf '%s\n' "$PL_DESTINATION"
    return 0
  fi
  if [ "$(pl_detect_platform)" = "macos" ]; then
    PL_DESTINATION="platform=macOS"
    echo "$PL_DESTINATION"
    return 0
  fi
  name="${VERIFY_SIM_NAME:-iPhone 17 Pro}"
  want="${VERIFY_RUNTIME:-}"
  devs="$(xcrun simctl list -j devices available 2>/dev/null)"

  # Every installed iOS runtime, NEWEST FIRST, as "27.0 <key>" lines. The
  # ordering is jq's, not sort's: BSD `sort -t. -k1,1n -r` silently ignores the
  # reverse on these lines and hands back ascending order, which is a fallback
  # to the OLDEST runtime that looks exactly like a working resolve. The
  # fixture test caught it; nothing else would have.
  runtimes="$(printf '%s' "$devs" | jq -r '
      .devices | keys
      | map(select(test("SimRuntime\\.iOS-")))
      | map({k: ., v: ((capture("iOS-(?<a>[0-9]+)-(?<b>[0-9]+)")
                        | [(.a | tonumber), (.b | tonumber)]) // [0, 0])})
      | sort_by(.v) | reverse | .[] | "\(.v[0]).\(.v[1]) \(.k)"
    ' 2>/dev/null)"
  newest="$(printf '%s' "$runtimes" | head -n 1 | cut -d' ' -f1)"

  # Walk them newest first and take the first that has a device of this name.
  # A VERIFY_RUNTIME pin ("27.0", or "26" for the newest 26.x) filters first.
  # `while read` rather than `for row in $runtimes`: zsh does not word-split an
  # unquoted variable on IFS, so the for-loop form runs ONCE with every line
  # glued together, the lookup misses, and the resolver falls back to the
  # by-name destination — silently, and only when this file is sourced into a
  # zsh shell rather than run by the bash-shebanged verify scripts. A here-doc
  # feeds the loop without a pipe, so `break` still leaves the function.
  chosen=""; udid=""
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    ver="${row%% *}"; key="${row#* }"
    if [ -n "$want" ]; then
      case "$ver" in "$want"|"$want".*) ;; *) continue ;; esac
    fi
    udid="$(printf '%s' "$devs" | jq -r --arg k "$key" --arg n "$name" \
              '.devices[$k][]? | select(.name == $n) | .udid' 2>/dev/null | head -n 1)"
    if [ -n "$udid" ]; then chosen="$ver"; break; fi
  done <<RUNTIMES
$runtimes
RUNTIMES

  if [ -n "$udid" ]; then
    if [ -z "$want" ] && [ -n "$newest" ] && [ "$chosen" != "$newest" ]; then
      PL_DEST_NOTE="iOS ${newest} is installed but has no \"${name}\" — building on ${chosen}. Create one (xcrun simctl create \"${name}\" <devicetype> <runtime>) or pin with VERIFY_RUNTIME."
    fi
    PL_DESTINATION="platform=iOS Simulator,id=$udid"
    printf '%s\n' "$PL_DESTINATION"
  else
    # No such simulator on this machine — fall back to the by-name form so the
    # xcodebuild error names the missing device instead of us failing silently.
    [ -n "$want" ] && PL_DEST_NOTE="No \"${name}\" on an iOS ${want} runtime."
    PL_DESTINATION="platform=iOS Simulator,name=$name"
    printf '%s\n' "$PL_DESTINATION"
  fi
}
