---
name: check-in
description: Produce a work-review from the work-ledger — since-last (default), ytd, mid-year, full-year, standup, or a custom range. Use when you ask for a check-in, a standup, "what have I done this year", a mid-year or performance-review summary, or when returning to review work-to-date. Synthesises themes and impact for 1:1s and performance reviews, not a raw commit dump.
---

# /check-in — work review

Turns the durable work-ledger plus hard evidence (git, PRs, tickets) into a
synthesised review of what you have accomplished. Mechanics live in scripts;
this skill supplies the synthesis judgement.

## Flow

1. **Resolve the period.** Default `since-last`. Find the newest review in
   `$REVIEWS_DIR` for the `since-last` baseline date. Then:
   `bash ~/.claude/scripts/checkin-range.sh <period> <today> [last-review-date]`
   → `<since-epoch> <until-epoch> <label>`. Convert epochs to YYYY-MM-DD for
   the evidence adapters.

2. **Catch the ledger up.** Invoke the `ledger-backfill` skill for the window
   (pass the epoch bounds) so cleared/killed/closed sessions in-range are
   distilled before you read. Never read raw transcripts here — backfill owns
   that, via jq subagents.

3. **Read the ledger for the window.** Pull every entry whose date falls in
   range from `$LEDGER_FILE`. These are the narrative spine (what you did,
   resolved, decided).

4. **Gather hard evidence** — one subagent per repo (from `$WORK_REPOS_FILE`,
   active rows) so the dumps stay out of the main context. Each runs:
   `evidence-git.sh`, `evidence-github.sh` for that repo, plus one
   `evidence-jira.sh` overall. Subagents return only the distilled lists.

5. **Synthesise** (the actual value):
   - Cluster ledger entries + evidence into 3–6 **themes / projects**, not a
     flat list. For each: what shipped, the impact/outcome, and the skills it
     demonstrated (cross-reference reflect's learning-inbox
     (`.claude/state/learning-inbox.md`) or the repo's `docs/LEARNED.md` if
     it keeps one for the growth angle).
   - Keep it standup-terse for `standup`; fuller (themes + impact narrative)
     for ytd / mid-year / full-year — this is 1:1 and performance-review grade.

6. **Write the review** to `$REVIEWS_DIR/<today>-<label>.md` (run
   `mkdir -p "$REVIEWS_DIR"` first — don't assume install scaffolded it):

   # Work check-in — <label> (<since> to <until>)

   ## Themes
   ### <theme> — <one-line impact>
   <2–4 sentences: what shipped, outcome, skills shown>
   …

   ## Forward — what I want to produce next
   <pulled from RESUME.md open threads, open tickets, deferred items>

   ## Evidence appendix
   <commits / PRs / tickets per repo, for traceability>

7. **Show the review** and end with the forward section so you can steer.

## Notes
- Git alone is enough; PR/ticket adapters are additive and degrade silently.
- The review is synthesis, never a commit dump — a bare list is a failure.
- Standup mode: skip the appendix, one tight paragraph (yesterday → today →
  blockers pulled from RESUME).
