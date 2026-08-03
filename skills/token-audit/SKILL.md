---
name: token-audit
description: Audit a Claude Code setup (CLAUDE.md, skills, subagents, hooks, MCP, memory) for token efficiency and produce a ranked, grounded report of what to trim. Use when asked to reduce token or context-window usage, audit eager load, diagnose a bloated context, or review skill / agent / CLAUDE.md weight.
---

# token-audit — find and rank context-window waste

Produce a ranked list of changes by token-saved vs effort, plus the top 3 — grounded in **real numbers**, not guesses.

## Ground in /context, never guess
Ask the user to run `/context` (and `/memory`) and read the category split: System prompt · System tools · MCP tools · Custom agents · Memory files · Skills · Messages · Free space. For individual file weight use `wc -c` ÷ 4 ≈ tokens. If `/context` is available and you estimate anyway, you will mis-rank — estimates have been off by 2× in practice.

## The core distinction — eager vs on-invocation
- **Eager** = loads every session regardless of task: the CLAUDE.md chain, skill frontmatter **descriptions**, agent descriptions, SessionStart hook output, the memory index, MCP tool defs. This is the expensive real estate — attack it first.
- **On-invocation** = loads only when fired: a skill's **body**, an agent's body, a `reference/*.md`. Cheaper; only matters for things invoked often.
Mis-sizing these is the #1 audit error: a fat skill *body* is not an eager cost, but a long *description* is.

## Passes
1. **Eager inventory.** List everything that loads every session + its weight; flag anything large that loads unconditionally. **Resolve symlinks** — confirm what's *actually* pulled in (e.g. `~/.claude/skills` may not be the kit; `.claude/scripts` may be a symlinked dir).
2. **SessionStart hooks.** Read what each injects. A hook that `cat`s a file verbatim (RESUME.md, a journal) is a silent per-session tax — check that file's size and **cap the hook** (`head -n N` + a truncation notice).
3. **Skill structure.** Fat single-file SKILL.md (whole thing loads on trigger) vs thin router + `reference/*.md` (progressive disclosure). Flag fat ones, estimate the per-invocation saving from splitting, and note cross-platform leakage (paying for skill B while doing A). Frontmatter is the eager trigger — never bloat or casually edit it.
4. **Subagents.** Confirm each *isolates* context into its own window (the real win) rather than just adding overhead. Check **model routing** — read-only / search / mechanical roles (discovery, reviewers, test-writing) belong on cheaper tiers; reserve the top model for synthesis and orchestration.
5. **Cache-friendliness.** Stable content (system, CLAUDE.md, tools) should precede variable content; variable injections (git status, diffs) should *append* after the cacheable prefix, not interleave into it.

## Levers (typically most impactful first)
- Bounded hook injection + RESUME/journal hygiene: archive-then-trim, then cap the hook.
- Right-size the CLAUDE.md chain: kill duplication, demote verbose procedure to pointers / agent files.
- Progressive disclosure for fat skills.
- Model routing on subagents (saves cost, not token count).
- Reconsider always-on plugins / MCP servers whose eager descriptions you rarely invoke.

## The doctrine behind all of it
Only what enters the context window costs tokens; disk is free until read. Keep the **write path fat and cheap**, the **reload/index path thin and curated**. Storage tech (Obsidian, SQL) does not reduce tokens — it's a human-curation layer at best.

## Output
A ranked table (change · est. saving · effort · eager vs on-invocation) + the 3 to do first. Be explicit about measured vs estimated, and correct earlier guesses when `/context` contradicts them — an honest downgrade beats a confident wrong number.
