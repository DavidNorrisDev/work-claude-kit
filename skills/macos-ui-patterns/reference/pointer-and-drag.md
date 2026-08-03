# Pointer affordances and drag-and-drop

## 3. Pointer-first affordances

The Mac is driven by a precise pointer, so the disclosure rules from mobile invert.

- Hover states are expected: reveal secondary controls and affordances on hover (the opposite of touch, where there is no hover).
- Right-click context menus (`.contextMenu`) are a primary power-user affordance, not an afterthought.
- Help tags / tooltips (`.help("…")`) on icons and ambiguous controls — assume the user will hover for clarification.
- Targets can be smaller than the 44pt mobile minimum; pointer precision allows tighter, denser controls.
- **Check:** have you given hover, right-click, and help affordances? A Mac view with none feels inert.

## 10. Drag and drop

Effortless Mac apps let you drag anything anywhere. Apple uses it everywhere (Finder, Photos, Reminders).

- Support getting content *in* (drop onto the window) and, just as importantly, *out* (drag an item into Finder, Figma, or another app).
- Pair drag with Apple's standard share affordance where convenient, and a floating action bar (copy / find / delete) on a selection or preview.
- **Check:** can the user drag content both into and out of the app?
