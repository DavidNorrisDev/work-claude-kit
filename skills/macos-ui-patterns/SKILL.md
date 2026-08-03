---
name: macos-ui-patterns
description: Layout, structure, and interaction patterns for building macOS app screens that feel native to the Mac rather than a stretched iPad. Use this whenever the work targets macOS — laying out a window, designing a sidebar/toolbar/inspector, building tables or data-dense analytics views, wiring keyboard shortcuts and menu commands, designing hover and right-click affordances, handling window sizing and the Settings/preferences scene, or designing menu-bar extras, floating panels, and optimistic updates. Trigger this before building any macOS view, even when the user only says "design the Mac app", "lay out this window", "make the analytics view", or "tidy up this Mac screen" — Mac conventions differ enough from iOS that applying mobile habits is the most common way a Mac app reads as non-native. Where this conflicts with mobile-ui-patterns, this skill wins on macOS. Motion lives in the kit's motion-system skill; visual craft (colour, hierarchy, dark mode) lives in visual-design-fundamentals.
---

# macOS UI Patterns

A checklist for building macOS screens that feel native — pointer-first, keyboard-complete, and comfortable with density. These patterns suit data-dense, prosumer-facing tools (e.g. an analytics app) particularly well. Several of these rules deliberately invert the mobile ones; on the Mac, this skill takes precedence.

This is judgement, not dogma. Where a rule conflicts with the HIG or the app's own conventions, defer to those and note the deviation.

**Core essence (always):** feel native to the Mac, not a stretched iPad — pointer-first, keyboard-complete, dense. Sidebar nav, toolbar actions, inspector for selection; respect window chrome and both appearances.

## Routing — load the one reference file for your task

| Task | Reference |
|---|---|
| Density / spacing / using the space | `reference/density-and-layout.md` |
| Shell — split view, sidebar, toolbar, inspector | `reference/shell-sidebar-toolbar-inspector.md` |
| Hover, right-click menus, help tags, drag in/out | `reference/pointer-and-drag.md` |
| Tables / data-dense / analytics views | `reference/tables-and-data.md` |
| Keyboard shortcuts, focus, menu-bar commands | `reference/keyboard-and-menus.md` |
| Menu-bar extras, floating panels, global summon | `reference/menu-bar-extras-and-panels.md` |
| Optimistic updates (saves/deletes/edits) | `reference/optimistic-ui.md` |
| Window sizing, scenes, Settings (⌘,), light/dark | `reference/windows-and-appearance.md` |
| Native controls and grouped forms | `reference/controls-and-forms.md` |
| Auditing a screen / scope vs other skills | `reference/quick-audit-checklist.md` |

Motion → motion-system. Visual craft → visual-design-fundamentals. HIG philosophy → design-principles.
