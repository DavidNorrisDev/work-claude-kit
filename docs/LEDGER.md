# Work Ledger — Architecture and Flows

The work ledger is a durable, append-only record of Claude Code sessions and the work they produced. It lives outside the kit repo (default: `~/work-ledger`) and feeds a `/check-in` skill that turns raw transcripts into synthesised work reviews.

## Why a Ledger?

Claude Code sessions are ephemeral — the transcript is local, the session ends, and memory evaporates. A ledger captures the work enduringly, feeding performance reviews, 1:1s, and standup without re-reading transcripts. The ledger distils, never includes code.

## Layout — `$WORK_LEDGER_DIR`

Default location: `$HOME/work-ledger` (override with `WORK_LEDGER_DIR` env).

```
~/work-ledger/
├── work-ledger.md       # Append-only session log (newest-first)
├── work-repos.md        # Roster of active work repos (pipe-delimited)
└── reviews/             # Check-in outputs (one per review date)
    ├── 2026-07-07-ytd.md
    ├── 2026-06-30-since-last.md
    └── …
```

The ledger is **local-first and git-backed, but never pushed** unless you add a remote yourself — it may contain work-derived summaries, timestamps, or personal reflection. `install.sh` `git init`s it and makes one seed commit; nothing in the kit pushes it anywhere (see "Privacy, Git History, and Remote Backup" below). Git-ignore it in any project that uses the kit, so a work repo never accidentally tracks it.

### Entry Format — `work-ledger.md`

One session = one entry, newest-first, directly under the `<!-- entries below, newest first -->` marker. The entry is the canonical format both `/handoff` (live path) and `ledger-backfill` (batch path) must match exactly:

```markdown
## YYYY-MM-DD · repo-name · session-id-short

<!-- session-id: full-session-id -->

**Did:** What was worked on; one or two sentences.
**Resolved:** Bugs fixed, tasks completed, or "—".
**Decisions:** Notable technical choices, or "—".
**Refs:** Commit SHAs, PR #numbers, TICKET-123 ids, or "—".
```

The `<!-- session-id: … -->` comment is the dedup key — enumeration and backfill grep this exact string to avoid duplicates.

### Repo Roster — `work-repos.md`

Pipe-delimited table (Markdown format for readability). One row per active work repo. The ledger miner sweeps only `active` rows:

```markdown
# Work repos the ledger sweeps — one row per repo under the header.
# | name | /absolute/repo/path | scheme | status |
| CompanyAppScheme | /Users/david/Projects/CompanyApp | CompanyAppScheme | active |
```

The two `#`-prefixed lines are the header `install.sh` writes when it first scaffolds `work-repos.md` — there's no `|---|---|---|---|` Markdown separator row; the miner's own case statement just skips the literal placeholder path (`/absolute/repo/path`) and anything starting with `---`, so a manually-added separator wouldn't break it either. `wire-repo.sh` appends the data row: it takes only `<repo-dir>` and `<scheme>`, no separate repo-name argument, so it writes the scheme into both the `name` and `scheme` columns. Edit the `name` column by hand afterwards for a friendlier label if you want one — the miner only reads column *position*, not the header text.

The miner reads this with `IFS='|'`, splits by pipes, and trims whitespace. Rows with `status != active` are skipped. Use this table to temporarily disable a repo (change `active` to `paused`) without deleting it.

### Review Outputs — `reviews/`

Each `/check-in` run writes one file: `YYYY-MM-DD-<period>.md` (e.g., `2026-07-07-ytd.md`). The directory is auto-created if missing. Reviews are synthesis, not raw commit dumps — they cluster work into themes, show impact, and list evidence for traceability.

## Two Feeders — Path A (Live) and Path B (Batch)

### Path A: `/handoff` — Incremental Feeder

Run at the end of a session when a task is complete. `/handoff`:

1. Commits any uncommitted work (after verifying the build).
2. Invokes the `reflect` skill to capture learning.
3. Writes `RESUME.md` to ground the next session.
4. **Feeds the ledger directly** — you have the whole session in context; no mining is needed.

