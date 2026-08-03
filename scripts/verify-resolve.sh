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
pl_resolve_destination() {
  if [ -n "${VERIFY_DESTINATION:-}" ]; then
    printf '%s\n' "$VERIFY_DESTINATION"
    return 0
  fi
  if [ "$(pl_detect_platform)" = "macos" ]; then
    echo "platform=macOS"
    return 0
  fi
  name="${VERIFY_SIM_NAME:-iPhone 17 Pro}"
  udid="$(xcrun simctl list -j devices available 2>/dev/null \
    | jq -r --arg n "$name" '
        .devices | to_entries
        | map(select(.key | test("SimRuntime\\.iOS-")))
        | map(.v = ((.key | try (capture("iOS-(?<a>[0-9]+)-(?<b>[0-9]+)")
                                 | [(.a | tonumber), (.b | tonumber)])) // [0, 0]))
        | sort_by(.v) | reverse
        | .[].value[]?
        | select(.name == $n)
        | .udid
      ' 2>/dev/null | head -n 1)"
  if [ -n "$udid" ]; then
    printf 'platform=iOS Simulator,id=%s\n' "$udid"
  else
    # No such simulator on this machine — fall back to the by-name form so the
    # xcodebuild error names the missing device instead of us failing silently.
    printf 'platform=iOS Simulator,name=%s\n' "$name"
  fi
}
