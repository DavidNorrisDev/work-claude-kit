---
name: ledger-backfill
description: Distil Claude Code sessions that never got a /handoff into the work-ledger. Use before a /check-in review, or directly to catch the ledger up. Covers usage-limit-killed, /clear-without-handoff, and crashed sessions.
---

# Ledger backfill — path B

Fills the work-ledger with sessions the incremental /handoff path missed.
Mechanics (enumeration, dedup, date range) live in
`~/.claude/scripts/list-unledgered-sessions.sh`; this skill supplies the
judgement (distilling a transcript into a ledger entry).

## HARD RULE
NEVER `Read` a `.jsonl` transcript — they run 460MB+ per project directory.
Every distillation happens inside a subagent that extracts with `jq`.

## Loop

1. Resolve the range. Default: everything (`since=0`). If the caller passes a
   window (e.g. from /check-in), pass the epoch bounds through.
2. Enumerate:
   `bash ~/.claude/scripts/list-unledgered-sessions.sh <since> <until>`
   Each line is `repo<TAB>session-id<TAB>jsonl-path`. If empty, report
   "ledger already current" and stop.
3. For EACH line, dispatch one subagent (general-purpose) with the prompt
   below. Dispatch in parallel batches (respect the concurrency the harness
   allows). Each subagent returns ONE ledger entry in the canonical format.
4. Append every returned entry to `$WORK_LEDGER_DIR/work-ledger.md` directly
   under the `<!-- entries below, newest first -->` marker, newest first.
5. Report a one-line summary: N sessions distilled, M skipped (empty/errored).

## Distil-subagent prompt (fill <repo>, <session-id>, <jsonl-path>)

> You are distilling ONE Claude Code transcript into a work-ledger entry.
> The file is `<jsonl-path>`. **Do NOT Read it** — it may be hundreds of MB.
> Extract only with `jq`, e.g.:
> - user requests: `jq -rc 'select(.type=="user") | .message.content' <jsonl-path> | head -c 20000`
> - assistant summaries: `jq -rc 'select(.type=="assistant") | (.message.content[]? | select(.type=="text") | .text)' <jsonl-path> | head -c 20000`
> - tool actions (for commits/PRs): `jq -rc 'select(.type=="assistant") | (.message.content[]? | select(.type=="tool_use") | .input.command? // empty)' <jsonl-path> | grep -E 'git commit|gh pr|git push' | head -50`
> - first date: `jq -rc '.timestamp // empty' <jsonl-path> | head -1`
>
> These filters are best-effort for one Claude Code transcript schema. If a
> filter returns nothing, DO NOT assume the session was empty — inspect and
> adapt first: `jq -rc '.type' <jsonl-path> | sort | uniq -c` and
> `jq -rc 'select(.type=="user") | .message.content | type' <jsonl-path> | head`
> (user content is sometimes a string, sometimes an array of blocks). Only
> return SKIP when the transcript genuinely has no work content, never merely
> because a filter did not match.
>
> From that, produce EXACTLY this entry — distilled summaries, NEVER code,
> ≤180 words total:
>
> ## <first-timestamp-date YYYY-MM-DD> · <repo> · <first 8 chars of session-id>
> <!-- session-id: <session-id> -->
>
> **Did:** …
> **Resolved:** …
> **Decisions:** …
> **Refs:** <commit shas / PR numbers / ticket ids you found, or —>
>
> Return only the entry. If the transcript is empty or has no work content,
> return the single line: SKIP <session-id>

## Notes
- Idempotent: the enumerator already excludes ledgered sessions, so re-running
  adds nothing duplicate.
- A `SKIP` return is not appended; count it as skipped.
