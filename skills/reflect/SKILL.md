---
name: reflect
description: Capture durable learnings from the current session into a review inbox (NOT the live memory index). Use at a natural checkpoint — after finishing a ticket, before /clear or ending a session, or when a non-obvious gotcha, decision, or convention emerged — to propose memory + CLAUDE.md candidates for later curated promotion.
---

# /reflect — capture session learnings (propose, don't auto-promote)

Reflect on what happened **this session** and propose durable learnings. Write *candidates* to an inbox; **never** write the eagerly-loaded memory index or any CLAUDE.md directly — promotion stays a curated, human step. This is the write-fat / inject-thin rule: fat freely to disk, thin and curated into context.

## When to run
After a non-trivial ticket; before `/clear` or ending a session; or whenever a gotcha / decision / convention surfaced that the repo doesn't already record.

## The bar — what counts as a durable learning
Follow the project's memory doctrine. Capture only the **non-obvious**:
- a gotcha, constraint, or convention NOT derivable from the code, git history, or CLAUDE.md
- a decision **plus its rationale** (so it isn't re-litigated later)
- a correction the user made to how you work (feedback)

**Skip:** anything the repo already records (structure, past fixes, commits), one-off conversational detail, or restating existing CLAUDE.md. If nothing clears the bar, say so and stop — an empty inbox beats a noisy one.

## How
1. Scan this session for candidates against the bar. Cheap extraction, not deep reasoning — if dispatching, use a **Haiku** subagent so the main context stays clean.
2. For each, draft an entry in the project's memory format: `name` (kebab-case), `description` (one line, used for recall), `type` (`user` | `feedback` | `project` | `reference`); body with **Why:** + **How to apply:** for feedback/project; `[[link]]` related memories.
3. **Append** the batch (dated) to `.claude/state/learning-inbox.md` — gitignored, and NOT injected by the resume hook (it only cats `RESUME.md`).
4. Do NOT touch the memory dir / `MEMORY.md` or any CLAUDE.md. Print one line: `N candidates → learning-inbox.md`.

## Promotion is separate (curated)
Later, review `learning-inbox.md` and promote the keepers into real memory files + the `MEMORY.md` index (per the memory doctrine) or into a project CLAUDE.md `## Learned Patterns` entry — `claude-md-management:revise-claude-md` helps. Delete the rest. The eagerly-loaded corpus stays hand-curated on purpose.
