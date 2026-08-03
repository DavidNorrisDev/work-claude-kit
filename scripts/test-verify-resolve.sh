#!/bin/bash
# test-verify-resolve.sh — fixture test for verify-resolve.sh (bash 3.2 / BSD safe)
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); }
bad()  { FAIL=$((FAIL+1)); printf 'test FAIL: %s\n' "$1"; }

# --- stub xcrun: canned simctl JSON ------------------------------------------
# Duplicate "iPhone 17 Pro" across two iOS runtimes (the real-world ambiguity)
# plus a visionOS runtime that must be ignored.
STUB="$TMP/stub-bin"
mkdir -p "$STUB"
cat > "$STUB/simctl.json" <<'EOF'
{"devices":{
  "com.apple.CoreSimulator.SimRuntime.iOS-18-4":[
    {"name":"iPhone 17 Pro","udid":"OLD-RUNTIME-UDID","isAvailable":true}],
  "com.apple.CoreSimulator.SimRuntime.iOS-26-0":[
    {"name":"iPhone 17 Pro","udid":"NEW-RUNTIME-UDID","isAvailable":true},
    {"name":"iPhone Air","udid":"AIR-UDID","isAvailable":true}],
  "com.apple.CoreSimulator.SimRuntime.xrOS-26-0":[
    {"name":"Apple Vision Pro","udid":"VISION-UDID","isAvailable":true}]
}}
EOF
cat > "$STUB/xcrun" <<EOF
#!/bin/bash
cat "$STUB/simctl.json"
EOF
chmod +x "$STUB/xcrun"
PATH="$STUB:$PATH"

. "$HERE/verify-resolve.sh"

# --- fixture repos (space in the name, per the hook-path lesson) ------------
mk_ios_app() {  # root-level iOS project
  d="$TMP/$1"; mkdir -p "$d/App.xcodeproj"
  printf 'SDKROOT = iphoneos;\n' > "$d/App.xcodeproj/project.pbxproj"
  echo "$d"
}

IOS_APP="$(mk_ios_app "Good App")"

MAC_APP="$TMP/Mac App"; mkdir -p "$MAC_APP/MacOnly.xcodeproj"
printf 'SDKROOT = macosx;\nSDKROOT = macosx;\n' > "$MAC_APP/MacOnly.xcodeproj/project.pbxproj"

NESTED_APP="$TMP/Nested App"; mkdir -p "$NESTED_APP/Sources/DevBar.xcodeproj"
printf 'SDKROOT = iphoneos;\n' > "$NESTED_APP/Sources/DevBar.xcodeproj/project.pbxproj"

# 1. VERIFY_DESTINATION wins verbatim
cd "$IOS_APP"
GOT="$(VERIFY_DESTINATION='platform=iOS Simulator,name=iPhone Air,OS=26.5' pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,name=iPhone Air,OS=26.5' ] && ok || bad "VERIFY_DESTINATION should pass through verbatim (got: $GOT)"

# 2. iOS app: duplicate sim name resolves to the NEWEST runtime's UDID
GOT="$(pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,id=NEW-RUNTIME-UDID' ] && ok || bad "duplicate name should resolve to newest iOS runtime UDID (got: $GOT)"

# 3. VERIFY_SIM_NAME is honoured
GOT="$(VERIFY_SIM_NAME='iPhone Air' pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,id=AIR-UDID' ] && ok || bad "VERIFY_SIM_NAME should resolve (got: $GOT)"

# 4. unknown sim name falls back to the by-name form
GOT="$(VERIFY_SIM_NAME='iPhone 99' pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,name=iPhone 99' ] && ok || bad "unknown sim should fall back to name= (got: $GOT)"

# 5. macOS-only project detected from SDKROOT
cd "$MAC_APP"
GOT="$(pl_resolve_destination)"
[ "$GOT" = 'platform=macOS' ] && ok || bad "macosx-only SDKROOT should give platform=macOS (got: $GOT)"

