---
name: spotlight-tour
description: A reusable Spotlight Tour guided-onboarding system (PreferenceKey anchor + cutout overlay). Use when adding or modifying a guided walkthrough / coachmark tour in any app.
---

# Spotlight Tour — reusable guided walkthrough

The technically tricky one. Get the compositing right or the cutout breaks.

## Architecture
- Each tour target attaches an anchor via a `PreferenceKey` (`TourAnchorsKey`)
  carrying its bounds in a named coordinate space.
- The overlay collects anchors, draws a dimmed scrim, then punches a hole over
  the active target using `blendMode(.destinationOut)` on the cutout shape.
- The whole overlay stack needs `.compositingGroup()` so `.destinationOut`
  composites against the scrim only, not the entire screen.

## Non-obvious rules (these are the failure points)
- The scrim + cutout must share ONE compositing group. Forgetting
  `.compositingGroup()` makes the cutout erase everything below it.
- Anchor bounds are resolved via `GeometryReader` in the SAME named coordinate
  space the overlay reads. Mismatched spaces = misplaced hole.
- Tour step state is ephemeral (not SwiftData). Persist only "tour completed"
  via the FeatureDiscoveryManager pattern.
- Honour `accessibilityReduceMotion`: cross-fade steps instead of animating the
  hole's position.

## Porting to a new app
Copy the `TourAnchorsKey`, the overlay view, and the cutout modifier verbatim.
Per app, supply only the ordered list of steps (anchor id + copy). Do not
re-derive the compositing approach — it is load-bearing and easy to break.
