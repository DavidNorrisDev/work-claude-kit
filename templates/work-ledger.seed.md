# Work ledger

Append-only, newest-first. One entry per Claude Code session. Distilled
summaries only — never code. Fed by /handoff (live sessions) and the
backfill miner (sessions that never got a handoff). Dedup key is the
`session-id` comment on each entry.

## Entry format (the single source of truth — both /handoff and the backfill miner MUST match this exactly)

Newest-first, directly under the marker below. The `<!-- session-id: … -->`
comment is the dedup key — the miner greps `session-id: <id>` to skip
already-ledgered sessions, so its format must never drift.

```
## <YYYY-MM-DD> · <repo-name> · <short-session-id>
<!-- session-id: <full-session-id> -->

**Did:** <one or two sentences on what was worked on>
**Resolved:** <bugs fixed / tasks completed, or "—">
**Decisions:** <notable choices, or "—">
**Refs:** <commit shas · PR #n · TICKET-123, or "—">
```

<!-- entries below, newest first -->
