#!/bin/bash
# PreToolUse: block edits to generated or explicitly-preserved files.
# Deterministic guard — CLAUDE.md asks nicely; this enforces.
set -euo pipefail

FILE=$(jq -r '.tool_input.file_path // empty' <<<"$(cat)")
[ -z "${FILE:-}" ] && exit 0

# Preserved components: HapticManager, ToastManager, ToastView, StaggeredList, ContainerFactory
# and anything under a Generated/ dir or *.generated.swift
case "$FILE" in
  *HapticManager.swift|*ToastManager.swift|*ToastView.swift|*StaggeredList.swift|*ContainerFactory.swift|*/Generated/*|*.generated.swift|*.pbxproj)
    echo "BLOCKED: $FILE is a preserved/generated file. Ask the user before modifying it." >&2
    exit 2
    ;;
esac
exit 0
