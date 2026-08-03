# Progressive disclosure and screen states

## 9. Progressive disclosure — sequence, don't dump

Hierarchy isn't only visual weight; it's also *what you show versus what you hide and when*.

- Surface the primary action; reveal secondary ones on demand (swipe actions, context menus, a sheet, an info affordance). Apple's swipe-to-reveal on list rows is the model: the main action (completing) is immediate, the secondary ones are a swipe away.
- Think of this as a spectrum of explicitness: an always-visible global button at one end, a context-menu action at the other. Place each action by how primary it is.
- Onboarding is progressive disclosure over time: one tip pointing at the most important action, then the next, not a six-bullet modal dumped on first launch and instantly forgotten. (This pairs with the kit's Spotlight Tour pattern.)
- On touch there is no hover — translate any "reveal on hover" idea into swipe actions, context menus, or an always-present-but-secondary control.
- **Check:** is everything competing for attention at once? Demote the secondary actions to a swipe/menu/sheet.

## 10. Design the UI you can't see

A screen isn't finished when the happy path looks good. Most of what makes it work is the states you don't see at first.

- Design every state, not just the populated one: **empty (first run)**, **empty (no results)**, **loading**, **error**.
  - First-run empty state: point at the primary action; keep it simple; a single instructional cue beats inviting cards for everything.
  - No-results empty state: acknowledge the search returned nothing, offer suggestions in case of a typo, and give a clear way out.
- Design the hidden affordances: context menus / long-press, copy actions, info/help for ambiguous labels or icons (the touch equivalent of a tooltip — assume the user won't decode an unlabelled icon).
- Account for announcement/first-feature moments where relevant.
- **Check:** have you designed empty, loading, error, and no-results — and the context-menu/help affordances — or only the populated happy path?
