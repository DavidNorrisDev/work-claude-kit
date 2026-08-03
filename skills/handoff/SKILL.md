---
name: handoff
description: End-of-session handoff — verify/commit the tree, capture learnings, and write a fresh RESUME.md + one-shot marker so the next session re-grounds after you /clear. Use when a feature or task is COMPLETE and you want a clean stopping point before clearing.
---

# /handoff — package a finished task for a clean /clear

Run this when a task or feature is **done** and you want to clear and start
fresh without losing the thread. `/handoff` conducts existing parts; it does not
reinvent them. It CANNOT `/clear` for you — it prepares the handoff and you press
`/clear`. The SessionStart hook then re-grounds the
next session from `RESUME.md`, because `/handoff` leaves a one-shot marker the
hook honours.

## When to run
A feature/task is complete and you're about to `/clear` or end the session. NOT
for mid-task pauses — for those, leave a one-line note in `RESUME.md` by hand.

## Steps — run in order

### 1. Check the tree
Run `git status --porcelain`.
- **Empty** → tree is clean; go to step 2.
- **Non-empty** → show the diff, propose a commit message in the project's
  style (present tense, sentence case, British English, no emoji). On the
  user's **yes**:
  1. Run `.claude/scripts/verify-build.sh` (or `scripts/verify-build.sh`) FIRST.
  2. **Build green** → commit, then continue.
  3. **Build red** → STOP. Report the failure tail; do not commit, do not hand
     off. Handoff is for a *safe* stopping point.
  Gate on the build only — do NOT run the heavier `verify-test.sh` suite; tests
  stay a deliberate call.
- If the user declines the commit → STOP and hand back; there's nothing to hand
  off from an uncommitted tree.

### 2. Reflect
Invoke the `reflect` skill. It appends durable-learning candidates to
`.claude/state/learning-inbox.md`. Do not duplicate its logic or promote to the
memory index — promotion stays the separate curated step reflect defines.

### 3. Write RESUME.md
Rewrite `.claude/state/RESUME.md` in the existing idiom — a dated **Status**
line, what just shipped, any **Carry-forward** items, and a **Single next
action**. Keep it terse: the resume hook caps injection at 120 lines and
`RESUME.md` is a standing token lever. Then write the
one-shot marker so the next `/clear` re-grounds (ensure the dir exists first, in
case this app hasn't created it yet):

    mkdir -p .claude/state && touch .claude/state/.handoff-active

### 4. Feed the work-ledger (path A)

After writing RESUME, append this session to the work-ledger — you already
have the whole session in context, so no transcript mining is needed.

1. Resolve the ledger: `. ~/.claude/scripts/ledger-env.sh 2>/dev/null || .
   .claude/scripts/ledger-env.sh 2>/dev/null` → `$LEDGER_FILE` (user-level
   install first, repo-relative fallback for a wired-only repo).
   If `$WORK_LEDGER_DIR` is unset/absent, skip silently (kit not installed).
2. Determine this session's id (the current transcript's session-id) and the
   repo name (basename of the repo root).
3. Append ONE entry directly under the `<!-- entries below, newest first -->`
   marker, in the canonical format — distilled, never code:

       ## <today YYYY-MM-DD> · <repo> · <short-session-id>
       <!-- session-id: <session-id> -->

       **Did:** …
       **Resolved:** …
       **Decisions:** …
       **Refs:** <commit shas from this session · PR/ticket ids · or —>

4. If an entry with this session-id already exists (e.g. a prior handoff this
   session), UPDATE it in place rather than adding a duplicate.

### 5. Print the summary
Print one block: `Handed off — safe to /clear now.` followed by the single next
action. Then stop. The user presses `/clear`.

## What this does NOT do
- It does not run `/clear` (a skill can't).
- It does not push or merge — those stay manual.
- A **plain** `/clear` you type without `/handoff` still gives a blank slate; only
  a handoff-marked clear re-grounds, once.
- The marker is a bare filesystem flag with no session id. If two sessions share
  one working tree, a `/clear` in either
  consumes it — worst case one missed re-ground, never corruption.