Steps for ledger append:
1. Source `. .claude/scripts/ledger-env.sh` to resolve `$LEDGER_FILE`.
2. Determine the session id (from the current transcript's session metadata) and repo name (basename of the repo root).
3. Append ONE entry under the marker in the canonical format — distilled, never code.
4. If an entry with this session-id already exists (e.g., a prior handoff this session), update it in place rather than adding a duplicate.

**Pros:** Immediate, low latency, no batch delay.
**Cons:** Only fires on explicit `/handoff` — sessions killed by usage limits, cleared without handoff, or crashed never feed this path.

### Path B: `ledger-backfill` — Batch Feeder

Catches the ledger up with sessions that missed Path A (usage-limit kills, `/clear` without `/handoff`, crashes, etc.). Run before any `/check-in` review or directly to keep the ledger current.

**Hard rule:** Never `Read` a `.jsonl` transcript — they run 460MB+ per project. Every distillation happens inside a subagent using `jq` to extract.

Flow:
1. Resolve the range. Default: everything (`since=0`). If called from `/check-in`, receive epoch bounds.
2. Enumerate unledgered sessions:  
   `bash .claude/scripts/list-unledgered-sessions.sh <since-epoch> <until-epoch>`  
   Each line is `repo<TAB>session-id<TAB>jsonl-path`. Empty means ledger is current.
3. For each session, dispatch a subagent (general-purpose) in parallel batches with a distil prompt that:
   - Extracts with `jq` only — user requests, assistant summaries, tool actions (commits, PRs).
   - Returns ONE ledger entry in the canonical format, ≤180 words, distilled.
   - Returns the line `SKIP <session-id>` if the transcript is empty or has no work content.
4. Append returned entries to `$LEDGER_FILE` newest-first under the marker.
5. Report: "N sessions distilled, M skipped (empty/errored)."

Backfill is idempotent — the enumerator already excludes ledgered sessions.

## The Never-Read-Transcripts Rule

The ledger system NEVER reads a `.jsonl` transcript file directly (with `Read` or `cat`). They are massive — 460MB+ per project directory — and would overflow context.

- **Path A (`/handoff`)** distils live (you already have the whole session).
- **Path B (`ledger-backfill`)** distils inside subagents using `jq` to extract snippets.
- **`/check-in` review** never reads transcripts — it reads the ledger (already distilled), then gathers hard evidence from git/PRs/Jira.

This is a hard architectural constraint, not a guideline.

## Evidence Adapters — Three Sources

After distilling the ledger, `/check-in` gathers hard evidence from three sources — git (mandatory, always available), GitHub, and Jira (both optional, each degrading silently if unavailable):

### Git Adapter: `evidence-git.sh`

Queries the repo's git log for your commits in a date range:

```bash
bash .claude/scripts/evidence-git.sh <repo-path> <since-date> <until-date>
```

Output: commit hash + subject, one per line. Discovers your commits by matching `git config user.email`.

**Config:** None required. Reads from `.git/config` in the target repo.

### GitHub Adapter: `evidence-github.sh`

Lists merged PRs authored by you and closed issues assigned to you in a date range:

```bash
bash .claude/scripts/evidence-github.sh <repo-path> <since-date> <until-date>
```

Output: `PR #123 Title` and `#456 Title` lines. Queries GitHub via the `gh` CLI.

**Config:** Uses whatever account `gh` is currently logged in as — on a work machine that's your work account, so it pulls *your work* PRs and issues, which is what you want. `install.sh` does not require or check `gh`. If `gh` is unavailable or the repo is not on GitHub, the adapter exits cleanly and `/check-in` runs on git alone.

### Jira Adapter: `evidence-jira.sh`

Lists Jira issues resolved by you in a date range (global, not per-repo):

```bash
bash .claude/scripts/evidence-jira.sh <since-date> <until-date>
```

Output: `KEY Summary` lines, one per resolved issue.

**Config:** Three environment variables (unset = silently skip):
- `JIRA_BASE`: Base URL, e.g., `https://acme.atlassian.net`
- `JIRA_EMAIL`: Your Jira email (e.g., `david@acme.com`)
- `JIRA_TOKEN`: Jira API token (generate at `https://id.atlassian.com/manage-profile/security/api-tokens`)

Export these in your shell init (e.g., `~/.zshenv`):

```bash
export JIRA_BASE="https://acme.atlassian.net"
export JIRA_EMAIL="david@acme.com"
export JIRA_TOKEN="XXXXXXX"
```

### Combining Evidence

`/check-in` gathers all available sources (git mandatory, GitHub and Jira optional), then clusters them with ledger entries into 3–6 **themes** — not a flat list. Each theme shows what shipped, the impact, and skills it demonstrated. This is synthesis, not a commit dump.

## Check-In Periods

The `/check-in` skill produces work reviews for seven standard periods. Each maps to a date range via `checkin-range.sh`:

1. **`standup`** — Past 24 hours (from 00:00 yesterday to 23:59 today).  
   Output: standup-terse, one tight paragraph, no appendix. Pulls RESUME blockers.

2. **`since-last`** — Default; since your last check-in review (date inferred from newest file in `reviews/`).  
   Use for daily standups, 1:1 updates.

3. **`ytd`** — Year-to-date (Jan 1 to 23:59 today).  
   Use for performance reviews, mid-year summaries.

4. **`mid-year`** — Jan 1 to June 30 of this year.  
   Use for mid-year feedback.

5. **`full-year`** — Jan 1 to Dec 31 of this year.  
   Use for annual performance review.

6. **`<from-date>:<to-date>`** — Custom range (e.g., `2026-06-01:2026-06-30`).  
   Dates must be in YYYY-MM-DD format; times default to 00:00 and 23:59 respectively.

7. **Request by name** — Tell `/check-in` what period you want; it resolves it via `checkin-range.sh`.

## Environment and Scripts

### Ledger Path Resolution: `ledger-env.sh`

Sourced by all ledger scripts. Exports:

```bash
WORK_LEDGER_DIR    # Default: $HOME/work-ledger
LEDGER_FILE        # $WORK_LEDGER_DIR/work-ledger.md
WORK_REPOS_FILE    # $WORK_LEDGER_DIR/work-repos.md
REVIEWS_DIR        # $WORK_LEDGER_DIR/reviews
```

Also defines the function `transcript_dir_for <abs-repo-path>`, which maps an absolute repo path to its Claude Code transcript directory (used by backfill to find `.jsonl` files).

### Enumerate Unledgered Sessions: `list-unledgered-sessions.sh`

```bash
bash .claude/scripts/list-unledgered-sessions.sh [since-epoch] [until-epoch]
```

Reads `$WORK_REPOS_FILE`, finds all active repos, and enumerates `.jsonl` transcript files that aren't yet in `$LEDGER_FILE`. Each line is `repo<TAB>session-id<TAB>jsonl-path`. Exits cleanly if the ledger file doesn't exist or no unledgered sessions are found.

Used by `ledger-backfill` to find what to distil.

### Date Range to Epochs: `checkin-range.sh`

```bash
bash .claude/scripts/checkin-range.sh <period> <today-YYYY-MM-DD> [last-review-date]
```

Returns: `<since-epoch> <until-epoch> <label>`

Used by `/check-in` to convert user-requested periods (e.g., `ytd`, `standup`) into Unix epoch timestamps and a label for file naming.

## Privacy, Git History, and Remote Backup

The ledger is **distilled only** — it never includes code, transcripts, or verbatim log output. Every entry is summarised to the four fields: Did, Resolved, Decisions, Refs.

The ledger lives outside the kit repo and is git-ignored in any repo that wires the kit — it never becomes part of a work repo's own history. Within `~/work-ledger` itself it *is* git-backed: `install.sh` runs `git init` and makes one seed commit so the record has local history and a target to push from. Nothing in the kit pushes anywhere on its own; it stays on your machine unless you add a remote yourself.

### Committing new entries is manual

`install.sh`'s seed commit is the only commit any script in this kit makes. `/handoff` and `ledger-backfill` append to `work-ledger.md`, but neither of them runs `git commit` inside `$WORK_LEDGER_DIR` afterwards — so `ledger-health.sh`'s uncommitted-change count will grow as you use the ledger day to day. That's expected, not a bug. If you want the git history (and any remote) to reflect your latest entries, commit by hand periodically:

```bash
cd ~/work-ledger && git add -A && git commit -m "Ledger update $(date +%Y-%m-%d)"
```

### Adding a remote (optional, for off-machine backup)

`ledger-health.sh` reports `off-machine: NONE` until a remote is configured. To back the ledger up off-machine, create a **private** repo (GitHub, GitLab, or any private git host) and point `~/work-ledger` at it:

```bash
cd ~/work-ledger
git remote add origin git@github.com:<you>/work-ledger-private.git
git push -u origin main
```

Keep it private — the ledger contains distilled work summaries, even though never raw transcripts. After the remote is set, `git push` whenever you commit (see above) to keep it current; `ledger-health.sh` will then report the remote URL instead of `NONE`.

## Integration with Session Lifecycle

### On `/handoff`
- Step 4 (Feed the work-ledger) appends this session to the ledger directly.
- Ledger is now current for this session.

### On `/check-in`
- Backfill is invoked first to catch any missed sessions.
- Ledger + evidence are read and synthesised into themes.
- Review is written to `$REVIEWS_DIR/<date>-<period>.md`.

### On `/clear`
- If `RESUME.md` has a `.handoff-active` marker, the next session re-grounds from RESUME and the ledger.
- Otherwise, no automatic re-ground — but the ledger persists, ready for the next session or check-in.

## Troubleshooting

**Ledger not found:** Check `WORK_LEDGER_DIR` (default `~/work-ledger`). Run `install.sh` if you haven't yet — it scaffolds the directory.

**Sessions not appearing in backfill:** Check that the repo is listed as `active` in `work-repos.md`. If a repo is `paused`, backfill skips it. Also verify the transcript `.jsonl` exists under `~/.claude/projects/` — Claude Code names that subdirectory after the repo's *absolute path* with every `/` replaced by `-` (see `ledger-env.sh`'s `transcript_dir_for`), not the repo's name.

**Jira evidence missing:** Set `JIRA_BASE`, `JIRA_EMAIL`, `JIRA_TOKEN` env vars. Verify the token hasn't expired. If unset, Jira evidence is skipped silently.

**GitHub evidence missing:** Ensure `gh auth login` succeeded and you're logged in as the account whose PRs/issues you want in the review (on a work machine, your work account). If that account can't see a given work repo, its PR/issue evidence will be empty.

**Review synthesis looks flat:** That's a sign `/check-in` didn't cluster the entries well. Check that the ledger entries are detailed enough (Did/Resolved/Decisions should be 1–2 sentences each); thin entries make synthesis hard.
