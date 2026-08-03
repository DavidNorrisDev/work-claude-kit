---
name: visual-design-fundamentals
description: Cross-cutting visual craft for app screens — hierarchy, spacing, typography, colour, dark mode, shadows, control states, and overlays. Use this whenever the work is about how a screen *looks and reads* rather than how it's structured or how it moves: choosing a colour or building a palette, setting type sizes and spacing, deciding what draws the eye, designing button/input states, getting dark mode right, or any time the user asks to make something look "more polished", "more professional", "less flat", or "less like a spreadsheet". Trigger it before styling any new view and when reviewing the visual quality of an existing one. This is the craft layer beneath the platform skills: mobile-ui-patterns and macos-ui-patterns handle layout, motion-system handles feel, and design-principles holds the Apple HIG philosophy — this one handles the visual fundamentals they all rely on.
---

# Visual Design Fundamentals

The cross-cutting craft that makes a screen read well: hierarchy, spacing, type, colour, depth, and state. Load the one reference file for the task at hand rather than reading everything.

**Core principles (always true):**

- Tie everything back to the project's own design-token palette rather than inventing values ad hoc: a single considered accent colour, a neutral ramp for surfaces and text, and a reserved semantic colour for success/completion states. Restraint is the house style.
- This is judgement, not dogma. Where a rule conflicts with the HIG or the app's own conventions, defer to those.

## Routing

| Task | Read |
|---|---|
| Selected/active/disabled/tappable states; button & input states | `reference/signifiers-and-states.md` |
| Focal point / contrast | `reference/hierarchy.md` |
| Gaps, spacing scale, grouping | `reference/spacing-and-layout.md` |
| Type sizes, tracking, Dynamic Type | `reference/typography.md` |
| Choosing a colour or building a palette | `reference/colour.md` |
| Dark mode | `reference/dark-mode.md` |
| Shadows / depth | `reference/shadows-and-depth.md` |
| Text over imagery | `reference/overlays.md` |
| Auditing a screen's visual quality | `reference/audit-checklist.md` |

## Scope note

This is the visual craft layer. It overlaps `design-principles` in places (clarity, dark mode); if you'd rather have one document, this can be merged into it — the cut here is "universal visual craft" versus that skill's "Apple HIG philosophy". Layout decisions belong in the mobile/macOS pattern skills; how things move belongs in motion-system.
