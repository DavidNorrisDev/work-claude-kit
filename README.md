# work-claude-kit

Public Claude Code kit for employed iOS/macOS engineering work: the
engineering + resilience spine (discovery → plan → implement → test →
review, session resilience, token discipline) plus a durable work-ledger
and a `/check-in` work-review skill.

The kit is tooling only — it holds no work data. The **ledger** (your
distilled work record) lives outside this repo at `~/work-ledger/`, in its
own git-backed local history separate from this kit's repo — never pushed
anywhere unless you add a remote yourself (see `docs/LEDGER.md`).

## Usage

### 1. Initial Setup

Clone and install — no GitHub auth needed (public repo), and **no `sudo`**.
Stay logged in to `gh` as whatever account you like (e.g. your work
account); the installer doesn't touch `gh`.

```bash
git clone https://github.com/DavidNorrisDev/work-claude-kit.git ~/Projects/work-claude-kit
cd ~/Projects/work-claude-kit
./install.sh
```

`./install.sh` (run as yourself, from the kit directory) is user-level,
additive, and non-destructive:

- Links the `check-in` and `ledger-backfill` skills, plus the seven ledger
  scripts they call (`ledger-env.sh`, `list-unledgered-sessions.sh`,
  `checkin-range.sh`, `evidence-git.sh`, `evidence-github.sh`,
  `evidence-jira.sh`, `ledger-health.sh`), into `~/.claude/skills/` and
  `~/.claude/scripts/` — so the ledger tooling works from any repo, wired
  or not.
- Records exactly what it linked in `~/.claude/.work-claude-kit`, so
  `./uninstall.sh` can reverse it precisely. It skips (never overwrites)
  anything already at that path that isn't its own prior link, so it's
  safe to re-run.
