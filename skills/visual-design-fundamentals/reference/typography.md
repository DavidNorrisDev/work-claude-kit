# Typography

Design is mostly text, so type does most of the work. One well-chosen typeface is usually enough.

- On large/display text, tighten tracking slightly (around -2 to -3%) and line height (roughly 110–120%) — it instantly reads more refined. Body text stays at its natural spacing.
- Constrain the number of sizes. Dense and data-heavy screens want a tight, small scale; expressive screens can range wider.
- Respect Dynamic Type — never hard-code sizes that can't scale. (A distinctive serif or italic treatment reserved for emotional moments can be a deliberate exception, used sparingly.)
- SwiftUI: prefer text styles and `.tracking(_:)` over fixed point sizes; let Dynamic Type drive the scale.
- **Check:** one typeface, a constrained set of sizes, display text tightened, and everything still scales with Dynamic Type?
