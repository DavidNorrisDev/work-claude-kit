# Quick audit checklist and scope

## Quick audit checklist

1. **Density** — space is used, not padded out like a stretched iPhone.
2. **Shell** — sidebar nav, toolbar actions, inspector for selection detail; top edge draggable.
3. **Pointer** — hover reveals, right-click menus, and help tags present.
4. **Tables** — dense data in a sortable, selectable `Table` with aligned numerals.
5. **Keyboard** — shortcuts on primary actions, with visible feedback; commands in the menu bar.
6. **System** — meets the user where they are (menu bar / panel / global summon) where it fits.
7. **Optimistic** — UI responds instantly; reconciliation happens in the background.
8. **Windows** — resizable with min sizes; a proper Settings (⌘,) scene.
9. **Controls** — native Mac controls at appropriate sizes; grouped forms.
10. **Drag and drop** — content moves both in and out.
11. **Appearance** — light and dark both designed, neither a mechanical inverse.

---

## Scope note

This skill is structure and judgement for the Mac. Motion (transitions, the feel of a summoned panel) comes from the project's shared motion tokens (see `motion-system`) so animation stays consistent across iOS and macOS. Visual craft — colour, hierarchy, dark-mode treatment, shadows — lives in `visual-design-fundamentals`. It assumes the HIG-level philosophy in `design-principles`; this is the Mac-specific layer on top.
