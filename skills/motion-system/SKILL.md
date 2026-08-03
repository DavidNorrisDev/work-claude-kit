---
name: motion-system
description: How to add animation, transitions, gestures, and interactive motion to apps so they feel smooth and premium while staying calm and consistent across the app. Use this whenever the work involves animating a state change, building a transition, designing a swipe or drag gesture, adding press feedback, or any time the user asks to make something feel "smooth", "slick", "premium", "polished", or "fun to use". Trigger it before writing any `.animation`, `withAnimation`, `.transition`, `.gesture`, or custom interaction, even when motion is only implied — the whole point is to reach for the shared tokens instead of inventing one-off curves. Consistent feel comes from every screen drawing on the same shared motion tokens, not from per-screen taste. This skill governs feel; layout lives in mobile-ui-patterns and macos-ui-patterns, visual craft in visual-design-fundamentals.
---

# Motion System

Premium feel that's consistent across a codebase comes from a shared set of motion tokens, not from per-screen instinct. This skill is the contract for using them.

## Source of truth

All motion tokens should live in one shared package across the project (a `import YourDesignSystem`-style module). Use them. Do **not** write raw `.spring(response:…)`, `.easeInOut(…)`, or magic durations inline — those are exactly what makes an app feel inconsistent.

If a screen needs a curve that no token covers, the fix is to **add a token to that shared package**, not to write a one-off. One source of truth, used everywhere.

## When to use which token

Reach for the role, not the curve:

- **`AppMotion.micro`** — taps, toggles, selection, small state flips. Fast, crisp, no bounce.
- **`AppMotion.standard`** — the default for most UI state changes and navigation.
- **`AppMotion.emphasis`** — sheets, hero moments, anything that should feel present. A touch of spring.
- **`AppMotion.gentle`** — ambient or background motion. Calm and unhurried.

Easing is what makes motion feel alive — almost never use a linear curve. Real things speed up and slow down, and the curve also sets the tone (crisp, springy, or smooth). The tokens encode this so you don't have to decide per screen.

Apply with the value-scoped form so motion is tied to the thing that changed:

```swift
.animation(AppMotion.standard, value: isExpanded)
// or
withAnimation(AppMotion.emphasis) { showSheet = true }
```

## Interaction feedback

For the "alive" press feel on tappable cards and buttons, use the shared style rather than hand-rolling scale effects:

```swift
Button { … } label: { CardView() }
    .buttonStyle(PressableButtonStyle())   // or .pressable() on a container
```

For elements entering or leaving, prefer the shared transition: `.transition(.appRise)` paired with an `AppMotion` token.

## Gestures

Gestures replace buttons or reveal context, and Apple leans on them everywhere. Three principles keep them intuitive rather than gimmicky:

- **Gesture-and-button duality.** A swipe is fast for those who know it, but invisible to those who don't. Always pair an important swipe with a visible control (a button, an edit affordance) so the action is discoverable. Gmail's swipe-to-delete sits alongside an explicit delete — match that.
- **Motion follows the gesture.** When a swipe drives a transition, the background and incoming content should move in the swipe's direction, tracking the finger, then settle. A page that slides in against the gesture feels disconnected.
- **Swipe-to-confirm for high-impact actions.** For destructive or irreversible actions (delete, send, a financial commit), a slide-to-confirm is better than a tap — it's much harder to trigger by accident. Reserve it for those cases; don't gate routine actions behind it.
- For dismissals (sheets, popovers), support the standard swipe-down and pair it with the background settling back as it closes.

**Restraint:** prefer Apple's standard gestures and the shared tokens. Novelty gesture choreography — 3D card carousels, spinning spools — fights the calm, non-manipulative brand. Smooth and intuitive, not showy.

## Restraint (brand)

Motion supports the task; it never performs for its own sake. The house design philosophy is calm and non-manipulative — so:

- No motion that delays the user, demands attention, or manufactures excitement.
- Prefer subtle and quick over showy. If an animation makes the user wait, it's wrong.
- Decorative, looping, or attention-grabbing motion does not belong.

## Reduce Motion is mandatory

Always respect the system setting — calm *and* accessible is the bar.

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
…
.animation(AppMotion.resolved(.standard, reduceMotion: reduceMotion), value: state)
```

When Reduce Motion is on, favour cross-fades and opacity over movement; `AppMotion.resolved(_:reduceMotion:)` swaps to a quick fade for you.

## Quick checklist

1. **Tokens only** — no inline raw curves or magic durations; everything from `AppMotion`.
2. **Right role** — micro / standard / emphasis / gentle matched to the interaction.
3. **Value-scoped** — `.animation(_, value:)` or `withAnimation`, tied to what changed.
4. **Press feel** — tappable things use `PressableButtonStyle` / `.pressable()`.
5. **Gestures** — swipes paired with visible controls; motion follows the gesture; swipe-to-confirm for destructive actions only.
6. **Restraint** — motion serves the task; nothing decorative, delaying, or showy.
7. **Reduce Motion** — honoured via `AppMotion.resolved`; movement degrades to fade.
8. **New curve?** — add a token to the shared package, never a one-off.