- Scaffolds `~/work-ledger/` with `work-ledger.md` and `work-repos.md`,
  and `git init`s that directory for local history (see `docs/LEDGER.md`
  for what that does and doesn't cover).

It does **not** link a global `~/.claude/CLAUDE.md`, and installs no
agents — those only reach a repo via `./wire-repo.sh` (step 2 below).
Update later with `git pull`.

To reverse the install:

```bash
./uninstall.sh
```

This removes exactly the links recorded in `~/.claude/.work-claude-kit`
(or, for a pre-manifest install, any `~/.claude` symlink pointing into
this kit checkout). If an older install.sh of this kit had ever repointed
`~/.claude/CLAUDE.md` and backed the original up to
`CLAUDE.md.pre-work-kit`, uninstall restores it. Your ledger at
`~/work-ledger` is always preserved — deleting it is a separate, explicit
`rm -rf ~/work-ledger`.

Check the ledger's health anytime with:

```bash
~/.claude/scripts/ledger-health.sh
```

It reports captured entry count and date span, the unledgered gap
(sessions on disk not yet distilled), git backup status (last commit,
uncommitted change count, whether a remote is configured), and the oldest
transcript still on disk — the retention edge, since sessions older than
that survive only in the ledger.

### 2. Wire a Work Repo

For each work repository (e.g., `CompanyApp`), run:

```bash
./wire-repo.sh /path/to/CompanyApp CompanyAppScheme
```

This is idempotent — safe to re-run on a repo you've already wired. It:

- Symlinks the kit's `skills/`, `agents/`, `scripts/`, and `settings.json` into the repo's `.claude/` directory.
- Symlinks `CLAUDE.global.md` into the **repo root** (`<repo>/CLAUDE.global.md`).
- Creates `.claude/state/` (session-resilience) and appends `export SCHEME="<scheme>"` to `.claude/.envrc` if that line isn't already there.
- Seeds `CLAUDE.md` from `CLAUDE.app-template.md` if the repo has none yet.
- If `CLAUDE.md` is itself a symlink, it's left completely untouched — the script only warns on stderr if the `@CLAUDE.global.md` import looks absent through the link. Otherwise it makes sure `CLAUDE.md` — freshly seeded or your own pre-existing one — carries that import line (prepended in place if missing), written via a unique temp file with a fail-loud check (exits non-zero if the swap fails).
- **This can edit a file you may already have committed to the repo's own git history** — review the diff after wiring. The file's permission bits are read before the swap and reapplied, so its mode is preserved.
- Records the repo in the ledger roster (`~/work-ledger/work-repos.md`).

**If you wired a repo before this change landed:** `verify-wiring.sh` (run at
SessionStart) will report three lines as missing — the `@CLAUDE.global.md`
import in `CLAUDE.md`, `export SCHEME=` in `.claude/.envrc`, and
`.claude/state/` — until you re-wire it. These aren't individually
actionable; just re-run `./wire-repo.sh <repo-dir> <scheme>` on the repo.
It's idempotent and safe — it only adds what's missing and won't disturb
anything already in place.

That same re-run also corrects the roster row. Repos wired before the path
fix recorded a logical path, which never matched what `verify-wiring.sh`
resolves when any part of the path is a symlink — so the roster check
warned forever. Re-wiring rewrites the row in place rather than adding a
duplicate; a repo you never re-wire keeps its stale row.

The two ledger skills (`check-in`, `ledger-backfill`) end up linked twice on
a wired repo — once at user level by `install.sh`, once again here (the
whole `skills/` directory is symlinked in). That's harmless — project
scope wins — and it's the intended layering: the user-level install gives
you the ledger tooling everywhere, even in repos you haven't wired yet;
`wire-repo.sh` gives a specific repo the full engineering spine (the
discovery/implement/test/review agents, resilience scripts, and hooks) on
top of that.

### 3. End-of-Session Handoff — Path A

When a feature or task is complete and you're about to `/clear`, run `/handoff`:

```
/handoff
```

This:
1. Commits any uncommitted work (after verifying the build passes).
2. Invokes `/reflect` to capture learning.
3. Rewrites `RESUME.md` to ground the next session.
4. **Feeds the work-ledger directly** — appends this session's work under the `<!-- entries below -->` marker in the canonical format.

The ledger is now current for this session. You can safely `/clear`.

### 4. Catch Up Missed Sessions — Path B

Before running a check-in or to catch the ledger up with sessions that never got a `/handoff` (usage-limit kills, crashes, `/clear` without handoff), run:

```
/ledger-backfill
```

This:
1. Enumerates unledgered sessions across all active repos.
2. Dispatches subagents to distil each transcript (using `jq` only, never reading the full `.jsonl`).
3. Appends the distilled entries to the ledger.

The command is idempotent — re-running adds no duplicates.

### 5. Review Your Work — `/check-in`

Run `/check-in` with a period to generate a synthesised work review:

```
/check-in [period]
```

Supported periods:
- `standup` — Past 24 hours; outputs a tight one-paragraph summary.
- `since-last` — Since your last check-in (default).
- `ytd` — Year-to-date (Jan 1 to today).
- `mid-year` — Jan 1 to June 30.
- `full-year` — Jan 1 to Dec 31.
- `<from:to>` — Custom range, e.g., `2026-06-01:2026-06-30` (YYYY-MM-DD format).

The review:
1. Catches the ledger up with `ledger-backfill` (so killed/crashed sessions are included).
2. Reads the ledger entries for the date range.
3. Gathers hard evidence from git, GitHub PRs/issues, and Jira (optional).
4. Synthesises themes and impact (not a flat commit dump).
5. Writes to `~/work-ledger/reviews/<date>-<period>.md` and displays it.

The review is suitable for 1:1s, performance reviews, and standups.

### Ledger Directory Structure

Default: `~/work-ledger` (override with `WORK_LEDGER_DIR`).

```
~/work-ledger/
├── work-ledger.md    # Append-only session log, newest-first
├── work-repos.md     # Active repo roster
└── reviews/          # Check-in outputs, one per review
```

### Optional: GitHub and Jira Evidence

By default, check-in gathers evidence from git (always available).

**GitHub PRs and issues:** Automatic if `gh auth login` succeeded.

**Jira tickets:** Set three env vars in `~/.zshenv`:

```bash
export JIRA_BASE="https://acme.atlassian.net"
export JIRA_EMAIL="david@acme.com"
export JIRA_TOKEN="<your-api-token>"  # Generate at https://id.atlassian.com/manage-profile/security/api-tokens
```

If any adapter is unavailable, check-in continues and skips that source.

See `docs/LEDGER.md` for the full architecture, formats, and troubleshooting.

### Vendored skills

`skills/swift-security` is vendored from
[dpearson2699/swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills)
at pin `8d90fd1`, under the PolyForm Perimeter 1.0.0 licence. Its `LICENSE`
and `UPSTREAM` files travel with it and must not be edited locally.