# 6. VERIFY_PLATFORM overrides the heuristic both ways
GOT="$(VERIFY_PLATFORM=ios pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,id=NEW-RUNTIME-UDID' ] && ok || bad "VERIFY_PLATFORM=ios should force simulator (got: $GOT)"
cd "$IOS_APP"
GOT="$(VERIFY_PLATFORM=macos pl_resolve_destination)"
[ "$GOT" = 'platform=macOS' ] && ok || bad "VERIFY_PLATFORM=macos should force macOS (got: $GOT)"

# 7. container: single root project passed explicitly
cd "$IOS_APP"
pl_resolve_container
[ "$PL_CONTAINER_FLAG" = "-project" ] && [ "$PL_CONTAINER_PATH" = "./App.xcodeproj" ] \
  && ok || bad "root project should resolve to -project (got: $PL_CONTAINER_FLAG $PL_CONTAINER_PATH)"

# 8. container: project one level down is found (the DevBar layout)
cd "$NESTED_APP"
pl_resolve_container
[ "$PL_CONTAINER_FLAG" = "-project" ] && [ "$PL_CONTAINER_PATH" = "./Sources/DevBar.xcodeproj" ] \
  && ok || bad "nested project should resolve (got: $PL_CONTAINER_FLAG $PL_CONTAINER_PATH)"

# 9. container: a standalone workspace wins over the project…
WS_APP="$TMP/WS App"; mkdir -p "$WS_APP/App.xcodeproj/project.xcworkspace" "$WS_APP/App.xcworkspace"
printf 'SDKROOT = iphoneos;\n' > "$WS_APP/App.xcodeproj/project.pbxproj"
cd "$WS_APP"
pl_resolve_container
[ "$PL_CONTAINER_FLAG" = "-workspace" ] && [ "$PL_CONTAINER_PATH" = "./App.xcworkspace" ] \
  && ok || bad "standalone workspace should win (got: $PL_CONTAINER_FLAG $PL_CONTAINER_PATH)"

# 10. …but the project.xcworkspace inside .xcodeproj alone does NOT count
cd "$IOS_APP"
mkdir -p App.xcodeproj/project.xcworkspace
pl_resolve_container
[ "$PL_CONTAINER_FLAG" = "-project" ] && ok || bad "embedded project.xcworkspace must be ignored (got: $PL_CONTAINER_FLAG)"

# 11. container: two projects → ambiguous → no explicit args (old behaviour)
AMB_APP="$TMP/Ambiguous App"; mkdir -p "$AMB_APP/A.xcodeproj" "$AMB_APP/B.xcodeproj"
cd "$AMB_APP"
pl_resolve_container
[ -z "$PL_CONTAINER_FLAG" ] && ok || bad "ambiguous projects should fall back (got: $PL_CONTAINER_FLAG)"

# 12. VERIFY_WORKSPACE beats discovery
cd "$IOS_APP"
VERIFY_WORKSPACE="Custom.xcworkspace" pl_resolve_container_out="$(VERIFY_WORKSPACE="Custom.xcworkspace" bash -c '. "'"$HERE"'/verify-resolve.sh"; pl_resolve_container; printf "%s|%s" "$PL_CONTAINER_FLAG" "$PL_CONTAINER_PATH"')"
[ "$pl_resolve_container_out" = "-workspace|Custom.xcworkspace" ] \
  && ok || bad "VERIFY_WORKSPACE should win (got: $pl_resolve_container_out)"

# 13. no pbxproj at all → defaults to ios (simulator destination)
EMPTY_APP="$TMP/Empty App"; mkdir -p "$EMPTY_APP"
cd "$EMPTY_APP"
GOT="$(pl_resolve_destination)"
[ "$GOT" = 'platform=iOS Simulator,id=NEW-RUNTIME-UDID' ] && ok || bad "no pbxproj should default to iOS (got: $GOT)"

# 14. all three scripts parse under this bash
for s in verify-resolve.sh verify-build.sh verify-test.sh; do
  bash -n "$HERE/$s" && ok || bad "$s should parse (bash -n)"
done

printf 'verify-resolve tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
