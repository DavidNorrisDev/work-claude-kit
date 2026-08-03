---
name: design-principles
description: Eight operational design checks (Purpose, Agency, Responsibility, Simplicity, Familiarity, Flexibility, Craft, Delight). Use when planning a new feature or app, deciding whether something should be built, implementing UI, reviewing/auditing a screen, or writing copy and empty states.
---

# Design Principles

Load this skill when: planning a new feature, reviewing UI code, evaluating whether something should be built, or auditing an existing screen.

These are operational checks, not inspiration. For each principle, ask the listed questions against the work in progress.

---

## 1. Purpose — does this earn its place?

Every feature costs the user time, attention, and trust. Before building, confirm:

- [ ] What specific problem does this solve for the user?
- [ ] Would removing it make the app worse in a meaningful way?
- [ ] Does it fit the app's core promise, or is it scope creep?

**Default position:** if you can't clearly answer the first two, don't build it.

---

## 2. Agency — does the user stay in control?

Users should be able to move at their own pace and recover from mistakes.

- [ ] Can the user undo or reverse this action?
- [ ] Is there a confirmation before any destructive operation (delete, overwrite, send)?
- [ ] Does the flow let the user explore freely, or does it funnel them down a single path?
- [ ] Are confirmations reserved for genuinely destructive actions, not routine ones?

**Implementation note:** destructive confirmation dialogs use `.destructive` role on the confirm button, `.cancel` role on dismiss. Never reverse these.

---

## 3. Responsibility — does this respect the user?

Well-made apps do not make users feel bad. This has a direct implementation meaning.

- [ ] Are permission requests deferred until the moment they're contextually needed — not on first launch?
- [ ] Is every piece of data collected clearly justified and explained?
- [ ] If this feature uses AI/ML: what happens when the model is wrong? Is there a safeguard?
- [ ] Could this feature be misused in a way that harms the user or someone else?

**AI-specific rule:** never surface a model output as a hard fact without a disclosure or user-visible confidence signal. Treat unexpected/inaccurate output as a known failure mode, not an edge case.

---

## 4. Simplicity — is this as clear as it can be?

Simple ≠ minimal. Simple means frictionless and legible.

- [ ] Does every UI element on this screen earn its place? Remove what doesn't contribute.
- [ ] Is the copy plain language? No jargon, no redundancy, no filler.
- [ ] Is the visual hierarchy strong enough that the most important thing is obviously the most important?
- [ ] Does this reduce the number of steps to accomplish the task, not just the number of visible controls?
- [ ] Is there any complex data that would be better understood as a graphic or summary?

**Hierarchy check:** if you squint at the screen and can't immediately identify the primary action, the hierarchy is broken.

---

## 5. Familiarity — does it behave as expected?

Users bring existing knowledge. Reward it, don't fight it.

- [ ] Does this use standard SwiftUI/iOS conventions for navigation, gestures, and controls?
- [ ] Do things that look the same behave the same across screens?
- [ ] Is any metaphor used close enough to its real-world counterpart to be instantly understood?
- [ ] Are common icons (trash = delete, share = export) used consistently and correctly?

**Rule:** only deviate from platform conventions when there is a clear, user-facing reason to do so. Novel patterns must be immediately discoverable — don't rely on onboarding to explain them.

---

## 6. Flexibility — does it fit real contexts?

Users are real people with varied lives. The app should fit them, not vice versa.

- [ ] Does this work well in both quick-glance and deep-focus modes?
- [ ] Have Dynamic Type and accessibility been considered (minimum tap target 44pt, supports `.accessibilityLabel`)?
- [ ] If the user has arranged or hidden controls, does this feature respect their layout?
- [ ] Does it work correctly in both light and dark mode, and with increased contrast?

---

## 7. Craft — is the execution flawless?

Well-made apps feel considered and finished. Shortcuts show.

- [ ] Are animations fluid and immediate — no perceptible lag on tap?
- [ ] Does the layout hold up on all supported device sizes and orientations?
- [ ] Are all icons SF Symbols or custom assets at correct weights and scales?
- [ ] Does the design adapt correctly between light mode, dark mode, and increased contrast?
- [ ] Has this been tested on a real device, not just the simulator?

**Craft is iterative.** A first pass that works is not the same as a first pass that's finished. Schedule a craft pass after the feature is functionally complete.

---

## 8. Delight — does it create a positive emotional moment?

Delight is the output of getting everything else right. It cannot be added at the end.

- [ ] What emotion should the user feel at the end of this flow? (Calm, capable, satisfied, excited?)
- [ ] Is there a micro-moment — a transition, a completion state, a confirmation — that could reinforce that feeling?
- [ ] Does the completion state (task done, purchase made, item logged) feel rewarding?

**Anti-pattern:** confetti, animations, or flourishes added to a flow that's still confusing or slow. Fix the fundamentals first.

---

## Quick audit checklist (use during code review)

Run through this when reviewing any UI addition:

```
Purpose      → does it earn its place?
Agency       → can the user undo it?
Responsibility → are permissions/data handled respectfully?
Simplicity   → is the hierarchy clear? is the copy plain?
Familiarity  → does it use standard conventions?
Flexibility  → does it work across sizes, modes, accessibility?
Craft        → does it feel finished on a real device?
Delight      → does the completion state feel good?
```

Flag anything that fails two or more checks before proceeding.
