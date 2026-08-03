# CLAUDE.md — work-claude-kit (global)

> Engineering + resilience kit for employed iOS/macOS work. Project-level
> CLAUDE.md files extend this with repo-specific detail.

## Stack

| Concern | Choice |
|---|---|
| Language | Swift 6 with strict concurrency |
| UI | SwiftUI |
| Persistence | SwiftData where the project uses it |
| Purchases | StoreKit 2 only — no StoreKit 1 fallbacks, where the project sells anything |
| State | `@Observable` macro for new code; `ObservableObject` only inside files already using it |
| Architecture | MVVM with thin Views, ViewModels owning state, Services owning side-effects |
| Tooling | Xcode current and one previous major |
| Tests | XCTest (or Swift Testing where a project has adopted it) for ViewModels and Services; in-memory `ModelContainer` for SwiftData; `StoreKitTest` for purchases |

A repo's own `CLAUDE.md` is the authority on which of these actually apply — don't
assume SwiftData or StoreKit are in play just because this table lists them.

---

## Coding conventions

- **MVVM** — Views render state and forward intents only. ViewModels own state machines and call Services. Services own side-effects (persistence, network, StoreKit, notifications).
- **Dependency injection** — collaborators come in through initialisers, not from singletons. Default arguments are fine for ergonomics; testability isn't.
- **Concurrency** — UI-bound types are `@MainActor`. Pure data services are usually actors. `@unchecked Sendable` requires written justification and a reviewer flag.
- **SwiftData** — `@Model` for entities; `ModelContext` injected via `Environment(\.modelContext)`; queries via `@Query` in Views or `FetchDescriptor` in ViewModels. Predicates run at the store, not in Swift.
- **StoreKit 2** — listen to `Transaction.updates` for the lifetime of the app; verify with `VerificationResult`; finish transactions; offer restore-purchases.
- **Naming** — types in `UpperCamelCase`, members in `lowerCamelCase`, files named after their primary type. Test files named `<Type>Tests.swift`.
- **Files and folders** — feature-first organisation; shared utilities in a `Common/` or `Shared/` folder; design tokens in `Design/` where a project has them.
- **Commits** — present tense, sentence case, no emoji prefixes, British English. `Add monthly retry backoff` over `feat: added monthly retry backoff 🎉`.

---

## Team workflow — apply automatically

Role definitions live in the repo's `.claude/agents/` (team-lead, discovery, implementer, tester, and the parallel reviewers) — `wire-repo.sh` symlinks them there from the kit; they aren't installed at user level. Two ways to run them: in the **CLI**, invoke `ios-team-lead` by name and it orchestrates the rest via `Task`; in **Xcode** (or any harness with only built-in subagent types), follow the same workflow yourself — `Read` each agent file for its instructions and spawn parallel `general-purpose` subagents for review. The orchestration is non-negotiable in either environment.

**When:** any ticket touching more than one file, adding non-trivial logic, or crossing architectural boundaries. Skip for one-line edits, pure questions, trivial renames.

**Steps:**

1. **Discovery first, always** (`ios-discovery`) — surface every existing ViewModel / Service / View / shared component touching the area before writing code; honour the project's own named patterns and design tokens.
2. **Plan** — decide reuse / extend / new (justify any new type in one line), state which files you'll touch.
3. **Implement** (`ios-implementer`) — smallest diff first; reuse before you add.
4. **Test** (`ios-tester`) — match the project's convention (XCTest, or Swift Testing where adopted).
5. **Parallel review** — in ONE message spawn all six reviewers (architecture, correctness, performance, accessibility, privacy-security, design), each with the diff for context. They MUST run in parallel — don't serialise.
6. **Triage** — group by severity; send must-fixes back through implement; re-review only what changed.
7. **Close out** — what shipped, what was deferred, any decision worth a note in the repo's own conventions doc.

**Learning loop** — after a non-trivial ticket, if a non-obvious pattern / gotcha / convention emerged, invoke the `reflect` skill rather than writing it up ad hoc; it captures durable-learning candidates without bloating this file.

**Skills** — when a step has an obvious skill match, invoke it rather than reasoning from scratch (tester → `swift-testing-pro`, correctness reviewer / any concurrency question → `swift6-concurrency`, SwiftData modelling → `swiftdata-patterns`). The agent file is the *role*; the skill is the *expertise*.

---

## Session resilience & token efficiency

Sessions get interrupted — usually by the Anthropic usage limit, sometimes by a crash, `/clear`, or a closed laptop. No hook fires when a usage limit kills a session, so the rule is simple: **make every stopping point safe, and re-ground from git on the way back in.**

**Resilience:**

- **Keep the tree committable.** Work in small units and commit completed ones immediately. Never end a turn with a broken build if it can be avoided. If you must stop mid-change, leave a one-line note in `.claude/state/RESUME.md` describing what's half-done.
- **Maintain `.claude/state/RESUME.md` at checkpoints** — plan agreed, step finished, decision made — not every turn. It holds the goal, the plan checklist (next item marked `← NEXT`), key decisions, and the single next action. It is gitignored working memory: intent, not truth.
- **Trust git over memory on resume.** The SessionStart hook injects RESUME.md plus live `git status`/`git diff`. Reconcile them before acting; if they disagree, the tree wins. Never redo committed work.
- **Run tests via `.claude/scripts/verify-test.sh`, never raw `xcodebuild test`.** It disables simulator cloning (`-parallel-testing-enabled NO`), so a run killed mid-flight can't leak `Clone N of …` simulators. A SessionStart sweep (`reap-sim-clones.sh`) reaps any Shutdown clones that do leak; run it by hand any time to reclaim space.

**Token efficiency** (same artefacts, double duty — ordered by impact here):

- **Route broad searches to subagents** (`ios-discovery`, `Explore`, `general-purpose`). They read the file dumps in their own context and return only the conclusion, so the dumps never enter the main context. This is the biggest lever, and discovery-first is already the workflow.
- **Scope reads** — read the region you need (offset/limit) when you know it; don't re-read a file already in context or one you just edited.
- **Work in small, committed units** — less uncommitted surface means less context carried and a smaller resume injection.
- **Trust the bounded verify loop** — `verify-build.sh` caps its error output; react to the tail, don't paste full build logs.
- **Prefer curated state over reconstruction** — RESUME.md and discovery output beat re-deriving where you were.
- **Keep `CLAUDE.md` files tight** — they load every session; bloat is a standing per-session tax.
- **Mind compaction** — long sessions auto-compact (costly and lossy); checkpointing + committing means a fresh session is often cheaper and cleaner than a compacted one.

---

## Work reviews

- **`/handoff`** — run at the end of a session that shipped something complete. Verifies the tree, captures learnings, writes a fresh `RESUME.md`, and feeds the work-ledger — the record this kit's check-in ritual reads from.
- **`/check-in`** — a since-last / year-to-date / mid-year / full-year review of what you've actually done, drawn from the work-ledger. Use it ahead of a 1:1, a review cycle, or whenever you need to answer "what have I shipped lately".

See the `check-in` skill for the full review format.
