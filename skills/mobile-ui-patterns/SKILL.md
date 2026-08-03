---
name: mobile-ui-patterns
description: Layout, content, and progressive-disclosure patterns for building iOS/macOS app screens that feel considered rather than crammed. Use this whenever the work involves laying out a new screen, porting a desktop or dashboard layout to a phone, deciding what to show versus hide, designing data-heavy or list/table surfaces (analytics, finance, logs), placing navigation and contextual actions, or designing empty, loading, and no-results states. Trigger this before building any new view, even when the user only says they want to "lay out a screen", "make this look better on mobile", "design the dashboard", or "tidy up this view" — these patterns catch the layout and state mistakes that are easy to miss and tedious to retrofit. This skill covers structure and judgement; it does not cover motion (see the motion tokens in the kit for animation feel).
---

# Mobile UI Patterns

Layout, content, and disclosure decisions for app screens. Use when laying out a new view or auditing an existing one. These are structural rules; the *feel* (springs, transitions, gesture choreography) lives in the shared motion layer, not here. This is judgement, not dogma — where a rule conflicts with the HIG or the app's own conventions, defer to those and note the deviation.

## Routing — read the file that matches the task

| Task | Reference |
|---|---|
| Laying out a screen; scale/type/spacing; one-job focus; scroll axis; cards & nesting | `reference/layout-and-structure.md` |
| Tab bars, sidebars, contextual chrome; sheets vs page-pushes | `reference/navigation-and-chrome.md` |
| Data-heavy surfaces (analytics/finance/logs); tables, chips, numerals, charts; colour as signal | `reference/data-surfaces.md` |
| Progressive disclosure; onboarding; empty/loading/error/no-results states; hidden affordances | `reference/disclosure-and-states.md` |

## Quick audit checklist

Run this against any screen before calling it done:

1. **Scale** — nothing shrunk to fit; targets ≥ ~44pt; Dynamic Type respected.
2. **One job** — the screen's purpose names in one phrase.
3. **One axis** — no section scrolls both ways or implies a desktop grid.
4. **Nesting** — no card-in-card / padding-on-padding.
5. **Chrome** — nav and actions are the right ones for *this* screen.
6. **Context** — sub-tasks use sheets, not unnecessary page-pushes.
7. **Data drives form** — chips for finite sets, aligned monospaced numerals, charts/timelines for time data.
8. **Colour means something** — no decorative colour on data views.
9. **Disclosure** — primary action surfaced; secondary actions demoted; onboarding sequenced.
10. **Hidden states** — empty (first-run + no-results), loading, error, context menus, and help all designed.

## Scope note

This skill is structure and judgement. It deliberately does **not** prescribe animation specifics (transition curves, parallax amounts, zoom behaviour). Those are craft decisions that belong in the kit's shared motion tokens so they stay consistent across apps — reference those when building the actual transitions.
